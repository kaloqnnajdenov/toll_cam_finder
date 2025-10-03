import 'dart:math' as math;

import 'package:toll_cam_finder/core/constants.dart';

/// Smooths instantaneous speed readings for a steadier UI while keeping
/// stop/slowdown response snappy.
class SpeedSmoother {
  SpeedSmoother({
    this.riseTimeSeconds = AppConstants.speedSmootherRiseTimeSeconds,
    this.fallTimeSeconds = AppConstants.speedSmootherFallTimeSeconds,
    this.stopSnapKmh = AppConstants.speedSmootherStopSnapKmh,
  }) : assert(riseTimeSeconds >= 0),
        assert(fallTimeSeconds >= 0),
        assert(stopSnapKmh >= 0);

  /// Approximate 63% response time for increases (seconds).
  final double riseTimeSeconds;

  /// Approximate 63% response time for decreases (seconds).
  final double fallTimeSeconds;

  /// Any reading below this threshold snaps immediately to 0 km/h.
  final double stopSnapKmh;

  double? _value;
  DateTime? _lastSample;

  /// Feed a new instantaneous speed (km/h) and obtain the smoothed value.
  double next(double rawKmh) {
    final now = DateTime.now();
    final dtSeconds = _lastSample == null
        ? null
        : now.difference(_lastSample!).inMicroseconds / 1e6;
    _lastSample = now;

    if (!rawKmh.isFinite || rawKmh <= stopSnapKmh) {
      _value = 0.0;
      return 0.0;
    }

    if (_value == null) {
      _value = rawKmh;
      return rawKmh;
    }

    final diff = rawKmh - _value!;
    final tau = diff >= 0 ? riseTimeSeconds : fallTimeSeconds;

    double alpha;
    if (dtSeconds == null || dtSeconds <= 0 || tau <= 0) {
      alpha = 1.0;
    } else {
      alpha = 1 - math.exp(-dtSeconds / tau);
    }

    alpha = alpha.clamp(0.0, 1.0);
    _value = (_value! + alpha * diff).clamp(0.0, double.infinity);
    return _value!;
  }

  void reset() {
    _value = null;
    _lastSample = null;
  }
}