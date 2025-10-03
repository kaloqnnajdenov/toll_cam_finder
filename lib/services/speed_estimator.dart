import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import 'package:toll_cam_finder/core/constants.dart';

/// - Internal lat/lng smoothing (1-D Kalman per coord; moved here from LocationService)
/// - 2-state KF on [velocity, acceleration]
/// - dt-scaled process noise (white-jerk model) + covariance fading + floors
/// - sequential fusion of Doppler + derived speed with 3σ/8σ robust gating
/// - soft stationary snapping (moderate R) + inflation to exit quickly
/// - zero-lock with hysteresis (hold exact 0 while stopped; ignore Doppler until clear movement)
class SpeedEstimator {
  // ---- NEW: coordinate smoothers live here (no smoothing in LocationService) ----
  final _LocationFilter _latFilter = _LocationFilter();
  final _LocationFilter _lngFilter = _LocationFilter();

  final _KF _kf = _KF(
    sigmaJerk:
        AppConstants.speedEstimatorSigmaJerk, // m/s^3 process noise (higher => more responsive)
    fading:
        AppConstants.speedEstimatorFadingFactor, // >1 inflates P each predict (forgetting); 1.1–1.3 works well
    pFloorV:
        AppConstants.speedEstimatorVelocityVarianceFloor, // min var for speed state (m/s)^2
    pFloorA:
        AppConstants.speedEstimatorAccelerationVarianceFloor, // min var for accel state (m/s^2)^2
    maxSpeed: AppConstants.speedEstimatorMaxSpeed, // cap estimate (m/s) ~288 km/h
  );

  // Store previous SMOOTHED coordinate + accuracy for derived-speed & stationary logic
  double? _lastLatSm;
  double? _lastLngSm;
  double? _lastAcc; // we keep last horizontal acc for variance calc
  DateTime? _lastFixWallTime;
  int _stationaryCount = 0;

  // Tunables (as before)
  final double horizAccBad = AppConstants.speedEstimatorHorizAccBadMeters; // m: ignore derived speed if poor
  final double minDt = AppConstants.speedEstimatorMinDtSeconds; // s: minimum dt to trust derived speed
  final double maxDt = AppConstants.speedEstimatorMaxDtSeconds; // s: clamp dt to avoid huge jumps
  final double stationaryDisp = AppConstants.speedEstimatorStationaryDispMeters; // m
  final int stationaryDebounceCount = AppConstants.speedEstimatorStationaryDebounceCount; // frames
  final double smallSpeed = AppConstants.speedEstimatorSmallSpeedMps; // m/s: tiny motion threshold
  final double stationaryExitInflate = AppConstants.speedEstimatorStationaryExitInflate; // inflate P when leaving stationary

  // Treat tiny/0 Doppler accuracy as "clamp up", not "unknown"
  final double devAccClampFloor =
      AppConstants.speedEstimatorDevAccClampFloor; // m/s: min Doppler σ we accept

  // Extra noise added to derived-speed variance to cover curvature/nonlinearity
  final double drvExtraNoise =
      AppConstants.speedEstimatorDrvExtraNoise; // m/s (added in quadrature)

  // --- zero-lock (hysteresis) ---
  bool _zeroLocked = false;
  final double zeroExit = AppConstants.speedEstimatorZeroExitSpeedMps; // m/s (~3.2 km/h) to LEAVE zero-lock

