// stationary.dart
class StationaryDetector {
  int _count = 0;
  bool get wasStationary => _count > 0;

  ({bool doSoftUpdate, double z, double r, bool becameMobile}) tick({
    required double? dispMeters,
    required double acc1,
    required double acc2,
    required double? devSpeed,
    required double? drvSpeed,
    required double smallSpeed,
    required double stationaryDisp,
    required int debounce,
  }) {
    bool doSoft = false, becameMobile = false;
    if (dispMeters != null) {
      final dTiny = dispMeters <= (stationaryDisp > 0 ? 
        (stationaryDisp > 0.5*(acc1+acc2) ? stationaryDisp : 0.5*(acc1+acc2))
        : 0.5*(acc1+acc2));
      final devTiny = (devSpeed ?? 0.0) < smallSpeed;
      final drvTiny = (drvSpeed ?? 0.0) < smallSpeed;

      if (dTiny && (devTiny || devSpeed == null) && (drvTiny || drvSpeed == null)) {
        _count++;
        if (_count >= debounce) doSoft = true;
      } else {
        becameMobile = _count >= debounce;
        _count = 0;
      }
    } else {
      _count = 0;
    }
    return (doSoftUpdate: doSoft, z: 0.0, r: 0.12 * 0.12, becameMobile: becameMobile);
  }
}
