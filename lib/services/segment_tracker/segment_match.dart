part of segment_tracker;

/// Describes how well a single [SegmentGeometry] matched the current vehicle
/// position. Instances are short-lived and used to drive ranking, transitions
/// and debug visualisations.
class SegmentMatch {
  SegmentMatch({
    required this.geometry,
    required this.path,
    required this.distanceMeters,
    required this.nearestPoint,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.headingDiffDeg,
    required this.withinTolerance,
    required this.startHit,
    required this.endHit,
    required this.passesDirection,
    required this.isDetailed,
  });

  /// Geometry that produced the match.
  final SegmentGeometry geometry;

  /// Path representation used for the evaluation, potentially enhanced.
  final List<GeoPoint> path;

  /// Distance from the current position to the closest point on [path].
  final double distanceMeters;

  /// Closest point on [path] to the vehicle position.
  final GeoPoint nearestPoint;

  /// Distance from the current position to the start of the segment.
  final double startDistanceMeters;

  /// Distance from the current position to the end of the segment.
  final double endDistanceMeters;

  /// Difference between the vehicle heading and the segment heading, if known.
  final double? headingDiffDeg;

  /// Whether the match is within the configured spatial tolerance.
  final bool withinTolerance;

  /// Whether the vehicle is inside the segment's start geofence.
  final bool startHit;

  /// Whether the vehicle is inside the segment's end geofence.
  final bool endHit;

  /// Whether the heading and direction constraints are satisfied.
  final bool passesDirection;

  /// Indicates if [path] contains detailed geometry rather than a fallback line.
  final bool isDetailed;
}
