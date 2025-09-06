// derived_speed.dart
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import 'package:toll_cam_finder/core/speed_tuning.dart';

class DerivedSpeed {
  double? _lastLat, _lastLng, _lastAcc; // keep acc used last tick

  Displacement? displacement(double latSm, double lngSm, double accNow) {
    if (_lastLat == null || _lastLng == null) return null;
    final d = Geolocator.distanceBetween(_lastLat!, _lastLng!, latSm, lngSm);
    return Displacement(d, _lastAcc ?? 999.0, accNow);
  }

  Measurements measure({
    required Displacement? disp,
    required double? dtRaw,
    required double drvExtraNoise,
    required double horizAccBad,
    required double minDtForDrv,
  }) {
    double? drvSpeed, drvSigma;
    if (disp != null && dtRaw != null && dtRaw >= minDtForDrv) {
      final accOk = (disp.acc1 <= horizAccBad && disp.acc2 <= horizAccBad);
      if (accOk) {
        final v = (disp.meters / dtRaw);
        final sigmaV = math.sqrt(disp.acc1 * disp.acc1 + disp.acc2 * disp.acc2) / dtRaw;
        drvSpeed = v;
        drvSigma = math.sqrt(sigmaV * sigmaV + drvExtraNoise * drvExtraNoise);
        if (dtRaw < 0.25) {
          final scale = (0.25 / dtRaw).clamp(1.0, 4.0);
          drvSigma *= scale;
        }
      }
    }
    return Measurements(drvSpeed: drvSpeed, drvSigma: drvSigma);
  }

  void commit(double latSm, double lngSm, double accNow) {
    _lastLat = latSm; _lastLng = lngSm; _lastAcc = accNow;
  }
}
