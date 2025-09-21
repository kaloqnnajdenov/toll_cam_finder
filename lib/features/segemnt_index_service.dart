// imports you likely already have:
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';

// add these if not present:
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/core/spatial/segment_spatial_index.dart';

// -----------------------------------------------------------------------------
// SegmentIndexService
// - Loads segments from an asset (plain JSON array OR GeoJSON FeatureCollection)
// - Builds an R-tree index for fast bbox queries
// - Exposes candidate lookups near a LatLng
// -----------------------------------------------------------------------------
class SegmentIndexService {
  SegmentIndexService._();
  static final SegmentIndexService instance = SegmentIndexService._();

  SegmentSpatialIndex? _index;
  bool get isReady => _index != null;

  Future<void> buildFromGeometries(List<SegmentGeometry> segments) async {
    _index = SegmentSpatialIndex.build(segments);
  }

  @visibleForTesting
  void resetForTest() {
    _index = null;
  }

  /// Tries to load from [assetPath]:
  /// - If it's a JSON array: [{id, points:[{lat,lon},...], length_m?}, ...]
  /// - Else, if it's a GeoJSON FeatureCollection with LineString/MultiLineString.
  ///
  /// Example call from MapPage:
  ///   await _segIndex.tryLoadFromDefaultAsset(
  ///     assetPath: 'assets/data/toll_segments.geojson',
  ///   );
  Future<void> tryLoadFromDefaultAsset({String assetPath = 'assets/data/segments.json'}) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final dynamic decoded = json.decode(raw);

      List<SegmentGeometry> segments;

      if (decoded is List) {
        // Plain JSON array path
        segments = _parsePlainArray(decoded);
      } else if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'FeatureCollection' &&
          decoded['features'] is List) {
        // GeoJSON FeatureCollection path
        segments = _parseGeoJson(decoded);
      } else {
        throw const FormatException('Unknown segment format');
      }

      if (segments.isNotEmpty) {
        await buildFromGeometries(segments);
        debugPrint('Segment index built with ${segments.length} segments from $assetPath.');
      } else {
        debugPrint('SegmentIndexService: no segments parsed from $assetPath.');
      }
    } catch (e) {
      debugPrint('SegmentIndexService: $assetPath not loaded (${e.runtimeType}).');
    }
  }

  // -----------------------------------------------------------------------------
  // Parsers
  // -----------------------------------------------------------------------------

  /// Plain JSON array format:
  /// [
  ///   {
  ///     "id": "...",
  ///     "points": [{"lat": .., "lon": ..}, ...]  // OR "lng"
  ///     "length_m": 1234
  ///   },
  ///   OR
  ///   {
  ///     "id": "...",
  ///     "start": {"lat": .., "lon": ..},
  ///     "end":   {"lat": .., "lon": ..}
  ///   }
  /// ]
  List<SegmentGeometry> _parsePlainArray(List list) {
    final segments = <SegmentGeometry>[];
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final id = '${m["id"]}';
      List<GeoPoint> pts;

      if (m['points'] is List) {
        pts = (m['points'] as List).map((p) {
          final mp = p as Map<String, dynamic>;
          final lat = (mp['lat'] as num).toDouble();
          final lon = ((mp['lon'] ?? mp['lng']) as num).toDouble();
          return GeoPoint(lat, lon);
        }).toList();
      } else if (m['start'] is Map && m['end'] is Map) {
        final s = m['start'] as Map<String, dynamic>;
        final t = m['end'] as Map<String, dynamic>;
        pts = [
          GeoPoint((s['lat'] as num).toDouble(), ((s['lon'] ?? s['lng']) as num).toDouble()),
          GeoPoint((t['lat'] as num).toDouble(), ((t['lon'] ?? t['lng']) as num).toDouble()),
        ];
      } else {
        debugPrint('SegmentIndexService: skip $id (no geometry in plain array).');
        continue;
      }

      final len = (m['length_m'] is num) ? (m['length_m'] as num).toDouble() : null;
      segments.add(SegmentGeometry(id: id, path: pts, lengthMeters: len));
    }
    return segments;
  }

  /// GeoJSON parser: supports LineString and MultiLineString.
  /// Expects coordinates in [lon, lat] (GeoJSON spec).
  /// Uses properties.segment_id as id when present; falls back to feature.id or properties.id.
  List<SegmentGeometry> _parseGeoJson(Map<String, dynamic> fc) {
    final features = (fc['features'] as List).cast<Map<String, dynamic>>();
    final segments = <SegmentGeometry>[];

    for (final feat in features) {
      final geom = (feat['geometry'] ?? const {}) as Map<String, dynamic>;
      final type = (geom['type'] ?? '') as String;

      final props = (feat['properties'] ?? const {}) as Map<String, dynamic>;
      // Prefer properties.segment_id (your schema), then feature.id, then properties.id.
      final dynamic rawId = props['segment_id'] ?? feat['id'] ?? props['id'];
      final id = (rawId == null) ? UniqueKey().toString() : '$rawId';

      double? lengthMeters;
      if (props['length_m'] is num) {
        lengthMeters = (props['length_m'] as num).toDouble();
      }

      List<GeoPoint> path;

      if (type == 'LineString') {
        final coords = (geom['coordinates'] as List);
        path = _toGeoPointsFromLonLatList(coords);
      } else if (type == 'MultiLineString') {
        final lines = (geom['coordinates'] as List);
        // Flatten all parts; alternatively, you could pick the longest sub-line.
        path = <GeoPoint>[];
        for (final part in lines) {
          path.addAll(_toGeoPointsFromLonLatList(part as List));
        }
      } else {
        // Unsupported geometry types are skipped
        debugPrint('SegmentIndexService: skip feature $id (geometry type $type).');
        continue;
      }

      if (path.length < 2) {
        debugPrint('SegmentIndexService: skip $id (path < 2 points).');
        continue;
      }

      segments.add(SegmentGeometry(id: id, path: path, lengthMeters: lengthMeters));
    }

    return segments;
  }

  /// coords: [[lon, lat], [lon, lat], ...]
  List<GeoPoint> _toGeoPointsFromLonLatList(List coords) {
    final out = <GeoPoint>[];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        out.add(GeoPoint(lat, lon)); // convert to (lat, lon)
      }
    }
    return out;
  }

  // -----------------------------------------------------------------------------
  // Public query helpers (used by MapPage)
  // -----------------------------------------------------------------------------
  List<SegmentGeometry> candidatesNearLatLng(LatLng p, {double radiusMeters = 150}) {
    final idx = _index;
    if (idx == null) return const [];
    return idx.candidatesNear(GeoPoint(p.latitude, p.longitude), radiusMeters: radiusMeters);
    // NOTE: idx returns segment geometries whose bounding boxes intersect the query bbox.
    // Do precise point-to-polyline checks in your Step 3 code after this prefilter.
  }

  List<String> candidateIdsNearLatLng(LatLng p, {double radiusMeters = 150}) {
    return candidatesNearLatLng(p, radiusMeters: radiusMeters)
        .map((g) => g.id)
        .toList(growable: false);
  }

  @visibleForTesting
  List<SegmentGeometry> parsePlainArrayForTest(List list) => _parsePlainArray(list);

  @visibleForTesting
  List<SegmentGeometry> parseGeoJsonForTest(Map<String, dynamic> fc) => _parseGeoJson(fc);

  @visibleForTesting
  List<GeoPoint> toGeoPointsFromLonLatListForTest(List coords) => _toGeoPointsFromLonLatList(coords);
}
