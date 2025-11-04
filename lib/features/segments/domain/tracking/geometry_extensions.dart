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
    int bestSegmentIndex = 0;
    double bestSegmentFraction = 0.0;

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
        bestSegmentIndex = i;
        bestSegmentFraction = t;
      }
    }

    // If the path collapsed to a single point fall back to the first vertex so
    // we can still report something useful.
    if (bestDistSq.isInfinite && offsets.isNotEmpty) {
      final math.Point<double> first = offsets.first;
      bestX = first.x;
      bestY = first.y;
      bestDistSq = bestX * bestX + bestY * bestY;
      bestSegmentIndex = 0;
      bestSegmentFraction = 0.0;
    }

    final double nearestLat = refLat + (bestY / mPerDegLat);
    final double nearestLon = refLon + (bestX / mPerDegLon);
    final double distance = math.sqrt(bestDistSq.abs());

    return _NearestPointResult(
      distanceMeters: distance,
      point: GeoPoint(nearestLat, nearestLon),
      segmentIndex: bestSegmentIndex,
      segmentFraction: bestSegmentFraction,
    );
  }

  /// Converts the polyline [path] into a [LatLng] list suitable for map widgets.
  List<LatLng> _pathToLatLngList(List<GeoPoint> path) {
    return path.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);
  }

  /// Computes the remaining distance along [path] starting from the provided
  /// segment index and fractional position within that segment.
  double _distanceToPathEnd(
    List<GeoPoint> path,
    int segmentIndex,
    double segmentFraction,
  ) {
    if (path.length < 2) {
      return 0.0;
    }

    final int clampedIndex = math.max(0, math.min(segmentIndex, path.length - 2));
    final double clampedFraction = segmentFraction.clamp(0.0, 1.0);

    double remaining = 0.0;

    final GeoPoint start = path[clampedIndex];
    final GeoPoint end = path[clampedIndex + 1];
    final double segmentLength = _distanceBetween(start, end);
    if (segmentLength.isFinite && segmentLength > 0) {
      remaining += (1.0 - clampedFraction) * segmentLength;
    }

    for (int i = clampedIndex + 1; i < path.length - 1; i++) {
      final double segLen = _distanceBetween(path[i], path[i + 1]);
      if (segLen.isFinite && segLen > 0) {
        remaining += segLen;
      }
    }

    return remaining;
  }

  double? _bearingBetweenPoints(GeoPoint from, GeoPoint to) {
    final double lat1 = from.lat * math.pi / 180.0;
    final double lat2 = to.lat * math.pi / 180.0;
    final double dLon = (to.lon - from.lon) * math.pi / 180.0;

    if (dLon.abs() < 1e-9 && (lat2 - lat1).abs() < 1e-9) {
      return null;
    }

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final double bearing = math.atan2(y, x) * 180.0 / math.pi;

    final double normalized = (bearing + 360.0) % 360.0;
    return normalized.isFinite ? normalized : null;
  }

  double _normalizeHeading(double heading) {
    final double normalized = heading % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  double _headingDeltaDegrees(double a, double b) {
    final double normalizedA = _normalizeHeading(a);
    final double normalizedB = _normalizeHeading(b);
    final double diff = (normalizedA - normalizedB).abs() % 360.0;
    return diff > 180.0 ? 360.0 - diff : diff;
  }

  double? _segmentHeadingAtStart(List<GeoPoint> path) {
    if (path.length < 2) {
      return null;
    }

    for (int i = 0; i < path.length - 1; i++) {
      final GeoPoint from = path[i];
      final GeoPoint to = path[i + 1];
      final double segmentLength = _distanceBetween(from, to);
      if (!segmentLength.isFinite) {
        continue;
      }
      if (segmentLength >= SegmentTracker._minimumHeadingSegmentLengthMeters) {
        return _bearingBetweenPoints(from, to);
      }
    }

    return _bearingBetweenPoints(path.first, path.last);
  }
}

/// Captures the result of projecting a point onto a polyline.
class _NearestPointResult {
  const _NearestPointResult({
    required this.distanceMeters,
    required this.point,
    required this.segmentIndex,
    required this.segmentFraction,
  });

  /// Distance in metres from the original point to the projected point.
  final double distanceMeters;

  /// The closest location on the path to the original point.
  final GeoPoint point;

  /// Index of the segment containing the projected point.
  final int segmentIndex;

  /// Fractional position along the segment containing the projected point.
  final double segmentFraction;
}
