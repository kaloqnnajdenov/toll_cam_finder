part of segment_tracker;

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

  final SegmentGeometry geometry;
  final List<GeoPoint> path;
  final double distanceMeters;
  final GeoPoint nearestPoint;
  final double startDistanceMeters;
  final double endDistanceMeters;
  final double? headingDiffDeg;
  final bool withinTolerance;
  final bool startHit;
  final bool endHit;
  final bool passesDirection;
  final bool isDetailed;
}
