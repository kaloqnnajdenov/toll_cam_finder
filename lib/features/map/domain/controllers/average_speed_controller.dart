import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:toll_cam_finder/features/map/domain/utils/average_speed_calculator.dart';

/// Tracks average speed (same unit as fed samples).
class AverageSpeedController extends ChangeNotifier {
  AverageSpeedController({AverageSpeedCalculator? calculator})
    : _calculator = calculator ?? const AverageSpeedCalculator();

  static const Duration _smoothingDuration = Duration(seconds: 20);

  bool _isRunning = false;
  double _distanceMeters = 0.0;
  double _rawAverageKph = 0.0;
  double _displayAverageKph = 0.0;
  bool _hasDisplayAverage = false;
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

  double get average => _displayAverageKph;

  void start({DateTime? startedAt}) {
    _isRunning = true;
    _distanceMeters = 0.0;
    _rawAverageKph = 0.0;
    _displayAverageKph = 0.0;
    _hasDisplayAverage = false;
    _startedAt = startedAt ?? DateTime.now();
    _lastSampleAt = _startedAt;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _distanceMeters = 0.0;
    _rawAverageKph = 0.0;
    _displayAverageKph = 0.0;
    _hasDisplayAverage = false;
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

    final DateTime clampedTimestamp = timestamp.isBefore(_startedAt!)
        ? _startedAt!
        : timestamp;

    final double sanitizedDistance =
        (distanceDeltaMeters.isFinite && distanceDeltaMeters > 0)
        ? distanceDeltaMeters
        : 0.0;

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
  }) => avgSpeedDone(
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
      _rawAverageKph = 0.0;
      _displayAverageKph = 0.0;
      _hasDisplayAverage = false;
      if (forceNotify) {
        notifyListeners();
      }
      return;
    }
    DateTime referenceTime = now ?? DateTime.now();

    if (_lastSampleAt != null && referenceTime.isBefore(_lastSampleAt!)) {
      referenceTime = _lastSampleAt!;
    }

    if (referenceTime.isBefore(_startedAt!)) {
      referenceTime = _startedAt!;
    }

    final Duration diff = referenceTime.difference(_startedAt!);
    if (diff <= Duration.zero) {
      _rawAverageKph = 0.0;
      _displayAverageKph = 0.0;
      _hasDisplayAverage = false;
      _lastSampleAt = referenceTime;
      if (forceNotify) {
        notifyListeners();
      }
      return;
    }

    final double nextRawAverage = _calculator.calculateKph(
      distanceMeters: _distanceMeters,
      elapsed: diff,
    );

    _rawAverageKph = nextRawAverage;

    final bool smoothingActive = diff < _smoothingDuration;
    final double nextDisplayAverage;
    if (!smoothingActive) {
      nextDisplayAverage = nextRawAverage;
    } else if (!_hasDisplayAverage) {
      nextDisplayAverage = nextRawAverage;
    } else {
      final double progress =
          (diff.inMilliseconds / _smoothingDuration.inMilliseconds)
              .clamp(0.0, 1.0);
      const double minWeight = 0.35;
      final double weight =
          minWeight + (1 - minWeight) * progress; // -> [0.35, 1.0]
      nextDisplayAverage =
          _displayAverageKph + (nextRawAverage - _displayAverageKph) * weight;
    }

    final bool changed =
        (_displayAverageKph - nextDisplayAverage).abs() > 1e-6;
    _displayAverageKph = nextDisplayAverage;
    _hasDisplayAverage = true;
    _lastSampleAt = referenceTime;
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
