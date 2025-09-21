part of segment_tracker;

/// Geometry helpers used by [SegmentTracker] to reason about distances and
/// bearings on the earth's surface.
extension _SegmentTrackerGeometry on SegmentTracker {
  /// Builds a square around [center] that approximates the radial candidate
  /// search region. Using a square keeps the debug overlay simple while still
  /// enclosing the full radius.
  List<LatLng> _computeQuerySquare(LatLng center, double radiusMeters) {
    const double mPerDegLat = 111320.0;
    final double latRad = center.latitude * math.pi / 180.0;
    final double mPerDegLon = (mPerDegLat * math.cos(latRad)).clamp(1e-9, double.infinity);
    final double dLat = radiusMeters / mPerDegLat;
    final double dLon = radiusMeters / mPerDegLon;

    final double minLat = center.latitude - dLat;
    final double maxLat = center.latitude + dLat;
    final double minLon = center.longitude - dLon;
    final double maxLon = center.longitude + dLon;

    return <LatLng>[
      LatLng(minLat, minLon),
      LatLng(minLat, maxLon),
      LatLng(maxLat, maxLon),
      LatLng(maxLat, minLon),
      LatLng(minLat, minLon),
    ];
  }

  /// Returns the absolute angular difference between two headings in degrees
  /// while accounting for wrap-around at 0/360.
  double _angularDifferenceDegrees(double a, double b) {
    double diff = (a - b).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    return diff;
  }

  /// Computes the forward bearing from [from] to [to] in degrees.
  double _bearingBetween(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180.0;
    final double lat2 = to.latitude * math.pi / 180.0;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180.0;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x) * 180.0 / math.pi;
    if (bearing < 0) bearing += 360.0;
    return bearing;
  }

  /// Computes the great-circle distance between [a] and [b] using the Haversine
  /// formula so that distances remain accurate regardless of position.
  double _distanceBetween(GeoPoint a, GeoPoint b) {
    const double earthRadius = 6371000.0; // meters
    final double lat1 = a.lat * math.pi / 180.0;
    final double lat2 = b.lat * math.pi / 180.0;
    final double dLat = lat2 - lat1;
    final double dLon = (b.lon - a.lon) * math.pi / 180.0;

    final double sinLat = math.sin(dLat / 2);
    final double sinLon = math.sin(dLon / 2);
    final double h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadius * c;
  }

  /// Finds the closest point on the polyline [path] to the provided [point],
  /// returning both the projected point and the direction of travel at that
  /// location when it can be derived.
  _NearestPointResult _nearestPointOnPath(GeoPoint point, List<GeoPoint> path) {
    const double mPerDegLat = 111320.0;
    final double latRad = point.lat * math.pi / 180.0;
    final double mPerDegLon = (mPerDegLat * math.cos(latRad)).clamp(1e-9, double.infinity);
    final double refLat = point.lat;
    final double refLon = point.lon;

    double bestDistSq = double.infinity;
    double bestX = 0;
    double bestY = 0;
    double? bestBearingDeg;

    // Convert the path into offsets expressed in metres so we can perform
    // inexpensive Cartesian projections while keeping reasonable precision.
    final offsets = <math.Point<double>>[];
    for (final p in path) {
      final double x = (p.lon - refLon) * mPerDegLon;
      final double y = (p.lat - refLat) * mPerDegLat;
      offsets.add(math.Point<double>(x, y));
    }

    for (var i = 0; i < offsets.length - 1; i++) {
      final math.Point<double> a = offsets[i];
      final math.Point<double> b = offsets[i + 1];
      final double dx = b.x - a.x;
      final double dy = b.y - a.y;
      final double lenSq = dx * dx + dy * dy;
      if (lenSq <= 1e-6) continue;

      // Project the point onto the segment, clamping to the segment ends.
      var t = (-(a.x * dx + a.y * dy)) / lenSq;
      if (t < 0) t = 0;
      if (t > 1) t = 1;

      final double projX = a.x + dx * t;
      final double projY = a.y + dy * t;
      final double distSq = projX * projX + projY * projY;
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        bestX = projX;
        bestY = projY;
        final double bearingRad = math.atan2(dx, dy);
        double bearingDeg = bearingRad * 180.0 / math.pi;
        if (bearingDeg < 0) bearingDeg += 360.0;
        bestBearingDeg = bearingDeg;
      }
    }

    // If the path collapsed to a single point fall back to the first vertex so
    // we can still report something useful.
    if (bestDistSq.isInfinite && offsets.isNotEmpty) {
      final math.Point<double> first = offsets.first;
      bestX = first.x;
      bestY = first.y;
      bestDistSq = bestX * bestX + bestY * bestY;
      if (offsets.length >= 2) {
        final math.Point<double> next = offsets[1];
        final double dx = next.x - first.x;
        final double dy = next.y - first.y;
        final double bearingRad = math.atan2(dx, dy);
        double bearingDeg = bearingRad * 180.0 / math.pi;
        if (bearingDeg < 0) bearingDeg += 360.0;
        bestBearingDeg = bearingDeg;
      }
    }

    final double nearestLat = refLat + (bestY / mPerDegLat);
    final double nearestLon = refLon + (bestX / mPerDegLon);
    final double distance = math.sqrt(bestDistSq.abs());

    return _NearestPointResult(
      distanceMeters: distance,
      point: GeoPoint(nearestLat, nearestLon),
      bearingDeg: bestBearingDeg,
    );
  }

  /// Converts the polyline [path] into a [LatLng] list suitable for map widgets.
  List<LatLng> _pathToLatLngList(List<GeoPoint> path) {
    return path.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);
  }
}

/// Captures the result of projecting a point onto a polyline.
class _NearestPointResult {
  const _NearestPointResult({
    required this.distanceMeters,
    required this.point,
    this.bearingDeg,
  });

  /// Distance in metres from the original point to the projected point.
  final double distanceMeters;

  /// The closest location on the path to the original point.
  final GeoPoint point;

  /// Heading of the path at [point] when it could be derived.
  final double? bearingDeg;
}
