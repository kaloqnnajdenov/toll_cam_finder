import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

class CurrentSegmentController extends ChangeNotifier {
  CurrentSegmentController({
    AverageSpeedController? averageController,
    Distance? distanceCalculator,
  })  : _averageController = averageController ?? AverageSpeedController(),
        _distance = distanceCalculator ?? const Distance();

  final AverageSpeedController _averageController;
  final Distance _distance;

  SegmentTrackerEvent? _lastEvent;
  SegmentDebugPath? _activePath;
  SegmentTrackerDebugData _debugData = const SegmentTrackerDebugData.empty();
  double? _distanceToSegmentStartMeters;
  double? _lastSegmentAverageKph;
  String? _progressLabel;
  LatLng? _lastAverageSamplePosition;
  DateTime? _lastAverageSampleAt;

  AverageSpeedController get averageController => _averageController;
  SegmentTrackerEvent? get lastEvent => _lastEvent;
  SegmentDebugPath? get activePath => _activePath;
  SegmentTrackerDebugData get debugData => _debugData;
  double? get distanceToSegmentStartMeters => _distanceToSegmentStartMeters;
  double? get activeSegmentSpeedLimitKph => _lastEvent?.activeSegmentSpeedLimitKph;
  double? get lastSegmentAverageKph => _lastSegmentAverageKph;
  String? get progressLabel => _progressLabel;
  double? get distanceToSegmentEndMeters => _activePath?.remainingDistanceMeters;
  bool get hasActiveSegment => _lastEvent?.activeSegmentId != null;
  String? get activeSegmentId => _lastEvent?.activeSegmentId;

  void reset() {
    _lastEvent = null;
    _activePath = null;
    _debugData = const SegmentTrackerDebugData.empty();
    _distanceToSegmentStartMeters = null;
    _lastSegmentAverageKph = null;
    _progressLabel = null;
    _lastAverageSamplePosition = null;
    _lastAverageSampleAt = null;
    _averageController.reset();
    notifyListeners();
  }

  void recordProgress({
    required LatLng position,
    required DateTime timestamp,
  }) {
    if (!_averageController.isRunning) {
      return;
    }

    final LatLng? previousPosition = _lastAverageSamplePosition;
    if (previousPosition == null || _lastAverageSampleAt == null) {
      _lastAverageSamplePosition = position;
      _lastAverageSampleAt = timestamp;
      return;
    }

    final double distanceMeters = _distance.as(
      LengthUnit.Meter,
      previousPosition,
      position,
    );

    final double sanitizedDistance =
        (distanceMeters.isFinite && distanceMeters > 0) ? distanceMeters : 0.0;

    _averageController.recordProgress(
      distanceDeltaMeters: sanitizedDistance,
      timestamp: timestamp,
    );

    _lastAverageSamplePosition = position;
    _lastAverageSampleAt = timestamp;
  }

  double? updateWithEvent({
    required SegmentTrackerEvent event,
    required DateTime timestamp,
    SegmentDebugPath? activePath,
    double? distanceToSegmentStartMeters,
    String? progressLabel,
    LatLng? userPosition,
  }) {
    double? exitAverage;

    if (event.endedSegment || event.completedSegmentLengthMeters != null) {
      final double? segmentLength = event.completedSegmentLengthMeters;
      final Duration? elapsed = _averageController.elapsed;
      final double computedAverage = (segmentLength != null && elapsed != null)
          ? _averageController.avgSpeedDone(
              segmentLengthMeters: segmentLength,
              segmentDuration: elapsed,
            )
          : _averageController.average;

      exitAverage = computedAverage;
      _lastSegmentAverageKph = computedAverage.isFinite ? computedAverage : null;
      _averageController.reset();
      _lastAverageSamplePosition = null;
      _lastAverageSampleAt = null;
    }

    if (event.startedSegment) {
      _lastSegmentAverageKph = null;
      _averageController.start(startedAt: timestamp);
      _lastAverageSamplePosition = userPosition;
      _lastAverageSampleAt = timestamp;
    }

    _lastEvent = event;
    _activePath = activePath;
    _debugData = event.debugData;
    _distanceToSegmentStartMeters = distanceToSegmentStartMeters;
    _progressLabel = progressLabel;

    notifyListeners();

    return exitAverage;
  }

  @override
  void dispose() {
    _averageController.dispose();
    super.dispose();
  }
}
