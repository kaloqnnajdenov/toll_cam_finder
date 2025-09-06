// speed_estimator.dart (facade)
import 'package:geolocator/geolocator.dart';
import 'package:toll_cam_finder/core/speed_tuning.dart';
import 'dart:math' as math;
import 'coord_smoother.dart';
import 'timebase.dart';
import 'derived_speed.dart';
import 'stationary.dart';
import 'zerolock.dart';
import 'robust_kf.dart';

class SpeedEstimator {
  final Tuning t;
  final CoordSmoother _smooth = CoordSmoother();
  final Timebase _time = Timebase();
  final DerivedSpeed _drv = DerivedSpeed();
  final StationaryDetector _stationary = StationaryDetector();
  final ZeroLock _zero = ZeroLock();
  final KF _kf;

  SpeedEstimator({
    Tuning tuning = const Tuning(),
    double sigmaJerk = 3.0,
    double fading = 1.15,
    double pFloorV = 0.10,
    double pFloorA = 0.25,
    double maxSpeed = 80.0,
  }) : t = tuning,
       _kf = KF(
         sigmaJerk: sigmaJerk, fading: fading,
         pFloorV: pFloorV, pFloorA: pFloorA, maxSpeed: maxSpeed,
       );

  Position fuse(Position raw) {
    final dt = _time.dtSeconds(minDt: t.minDt, maxDt: t.maxDt);
    final dtRaw = _time.dtRawSeconds();
    final (latSm, lngSm) = _smooth.smooth(raw.latitude, raw.longitude);
    final accNow = (raw.accuracy.isFinite) ? raw.accuracy : 999.0;

    // Measurements: Doppler
    final devSpeed = (raw.speed.isFinite && raw.speed >= 0) ? raw.speed : null;
    double? devSigma = (raw.speedAccuracy.isFinite) ? raw.speedAccuracy : null;
    if (devSigma != null) devSigma = math.max(devSigma, t.devAccClampFloor);

    // Derived (single distance computation, reused)
    final disp = _drv.displacement(latSm, lngSm, accNow);
    final drvMeas = _drv.measure(
      disp: disp, dtRaw: dtRaw,
      drvExtraNoise: t.drvExtraNoise,
      horizAccBad: t.horizAccBad,
      minDtForDrv: t.minDt,
    );

    // Initialize KF if needed
    if (!_kf.initialized) {
      final z0 = devSpeed ?? drvMeas.drvSpeed ?? 0.0;
      final r0 = (devSigma != null ? devSigma*devSigma
                 : (drvMeas.drvSigma != null ? drvMeas.drvSigma!*drvMeas.drvSigma! : 25.0));
      _kf.init(z0.clamp(0.0, _kf.maxSpeed), r0);
    }

    _kf.predict(dt);

    // Stationary logic
    final st = _stationary.tick(
      dispMeters: disp?.meters,
      acc1: disp?.acc1 ?? 999.0,
      acc2: disp?.acc2 ?? accNow,
      devSpeed: devSpeed,
      drvSpeed: drvMeas.drvSpeed,
      smallSpeed: t.smallSpeed,
      stationaryDisp: t.stationaryDisp,
      debounce: t.stationaryDebounceCount,
    );
    if (st.doSoftUpdate) {
      _kf.updateRobust(st.z, st.r);
      _zero.engage();
      _kf.inflate(1.3);
    } else if (st.becameMobile) {
      _kf.inflate(t.stationaryExitInflate);
    }

    // Updates (skip Doppler while zero-locked)
    if (!_zero.locked && devSpeed != null && devSigma != null) {
      _kf.updateRobust(devSpeed, _boundedVar(devSigma * devSigma));
    }
    if (drvMeas.drvSpeed != null && drvMeas.drvSigma != null) {
      _kf.updateRobust(drvMeas.drvSpeed!, _boundedVar(drvMeas.drvSigma! * drvMeas.drvSigma!));
    }

    // Zero-lock clamp & exit check
    if (_zero.locked) {
      final left = _zero.checkExit(
        threshold: t.zeroExit, devSpeed: devSpeed, drvSpeed: drvMeas.drvSpeed,
      );
      if (!left) {
        _zero.clampIfLocked(_kf);
      } else {
        _kf.inflate(t.stationaryExitInflate);
      }
    }

    // Commit displacement state
    _drv.commit(latSm, lngSm, accNow);

    final estSpeed = _kf.v.clamp(0.0, _kf.maxSpeed);
    final estVar = _kf.p00;

    return Position(
      latitude: latSm,
      longitude: lngSm,
      accuracy: raw.accuracy,
      altitude: raw.altitude,
      heading: raw.heading,
      speed: estSpeed,
      speedAccuracy: math.sqrt(estVar),
      timestamp: raw.timestamp,
      isMocked: raw.isMocked,
      altitudeAccuracy: raw.altitudeAccuracy,
      headingAccuracy:  raw.headingAccuracy,
    );
  }

  static double _boundedVar(double v, {double minVar = 0.25 * 0.25, double maxVar = 400.0}) {
    if (!v.isFinite) return minVar;
    return v.clamp(minVar, maxVar);
  }
}