  /// Fuse a raw geolocator Position. Returns a Position whose lat/lng are the
  /// internally smoothed coordinates and whose speed is the robust KF estimate.
  Position fuse(Position raw) {
    final wallNow = DateTime.now();
    final dtRaw = (_lastFixWallTime != null)
        ? (wallNow.difference(_lastFixWallTime!).inMilliseconds / 1000.0)
        : null;
    final dt = (dtRaw == null) ? minDt : dtRaw.clamp(minDt, maxDt);

    // ---- NEW: smooth coordinates here (centralized) ----
    final latSm = _latFilter.filter(raw.latitude);
    final lngSm = _lngFilter.filter(raw.longitude);

    // Prepare an accuracy figure for derived-speed/stationary (use raw.accuracy if finite)
    final accNow =
        _finiteOr(raw.accuracy, AppConstants.speedEstimatorAccuracyFallbackMeters);

    // --- Measurements -------------------------------------------------------

    // Doppler (device) speed
    final devSpeed = (raw.speed.isFinite && raw.speed >= 0) ? raw.speed : null;

    double? devAcc = (raw.speedAccuracy.isFinite) ? raw.speedAccuracy : null;
    if (devAcc != null) {
      // clamp too-small/zero to a sane floor; do NOT discard
      devAcc = math.max(devAcc, devAccClampFloor);
    }
    double? devR = (devAcc != null) ? _boundedVar(devAcc * devAcc) : null;

    // Derived speed from SMOOTHED positions (distance / wall-time dt), single computation reused
    double? drvSpeed;
    double? drvR;
    double? dispMeters; // reuse for stationary detection
    if (_lastLatSm != null &&
        _lastLngSm != null &&
        dtRaw != null &&
        dtRaw >= minDt) {
      dispMeters = Geolocator.distanceBetween(
        _lastLatSm!,
        _lastLngSm!,
        latSm,
        lngSm,
      );

      final acc1 =
          _finiteOr(_lastAcc, AppConstants.speedEstimatorAccuracyFallbackMeters);
      final acc2 = accNow;
      final accOk = (acc1 <= horizAccBad && acc2 <= horizAccBad);

      if (accOk) {
        final v = (dispMeters / dtRaw).clamp(0.0, _kf.maxSpeed);
        final sigmaV = math.sqrt(acc1 * acc1 + acc2 * acc2) / dtRaw;
        final sigma = math.sqrt(
          sigmaV * sigmaV + drvExtraNoise * drvExtraNoise,
        );
        drvSpeed = v;
        drvR = _boundedVar(sigma * sigma);
        // If dt is very small, derived becomes unstable; inflate R
        if (dtRaw < AppConstants.speedEstimatorShortDtSeconds) {
          final scale = (AppConstants.speedEstimatorShortDtSeconds / dtRaw)
              .clamp(
            AppConstants.speedEstimatorShortDtInflateMin,
            AppConstants.speedEstimatorShortDtInflateMax,
          );
          drvR = _boundedVar(drvR * scale);
        }
      }
    }

    // --- Stationary gating (soft) ------------------------------------------
    bool stationarySoftUpdate = false;
    double? zStationary;
    double? rStationary;

    if (_lastLatSm != null && _lastLngSm != null && _lastFixWallTime != null) {
      // Reuse displacement if available, else compute once
      dispMeters ??= Geolocator.distanceBetween(
        _lastLatSm!,
        _lastLngSm!,
        latSm,
        lngSm,
      );

      final acc1 =
          _finiteOr(_lastAcc, AppConstants.speedEstimatorAccuracyFallbackMeters);
      final acc2 = accNow;

      final dTiny = dispMeters <= math.max(stationaryDisp, 0.5 * (acc1 + acc2));
      final devTiny = (devSpeed ?? 0.0) < smallSpeed;
      final drvTiny = (drvSpeed ?? 0.0) < smallSpeed;

      if (dTiny && (devTiny || devR == null) && (drvTiny || drvR == null)) {
        _stationaryCount++;
        if (_stationaryCount >= stationaryDebounceCount) {
          // Softly pull to zero, but keep enough uncertainty to leave quickly
          stationarySoftUpdate = true;
          zStationary = 0.0;
          rStationary =
              AppConstants.speedEstimatorStationaryVariance; // stronger pull (σ=0.12 m/s)
          // Keep some "readiness" to move: gentle inflate every stationary tick
          _kf.inflate(AppConstants.speedEstimatorStationaryInflateFactor);
          _zeroLocked = true; // engage zero-lock
        }
      } else {
        // Leaving stationary: make the filter responsive immediately
        if (_stationaryCount >= stationaryDebounceCount) {
          _kf.inflate(stationaryExitInflate);
        }
        _stationaryCount = 0;
        // don't forcibly clear zero-lock here; it will clear on clear movement
      }
    } else {
      _stationaryCount = 0;
    }

    // --- Filter predict & updates ------------------------------------------

    // Initialize sensibly on first call
    if (!_kf.initialized) {
      final z0 = devSpeed ?? drvSpeed ?? 0.0;
      final r0 = (devR ?? drvR ??
          AppConstants
              .speedEstimatorInitialMeasurementVariance); // very loose if unknown
      _kf.init(z0.clamp(0.0, _kf.maxSpeed), r0);
    }

    _kf.predict(dt);

    // 1) Stationary soft-update (if applicable)
    if (stationarySoftUpdate && zStationary != null && rStationary != null) {
      _kf.updateRobust(zStationary, rStationary);
    }

    // 2) Doppler (preferred, robust-gated) — skip while zero-locked
    if (devSpeed != null && devR != null && !_zeroLocked) {
      _kf.updateRobust(devSpeed, devR);
    }

    // 3) Derived (secondary, robust-gated)
    if (drvSpeed != null && drvR != null) {
      _kf.updateRobust(drvSpeed, drvR);
    }

    var estSpeed = _kf.v.clamp(0.0, _kf.maxSpeed);
    var estVar = math.max(_kf.p00, 0.0); // variance of velocity state

    // --- Zero-lock clamp & hysteresis exit ---------------------------------
    if (_zeroLocked) {
      final leaving =
          ((devSpeed ?? 0.0) > zeroExit) || ((drvSpeed ?? 0.0) > zeroExit);
      if (!leaving) {
        // Hold exact zero and keep filter nimble
        _kf.v = 0.0;
        _kf.a = 0.0;
        estSpeed = 0.0;
        estVar = math.max(_kf.p00, 0.0);
      } else {
        _zeroLocked = false;
        _kf.inflate(stationaryExitInflate); // react quickly on exit
      }
    }

    // ---- Bookkeeping of smoothed coords & accuracy ----
    _lastLatSm = latSm;
    _lastLngSm = lngSm;
    _lastAcc = accNow;
    _lastFixWallTime = wallNow;

    // ---- Return a Position with SMOOTHED coords + estimated speed ----
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
      // Preserve/forward (keep the same compatibility shim you had before)
      altitudeAccuracy: raw.altitudeAccuracy,
      headingAccuracy: raw.headingAccuracy,
    );
  }

  static double _finiteOr(double? v, double fallback) =>
      (v != null && v.isFinite) ? v : fallback;

  static double _boundedVar(
    double v, {
    double minVar = AppConstants.speedEstimatorMinVariance,
    double maxVar = AppConstants.speedEstimatorMaxVariance,
  }) {
    if (!v.isFinite) return minVar;
    return v.clamp(minVar, maxVar);
  }
}

