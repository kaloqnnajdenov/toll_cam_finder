import 'package:flutter/foundation.dart';

import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker_models.dart';

enum SegmentsOnlyModeReason { manual, osmUnavailable, offline }

class SegmentsOnlyModeController extends ChangeNotifier {
  double? _currentSpeedKmh;
  bool _hasActiveSegment = false;
  double? _segmentSpeedLimitKph;
  SegmentDebugPath? _segmentDebugPath;
  double? _distanceToSegmentStartMeters;
  SegmentsOnlyModeReason? _reason;
  bool _isActive = false;

  double? get currentSpeedKmh => _currentSpeedKmh;
  bool get hasActiveSegment => _hasActiveSegment;
  double? get segmentSpeedLimitKph => _segmentSpeedLimitKph;
  SegmentDebugPath? get segmentDebugPath => _segmentDebugPath;
  double? get distanceToSegmentStartMeters => _distanceToSegmentStartMeters;
  SegmentsOnlyModeReason? get reason => _reason;
  bool get isActive => _isActive;

  void updateMetrics({
    required double? currentSpeedKmh,
    required bool hasActiveSegment,
    required double? segmentSpeedLimitKph,
    required SegmentDebugPath? segmentDebugPath,
    required double? distanceToSegmentStartMeters,
  }) {
    bool changed = false;

    if (_currentSpeedKmh != currentSpeedKmh) {
      _currentSpeedKmh = currentSpeedKmh;
      changed = true;
    }

    if (_hasActiveSegment != hasActiveSegment) {
      _hasActiveSegment = hasActiveSegment;
      changed = true;
    }

    if (_segmentSpeedLimitKph != segmentSpeedLimitKph) {
      _segmentSpeedLimitKph = segmentSpeedLimitKph;
      changed = true;
    }

    if (!identical(_segmentDebugPath, segmentDebugPath)) {
      _segmentDebugPath = segmentDebugPath;
      changed = true;
    }

    if (_distanceToSegmentStartMeters != distanceToSegmentStartMeters) {
      _distanceToSegmentStartMeters = distanceToSegmentStartMeters;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void enterMode(SegmentsOnlyModeReason reason) {
    final bool changed = !_isActive || _reason != reason;
    _isActive = true;
    _reason = reason;
    if (changed) {
      notifyListeners();
    }
  }

  void exitMode() {
    if (!_isActive && _reason == null) {
      return;
    }
    _isActive = false;
    _reason = null;
    notifyListeners();
  }
}
