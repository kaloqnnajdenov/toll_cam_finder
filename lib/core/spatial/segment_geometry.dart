// lib/services/segments/segment_geometry.dart
import 'geo.dart';

class SegmentGeometry {
  final String id;
  final List<GeoPoint> path; // at least 2 points (start/end or full polyline)
  final double? lengthMeters; // optional if you have it
  final double? speedLimitKph; // optional max allowed speed for the segment
  final GeoBounds bounds;

  SegmentGeometry({
    required this.id,
    required this.path,
    this.lengthMeters,
    this.speedLimitKph,
  })  : assert(path.length >= 2, 'Segment needs ≥ 2 points'),
        bounds = _computeBounds(path);

  static GeoBounds _computeBounds(List<GeoPoint> path) {
    double minLat = double.infinity, minLon = double.infinity;
    double maxLat = -double.infinity, maxLon = -double.infinity;
    for (final p in path) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    return GeoBounds(
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
    );
  }
}
