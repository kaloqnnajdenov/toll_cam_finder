part of segment_tracker;

extension _SegmentTrackerHeading on SegmentTracker {
  double? _resolveHeading(
    LatLng current,
    LatLng? previous,
    double? rawHeading,
    double? speedKmh,
  ) {
    double? heading = _normalizeHeading(rawHeading);
    final bool speedOk = speedKmh == null || speedKmh >= directionMinSpeedKmh;
    if (heading != null && speedOk) {
      return heading;
    }

    if (previous != null) {
      final GeoPoint prevPoint = GeoPoint(previous.latitude, previous.longitude);
      final GeoPoint currPoint = GeoPoint(current.latitude, current.longitude);
      if (_distanceBetween(prevPoint, currPoint) >= 3) {
        return _bearingBetween(previous, current);
      }
    }

    return heading;
  }

  double? _normalizeHeading(double? heading) {
    if (heading == null || !heading.isFinite) return null;
    double value = heading % 360.0;
    if (value < 0) value += 360.0;
    return value;
  }
}
