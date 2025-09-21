part of segment_tracker;

class SegmentTrackerEvent {
  const SegmentTrackerEvent({
    required this.startedSegment,
    required this.endedSegment,
    required this.activeSegmentId,
    required this.debugData,
  });

  final bool startedSegment;
  final bool endedSegment;
  final String? activeSegmentId;
  final SegmentTrackerDebugData debugData;
}

class SegmentTrackerDebugData {
  const SegmentTrackerDebugData({
    required this.isReady,
    required this.querySquare,
    required this.boundingCandidates,
    required this.candidatePaths,
    required this.startGeofenceRadius,
    required this.endGeofenceRadius,
  });

  const SegmentTrackerDebugData.empty()
      : isReady = false,
        querySquare = const [],
        boundingCandidates = const [],
        candidatePaths = const [],
        startGeofenceRadius = 0,
        endGeofenceRadius = 0;

  final bool isReady;
  final List<LatLng> querySquare;
  final List<SegmentGeometry> boundingCandidates;
  final List<SegmentDebugPath> candidatePaths;
  final double startGeofenceRadius;
  final double endGeofenceRadius;

  int get candidateCount => boundingCandidates.length;
}

class SegmentDebugPath {
  const SegmentDebugPath({
    required this.id,
    required this.polyline,
    required this.distanceMeters,
    required this.isWithinTolerance,
    required this.passesDirection,
    required this.startHit,
    required this.endHit,
    required this.isActive,
    required this.isDetailed,
    this.nearestPoint,
    this.headingDiffDeg,
  });

  final String id;
  final List<LatLng> polyline;
  final double distanceMeters;
  final bool isWithinTolerance;
  final bool passesDirection;
  final bool startHit;
  final bool endHit;
  final bool isActive;
  final bool isDetailed;
  final LatLng? nearestPoint;
  final double? headingDiffDeg;
}
