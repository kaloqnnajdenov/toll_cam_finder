part of segment_tracker;

/// Represents the outcome of processing a new position update. The tracker
/// emits this to inform listeners about segment transitions and to provide
/// accompanying debug data.
class SegmentTrackerEvent {
  const SegmentTrackerEvent({
    required this.startedSegment,
    required this.endedSegment,
    required this.activeSegmentId,
    required this.debugData,
  });

  /// Whether the latest update triggered a transition into a new segment.
  final bool startedSegment;

  /// Whether the previously active segment was exited on this update.
  final bool endedSegment;

  /// Identifier of the currently active segment, if any.
  final String? activeSegmentId;

  /// Snapshot of the debug data associated with the update.
  final SegmentTrackerDebugData debugData;
}

/// Aggregated debug information that accompanies each tracker event. The data
/// can be visualised to inspect the underlying decision-making process.
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

  /// Whether the tracker has performed at least one candidate query.
  final bool isReady;

  /// Bounding square used for the last candidate lookup.
  final List<LatLng> querySquare;

  /// Segment geometries that intersected the bounding square.
  final List<SegmentGeometry> boundingCandidates;

  /// Evaluation results for each candidate segment.
  final List<SegmentDebugPath> candidatePaths;

  /// Radius of the start geofence used when checking candidate matches.
  final double startGeofenceRadius;

  /// Radius of the end geofence used when checking candidate matches.
  final double endGeofenceRadius;

  /// Convenience getter exposing how many candidate segments were considered.
  int get candidateCount => boundingCandidates.length;
}

/// Visualisable information for a single candidate path that can be plotted on
/// a map overlay.
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

  /// Identifier of the underlying segment geometry.
  final String id;

  /// Polyline displayed for the candidate segment.
  final List<LatLng> polyline;

  /// Distance from the vehicle to the segment's closest point.
  final double distanceMeters;

  /// Whether the candidate fell within the acceptable distance threshold.
  final bool isWithinTolerance;

  /// Whether the candidate satisfied the heading/direction requirements.
  final bool passesDirection;

  /// Whether the vehicle is currently inside the start geofence.
  final bool startHit;

  /// Whether the vehicle is currently inside the end geofence.
  final bool endHit;

  /// Highlights which candidate is actively being tracked.
  final bool isActive;

  /// Indicates whether the geometry is detailed or a fallback straight line.
  final bool isDetailed;

  /// Optional marker for the closest point on the path.
  final LatLng? nearestPoint;

  /// Optional difference between the vehicle heading and the segment heading.
  final double? headingDiffDeg;
}
