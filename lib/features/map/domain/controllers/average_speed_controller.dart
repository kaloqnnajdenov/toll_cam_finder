import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:toll_cam_finder/features/map/domain/utils/average_speed_calculator.dart';

/// Tracks average speed (same unit as fed samples).
class AverageSpeedController extends ChangeNotifier {
  AverageSpeedController({AverageSpeedCalculator? calculator})
      : _calculator = calculator ?? const AverageSpeedCalculator();

  bool _isRunning = false;
  double _distanceMeters = 0.0;
  double _averageKph = 0.0;
  DateTime? _startedAt;
  DateTime? _lastSampleAt;
  Timer? _ticker;

  final AverageSpeedCalculator _calculator;

  bool get isRunning => _isRunning;
  DateTime? get startedAt => _startedAt;
  double get distanceMeters => _distanceMeters;

  /// Duration elapsed between [startedAt] and the most recent sample.
  Duration? get elapsed {
    if (_startedAt == null || _lastSampleAt == null) {
      return null;
    }
    final Duration diff = _lastSampleAt!.difference(_startedAt!);
    if (diff.isNegative) {
      return Duration.zero;
    }
    return diff;
  }

  double get average => _averageKph;

  void start({DateTime? startedAt}) {
    _isRunning = true;
    _distanceMeters = 0.0;
    _averageKph = 0.0;
    _startedAt = startedAt ?? DateTime.now();
    _lastSampleAt = _startedAt;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _distanceMeters = 0.0;
    _averageKph = 0.0;
    _startedAt = null;
    _lastSampleAt = null;
    _stopTicker();
    notifyListeners();
  }

  void recordProgress({
    required double distanceDeltaMeters,
    required DateTime timestamp,
  }) {
    if (!_isRunning) {
      return;
    }

    if (_startedAt == null) {
      _startedAt = timestamp;
      _startTicker();
    }

    final DateTime clampedTimestamp = timestamp.isBefore(_startedAt!) ? _startedAt! : timestamp;

    final double sanitizedDistance =
        (distanceDeltaMeters.isFinite && distanceDeltaMeters > 0) ? distanceDeltaMeters : 0.0;

    if (sanitizedDistance > 0.0) {
      _distanceMeters += sanitizedDistance;
    }

    _updateAverage(now: clampedTimestamp);
  }

  double avgSpeedDone({
    required double segmentLengthMeters,
    Duration? segmentDuration,
  }) {
    final Duration? duration = segmentDuration ?? elapsed;
    if (duration == null) {
      return 0.0;
    }
    return _calculator.calculateKph(
      distanceMeters: segmentLengthMeters,
      elapsed: duration,
    );
  }

  double avg_speed_done({
    required double segmentLengthMeters,
    Duration? segmentDuration,
  }) =>
      avgSpeedDone(
        segmentLengthMeters: segmentLengthMeters,
        segmentDuration: segmentDuration,
      );

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateAverage(forceNotify: true);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _updateAverage({DateTime? now, bool forceNotify = false}) {
    if (!_isRunning || _startedAt == null) {
      _averageKph = 0.0;
      return;
    }

    final DateTime current = now ?? DateTime.now();
    final Duration diff = current.difference(_startedAt!);
    if (diff <= Duration.zero) {
      _averageKph = 0.0;
      _lastSampleAt = current;
      if (forceNotify) {
        notifyListeners();
      }
      return;
    }

    final double nextAverage = _calculator.calculateKph(
      distanceMeters: _distanceMeters,
      elapsed: diff,
    );

    final bool changed = (_averageKph - nextAverage).abs() > 1e-6;
    _averageKph = nextAverage;
    _lastSampleAt = current;

    if (forceNotify || changed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
