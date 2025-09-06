import 'package:flutter/foundation.dart';

/// Tracks average speed (same unit as fed samples).
class AverageSpeedController extends ChangeNotifier {
  bool _isRunning = false;
  int _sampleCount = 0;
  double _sum = 0.0;
  DateTime? _startedAt;

  bool get isRunning => _isRunning;
  DateTime? get startedAt => _startedAt;
  int get sampleCount => _sampleCount;
  double get average => (_isRunning && _sampleCount > 0) ? _sum / _sampleCount : 0.0;

  void start() {
    _isRunning = true;
    _sampleCount = 0;
    _sum = 0.0;
    _startedAt = DateTime.now();
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _sampleCount = 0;
    _sum = 0.0;
    _startedAt = null;
    notifyListeners();
  }

  void addSample(double speed) {
    if (!_isRunning) return;
    _sum += speed;
    _sampleCount++;
    notifyListeners();
  }
}
