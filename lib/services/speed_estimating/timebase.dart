// timebase.dart
class Timebase {
  DateTime? _last;
  double dtSeconds({double minDt = 0.12, double maxDt = 2.5}) {
    final now = DateTime.now();
    final dt = (_last == null) ? minDt
      : (now.difference(_last!).inMilliseconds / 1000.0);
    _last = now;
    return dt.clamp(minDt, maxDt);
  }
  double? dtRawSeconds() => (_last == null) ? null
      : (DateTime.now().difference(_last!).inMilliseconds / 1000.0);
}