/// 1-D scalar Kalman filter for coordinates (moved from LocationService)
class _LocationFilter {
  double _errorEstimate = AppConstants.locationFilterInitialErrorEstimate;
  double _lastEstimate = AppConstants.locationFilterInitialEstimate;
  double _kalmanGain = AppConstants.locationFilterInitialKalmanGain;
  final double _errorMeasure = AppConstants.locationFilterMeasurementError;
  final double _errorProcess = AppConstants.locationFilterProcessError;
  bool _initialized = false;

  double filter(double currentMeasurement) {
    if (!_initialized) {
      _initialized = true;
      _lastEstimate = currentMeasurement; // avoid huge first-step bias
      return currentMeasurement;
    }

    // Prediction
    final prediction = _lastEstimate;
    _errorEstimate = _errorEstimate + _errorProcess;

    // Update
    _kalmanGain = _errorEstimate / (_errorEstimate + _errorMeasure);
    final currentEstimate =
        prediction + _kalmanGain * (currentMeasurement - prediction);
    _errorEstimate = (1.0 - _kalmanGain) * _errorEstimate;

    _lastEstimate = currentEstimate;
    return currentEstimate;
  }

  void reset() {
    _errorEstimate = AppConstants.locationFilterInitialErrorEstimate;
    _lastEstimate = AppConstants.locationFilterInitialEstimate;
    _kalmanGain = AppConstants.locationFilterInitialKalmanGain;
    _initialized = false;
  }
}

/// 2-state constant-acceleration KF on [velocity, acceleration].
/// Dynamics: v_k = v + a*dt, a_k = a + w (jerk integrated) with white-jerk noise.
/// Discrete Q = q * [[dt^3/3, dt^2/2],
///                   [dt^2/2,    dt  ]]
class _KF {
  _KF({
    required this.sigmaJerk,
    required this.fading,
    required this.pFloorV,
    required this.pFloorA,
    required this.maxSpeed,
  });

  final double sigmaJerk; // m/s^3
  final double fading; // >1: covariance inflation per predict
  final double pFloorV; // min var for v
  final double pFloorA; // min var for a
  final double maxSpeed; // cap for v

  bool initialized = false;

  // State x = [v, a]
  double v = 0.0;
  double a = 0.0;

  // Covariance P
  double p00 = AppConstants.speedEstimatorInitialCovariance,
      p01 = 0.0,
      p10 = 0.0,
      p11 = AppConstants.speedEstimatorInitialCovariance;

