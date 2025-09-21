part of segment_tracker;

/// Heading related utilities for [SegmentTracker].
extension _SegmentTrackerHeading on SegmentTracker {
  /// Picks the best heading estimate for the tracker to use. Preference is
  /// given to the sensor-derived [rawHeading] when it is available and the
  /// vehicle is moving fast enough; otherwise we fall back to the bearing
  /// between the current and previous location.
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
      // Only derive a bearing if the vehicle actually moved; otherwise noise in
      // GPS positions could produce wildly inaccurate headings.
      if (_distanceBetween(prevPoint, currPoint) >= 3) {
        return _bearingBetween(previous, current);
      }
    }

    return heading;
  }

  /// Normalises [heading] to the [0, 360) range and discards invalid values.
  double? _normalizeHeading(double? heading) {
    if (heading == null || !heading.isFinite) return null;
    double value = heading % 360.0;
    if (value < 0) value += 360.0;
    return value;
  }
}
