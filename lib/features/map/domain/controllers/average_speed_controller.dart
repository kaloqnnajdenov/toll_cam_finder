import 'package:flutter/foundation.dart';
import 'package:toll_cam_finder/features/map/domain/utils/average_speed_calculator.dart';

/// Tracks average speed (same unit as fed samples).
class AverageSpeedController extends ChangeNotifier {
  AverageSpeedController({AverageSpeedCalculator? calculator})
      : _calculator = calculator ?? const AverageSpeedCalculator();

  bool _isRunning = false;
  double _distanceMeters = 0.0;
  DateTime? _startedAt;
  DateTime? _lastSampleAt;

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

  double get average {
    if (!_isRunning) {
      return 0.0;
    }
    final Duration? elapsedDuration = elapsed;
    if (elapsedDuration == null) {
      return 0.0;
    }
    return _calculator.calculateKph(
      distanceMeters: _distanceMeters,
      elapsed: elapsedDuration,
    );
  }

  void start({DateTime? startedAt}) {
    _isRunning = true;
    _distanceMeters = 0.0;
    _startedAt = startedAt ?? DateTime.now();
    _lastSampleAt = _startedAt;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _distanceMeters = 0.0;
    _startedAt = null;
    _lastSampleAt = null;
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
    }

    final DateTime clampedTimestamp = timestamp.isBefore(_startedAt!) ? _startedAt! : timestamp;
    final DateTime? previous = _lastSampleAt;
    final Duration? delta = previous != null ? clampedTimestamp.difference(previous) : null;

    final double sanitizedDistance =
        (distanceDeltaMeters.isFinite && distanceDeltaMeters > 0) ? distanceDeltaMeters : 0.0;

    if (sanitizedDistance == 0.0 && (delta == null || delta <= Duration.zero)) {
      _lastSampleAt = clampedTimestamp;
      return;
    }

    _distanceMeters += sanitizedDistance;
    _lastSampleAt = clampedTimestamp;
    notifyListeners();
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
}
