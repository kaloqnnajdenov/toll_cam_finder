import 'dart:async';

import 'package:flutter/foundation.dart';

const int _microsecondsPerHour = Duration.microsecondsPerSecond *
    Duration.secondsPerMinute *
    Duration.minutesPerHour;

/// Tracks average speed (same unit as fed samples).
class AverageSpeedController extends ChangeNotifier {
  bool _isRunning = false;
  int _sampleCount = 0;
  double _totalDistanceMeters = 0.0;
  DateTime? _startedAt;
  DateTime? _lastSampleAt;
  double? _lastSpeedKph;
  Timer? _ticker;

  bool get isRunning => _isRunning;
  DateTime? get startedAt => _startedAt;
  int get sampleCount => _sampleCount;

  double get average {
    if (!_isRunning || _startedAt == null) {
      return 0.0;
    }

    final DateTime now = DateTime.now();
    final Duration elapsed = now.difference(_startedAt!);
    if (elapsed.isNegative || elapsed.inMicroseconds == 0) {
      return 0.0;
    }

    final double hours = elapsed.inMicroseconds / _microsecondsPerHour;
    if (hours <= 0) {
      return 0.0;
    }

    final double kilometers = _totalDistanceMeters / 1000;
    return kilometers / hours;
  }

  void start() {
    _isRunning = true;
    _sampleCount = 0;
    _totalDistanceMeters = 0.0;
    _startedAt = DateTime.now();
    _lastSampleAt = _startedAt;
    _lastSpeedKph = null;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning) {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _sampleCount = 0;
    _totalDistanceMeters = 0.0;
    _startedAt = null;
    _lastSampleAt = null;
    _lastSpeedKph = null;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void addSample(
    double speed, {
    DateTime? timestamp,
    double? distanceMeters,
  }) {
    if (!_isRunning) return;
    final DateTime sampleAt = timestamp ?? DateTime.now();
    _sampleCount++;

    if (distanceMeters != null && distanceMeters.isFinite) {
      _totalDistanceMeters += distanceMeters.abs();
    } else if (_lastSampleAt != null && _lastSpeedKph != null) {
      final Duration delta = sampleAt.difference(_lastSampleAt!);
      if (!delta.isNegative && delta.inMicroseconds > 0) {
        final double hours = delta.inMicroseconds / _microsecondsPerHour;
        final double avgSpeedKph = (_lastSpeedKph! + speed) / 2;
        _totalDistanceMeters += (avgSpeedKph * hours) * 1000;
      }
    }

    _lastSampleAt = sampleAt;
    _lastSpeedKph = speed;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
