// lib/services/segments/segment_geometry.dart
import 'geo.dart';

class SegmentGeometry {
  final String id;
  final List<GeoPoint> path;      // at least 2 points (start/end or full polyline)
  final double? lengthMeters;     // optional if you have it

  SegmentGeometry({
    required this.id,
    required this.path,
    this.lengthMeters,
  }) : assert(path.length >= 2, 'Segment needs ≥ 2 points');

  GeoBounds get bounds {
    double minLat = double.infinity, minLon = double.infinity;
    double maxLat = -double.infinity, maxLon = -double.infinity;
    for (final p in path) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    return GeoBounds(minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon);
  }
}
