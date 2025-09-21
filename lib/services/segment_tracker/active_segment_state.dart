part of segment_tracker;

class _ActiveSegmentState {
  _ActiveSegmentState({
    required this.geometry,
    required this.path,
    required this.forceKeepUntilEnd,
    required this.enforceDirection,
    required this.enteredAt,
  });

  final SegmentGeometry geometry;
  List<GeoPoint> path;
  bool forceKeepUntilEnd;
  bool enforceDirection;
  final DateTime enteredAt;
  int consecutiveMisses = 0;
  SegmentMatch? lastMatch;
}
