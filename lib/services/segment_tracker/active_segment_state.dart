part of segment_tracker;

/// Holds the mutable bookkeeping for the segment that is currently
/// considered active by [SegmentTracker].
class _ActiveSegmentState {
  /// Creates a new state snapshot for the active segment. The caller provides
  /// the geometry and initial settings derived from the match that promoted the
  /// segment to the active state.
  _ActiveSegmentState({
    required this.geometry,
    required this.path,
    required this.forceKeepUntilEnd,
    required this.enforceDirection,
    required this.enteredAt,
  });

  /// Geometry metadata describing the underlying road segment.
  final SegmentGeometry geometry;

  /// Polyline currently used for proximity checks. This may be upgraded to a
  /// denser path when an enhanced route is fetched.
  List<GeoPoint> path;

  /// When `true` the tracker keeps the segment active until it is explicitly
  /// exited, even if interim matches are weak.
  bool forceKeepUntilEnd;

  /// When `true` heading alignment is enforced while matching against the
  /// segment geometry.
  bool enforceDirection;

  /// Timestamp at which the segment became active, used by timeout heuristics.
  final DateTime enteredAt;

  /// Number of consecutive update cycles in which the active segment failed to
  /// produce a satisfactory match.
  int consecutiveMisses = 0;

  /// Most recent positive match for the active segment. This is reused for
  /// debugging and to provide continuity when no fresh candidates are present.
  SegmentMatch? lastMatch;
}
