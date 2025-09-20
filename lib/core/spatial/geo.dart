// lib/services/segments/geo.dart
import 'dart:math' as math;

class GeoPoint {
  final double lat; // y
  final double lon; // x
  const GeoPoint(this.lat, this.lon);
}

class GeoBounds {
  final double minLat, minLon, maxLat, maxLon;
  const GeoBounds({
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
  });

  static GeoBounds around(GeoPoint c, double radiusMeters) {
    // ~1 deg lat ≈ 111_320 m; lon is scaled by cos(latitude)
    const mPerDegLat = 111_320.0;
    final mPerDegLon = (mPerDegLat * math.cos(c.lat * math.pi / 180.0))
        .clamp(1e-9, double.infinity);
    final dLat = radiusMeters / mPerDegLat;
    final dLon = radiusMeters / mPerDegLon;

    return GeoBounds(
      minLat: c.lat - dLat,
      minLon: c.lon - dLon,
      maxLat: c.lat + dLat,
      maxLon: c.lon + dLon,
    );
  }
}