  void init(double v0, double r0) {
    v = v0.clamp(0.0, maxSpeed);
    a = 0.0;
    // Seed P from measurement variance; allow acceleration to be quite uncertain
    p00 = math.max(r0, pFloorV);
    p11 = math.max(AppConstants.speedEstimatorInitialAccelerationVariance,
        pFloorA); // start with loose accel variance
    p01 = 0.0;
    p10 = 0.0;
    initialized = true;
  }

  void predict(double dt) {
    if (!initialized) return;

    // State prediction
    v = (v + a * dt).clamp(0.0, maxSpeed);
    // a = a (constant accel model)

    // P' = F P F^T + Q, with F = [[1, dt],[0,1]]
    final p00n = p00 + dt * (p01 + p10) + dt * dt * p11;
    final p01n = p01 + dt * p11;
    final p10n = p10 + dt * p11;
    final p11n = p11;

    // Q from white-jerk spectral density q = sigmaJerk^2
    final q = sigmaJerk * sigmaJerk;
    final dt2 = dt * dt;
    final q00 = q * (dt * dt2) / 3.0; // dt^3 / 3
    final q01 = q * (dt2) / 2.0; // dt^2 / 2
    final q11 = q * dt;

    p00 = (p00n + q00) * fading;
    p01 = (p01n + q01) * fading;
    p10 = (p10n + q01) * fading;
    p11 = (p11n + q11) * fading;

    // Floors to avoid collapse
    p00 = math.max(p00, pFloorV);
    p11 = math.max(p11, pFloorA);
  }

  /// Robust update with scalar measurement z of velocity, variance r.
  /// Uses 3σ soft-inflation and 8σ hard-reject gating.
  void updateRobust(
    double z,
    double r, {
    double gateSoft = AppConstants.speedEstimatorGateSoftSigma,
    double gateHard = AppConstants.speedEstimatorGateHardSigma,
  }) {
    if (!initialized) return;

    final s = p00 + r; // innovation variance (scalar)
    final sigma = math.sqrt(
      math.max(s, AppConstants.speedEstimatorInnovationVarianceFloor),
    );
    final y = z - v; // innovation

    final ay = y.abs();
    if (ay > gateHard * sigma) {
      if (y > 0) {
        // Measurement wildly higher than expected: reject.
        return;
      }
      // Soft accept: encourage responsiveness (more aggressively for drops).
      inflate(y >= 0
          ? AppConstants.speedEstimatorPositiveSurpriseInflate
          : AppConstants.speedEstimatorNegativeSurpriseInflate);
    } else if (ay > gateSoft * sigma) {
      // Soft accept: inflate P so the gain is higher for this surprise
      inflate(AppConstants.speedEstimatorPositiveSurpriseInflate);
    }

    // K = P H^T / S, with H = [1, 0]
    final k0 = p00 / s;
    final k1 = p10 / s;

    // State update
    v = (v + k0 * y).clamp(0.0, maxSpeed);
    a = a + k1 * y;

    // Joseph form: P = (I-KH)P(I-KH)^T + K R K^T
    final t00 = (1.0 - k0) * p00;
    final t01 = (1.0 - k0) * p01;
    final t10 = p10 - k1 * p00;
    final t11 = p11 - k1 * p01;

    final p00n = t00 * (1.0 - k0) + (k0 * k0) * r;
    final p01n = -t00 * k1 + t01 + (k0 * k1) * r;
    final p10n = t10 * (1.0 - k0) + (k1 * k0) * r;
    final p11n = -t10 * k1 + t11 + (k1 * k1) * r;

    p00 = p00n;
    p01 = p01n;
    p10 = p10n;
    p11 = p11n;

    // Symmetrize lightly
    final avg = 0.5 * (p01 + p10);
    p01 = avg;
    p10 = avg;

    // Floors
    p00 = math.max(p00, pFloorV);
    p11 = math.max(p11, pFloorA);
  }

  /// Multiply covariance by a factor (>=1).
  void inflate(double factor) {
    if (!initialized) return;
    final f = factor.isFinite && factor >= AppConstants.speedEstimatorInflateFloor
        ? factor
        : AppConstants.speedEstimatorInflateFloor;
    p00 *= f;
    p01 *= f;
    p10 *= f;
    p11 *= f;
    p00 = math.max(p00, pFloorV);
    p11 = math.max(p11, pFloorA);
  }
}
