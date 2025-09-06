// zerolock.dart
import 'package:toll_cam_finder/services/speed_estimating/robust_kf.dart';

class ZeroLock {
  bool _locked = false;
  bool get locked => _locked;

  void engage() { _locked = true; }
  bool checkExit({required double threshold, double? devSpeed, double? drvSpeed}) {
    final leaving = ((devSpeed ?? 0.0) > threshold) || ((drvSpeed ?? 0.0) > threshold);
    if (leaving) _locked = false;
    return leaving;
  }

  void clampIfLocked(KF kf) {
    if (_locked) {
      kf.v = 0.0; kf.a = 0.0;
    }
  }
}
