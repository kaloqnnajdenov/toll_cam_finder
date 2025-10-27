import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

class SegmentHandoverStatus {
  const SegmentHandoverStatus({
    this.previousAverageKph,
    this.previousLimitKph,
    this.nextLimitKph,
    required this.createdAt,
  });

  final double? previousAverageKph;
  final double? previousLimitKph;
  final double? nextLimitKph;
  final DateTime createdAt;
}

class _PendingExitSummary {
  const _PendingExitSummary({
    required this.createdAt,
    this.averageKph,
    this.limitKph,
  });

  final DateTime createdAt;
  final double? averageKph;
  final double? limitKph;
}

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
  SegmentHandoverStatus? _handoverStatus;
  _PendingExitSummary? _pendingExitSummary;
  Timer? _handoverTimer;

  static const Duration _handoverVisibility = Duration(seconds: 6);
  static const Duration _handoverWindow = Duration(seconds: 4);

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
  SegmentHandoverStatus? get handoverStatus => _handoverStatus;

  void reset() {
    _lastEvent = null;
    _activePath = null;
    _debugData = const SegmentTrackerDebugData.empty();
    _distanceToSegmentStartMeters = null;
    _lastSegmentAverageKph = null;
    _progressLabel = null;
    _lastAverageSamplePosition = null;
    _lastAverageSampleAt = null;
    _handoverTimer?.cancel();
    _handoverTimer = null;
    _handoverStatus = null;
    _pendingExitSummary = null;
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

    final double? previousLimit = _lastEvent?.activeSegmentSpeedLimitKph;
    final DateTime now = timestamp;

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

      if (event.endedSegment) {
        _pendingExitSummary = _PendingExitSummary(
          createdAt: now,
          averageKph: _lastSegmentAverageKph,
          limitKph: previousLimit,
        );
      }
    }

    if (event.startedSegment) {
      _lastSegmentAverageKph = null;
      _averageController.start(startedAt: timestamp);
      _lastAverageSamplePosition = userPosition;
      _lastAverageSampleAt = timestamp;

      _maybeCreateHandover(
        timestamp: now,
        nextLimitKph: event.activeSegmentSpeedLimitKph,
      );
    }

    _lastEvent = event;
    _activePath = activePath;
    _debugData = event.debugData;
    _distanceToSegmentStartMeters = distanceToSegmentStartMeters;
    _progressLabel = progressLabel;

    _expireStaleSummaries(now);

    notifyListeners();

    return exitAverage;
  }

  @override
  void dispose() {
    _averageController.dispose();
    _handoverTimer?.cancel();
    super.dispose();
  }

  void _maybeCreateHandover({
    required DateTime timestamp,
    double? nextLimitKph,
  }) {
    final _PendingExitSummary? pending = _pendingExitSummary;
    if (pending == null) {
      return;
    }

    if (timestamp.difference(pending.createdAt) > _handoverWindow) {
      _pendingExitSummary = null;
      return;
    }

    _handoverStatus = SegmentHandoverStatus(
      previousAverageKph: pending.averageKph,
      previousLimitKph: pending.limitKph,
      nextLimitKph: nextLimitKph,
      createdAt: timestamp,
    );
    _pendingExitSummary = null;
    _handoverTimer?.cancel();
    _handoverTimer = Timer(_handoverVisibility, () {
      if (_handoverStatus != null) {
        _handoverStatus = null;
        if (hasListeners) {
          notifyListeners();
        }
      }
    });
  }

  void _expireStaleSummaries(DateTime now) {
    final _PendingExitSummary? pending = _pendingExitSummary;
    if (pending != null &&
        now.difference(pending.createdAt) > _handoverVisibility) {
      _pendingExitSummary = null;
    }

    final SegmentHandoverStatus? status = _handoverStatus;
    if (status != null &&
        now.difference(status.createdAt) > _handoverVisibility) {
      _handoverStatus = null;
    }
  }
}
