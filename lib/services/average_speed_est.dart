import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks average speed (same unit as fed samples).
class AverageSpeedController extends ChangeNotifier {
  static const int _millisecondsPerHour = 1000 * 60 * 60;

  bool _isRunning = false;
  double _distanceKm = 0.0;
  double _lastSpeedKph = 0.0;
  DateTime? _lastSampleAt;
  DateTime? _startedAt;
  Timer? _ticker;

  bool get isRunning => _isRunning;
  DateTime? get startedAt => _startedAt;

  double get average {
    if (!_isRunning || _startedAt == null) {
      return 0.0;
    }

    final DateTime now = DateTime.now();
    final double elapsedHours = _elapsedHours(_startedAt!, now);
    if (elapsedHours <= 0) {
      return 0.0;
    }

    final double totalDistanceKm =
        _distanceKm + _distanceSinceLastSample(now: now, speedKph: _lastSpeedKph);
    if (totalDistanceKm <= 0) {
      return 0.0;
    }

    return totalDistanceKm / elapsedHours;
  }

  void start() {
    _isRunning = true;
    _distanceKm = 0.0;
    _lastSpeedKph = 0.0;
    final DateTime now = DateTime.now();
    _startedAt = now;
    _lastSampleAt = now;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _distanceKm = 0.0;
    _lastSpeedKph = 0.0;
    _lastSampleAt = null;
    _startedAt = null;
    _stopTicker();
    notifyListeners();
  }

  void addSample(double speed, {DateTime? timestamp}) {
    if (!_isRunning) return;
    final double sanitizedSpeed =
        (speed.isFinite && speed >= 0) ? speed : 0.0;
    final DateTime now = timestamp ?? DateTime.now();

    if (_lastSampleAt != null) {
      final double deltaHours = _elapsedHours(_lastSampleAt!, now);
      if (deltaHours > 0) {
        _distanceKm += _lastSpeedKph * deltaHours;
      }
    }

    _lastSampleAt = now;
    _lastSpeedKph = sanitizedSpeed;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  double _distanceSinceLastSample({required DateTime now, required double speedKph}) {
    if (_lastSampleAt == null) {
      return 0.0;
    }

    final double deltaHours = _elapsedHours(_lastSampleAt!, now);
    if (deltaHours <= 0) {
      return 0.0;
    }

    return speedKph * deltaHours;
  }

  double _elapsedHours(DateTime from, DateTime to) {
    final int deltaMillis = to.difference(from).inMilliseconds;
    if (deltaMillis <= 0) {
      return 0.0;
    }

    return deltaMillis / _millisecondsPerHour;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning) {
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
