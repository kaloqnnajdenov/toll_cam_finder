// imports you likely already have:
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';

// add these if not present:
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/core/spatial/segment_spatial_index.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_data_store.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_file_system_stub.dart'
    if (dart.library.io)
      'package:toll_cam_finder/features/segments/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/features/segments/services/toll_segments_paths.dart';

// -----------------------------------------------------------------------------
// SegmentIndexService
// - Loads segments from an asset (plain JSON array OR GeoJSON FeatureCollection)
// - Builds an R-tree index for fast bbox queries
// - Exposes candidate lookups near a LatLng
// -----------------------------------------------------------------------------
class SegmentIndexService {
  SegmentIndexService._({TollSegmentsFileSystem? fileSystem})
    : _fileSystem = fileSystem ?? fs_impl.createFileSystem();
  static final SegmentIndexService instance = SegmentIndexService._();

  SegmentSpatialIndex? _index;
  bool get isReady => _index != null;
  final TollSegmentsFileSystem _fileSystem;

  Future<void> buildFromGeometries(List<SegmentGeometry> segments) async {
    _index = SegmentSpatialIndex.build(segments);
  }

  List<SegmentGeometry> _deserializeSegments(
    List<Map<String, Object?>> rawSegments,
  ) {
    final segments = <SegmentGeometry>[];
    for (final data in rawSegments) {
      final String? id = data['id'] as String?;
      final List<dynamic>? rawPath = data['path'] as List<dynamic>?;
      if (id == null || rawPath == null) {
        continue;
      }

      final path = <GeoPoint>[];
      for (final entry in rawPath) {
        if (entry is List && entry.length >= 2) {
          final lat = (entry[0] as num?)?.toDouble();
          final lon = (entry[1] as num?)?.toDouble();
          if (lat != null && lon != null) {
            path.add(GeoPoint(lat, lon));
          }
        }
      }

      if (path.length < 2) {
        continue;
      }

      final double? lengthMeters =
          (data['lengthMeters'] as num?)?.toDouble();
      final double? speedLimit =
          (data['speedLimitKph'] as num?)?.toDouble();

      segments.add(
        SegmentGeometry(
          id: id,
          path: path,
          lengthMeters: lengthMeters,
          speedLimitKph: speedLimit,
        ),
      );
    }
    return segments;
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
  ///     assetPath: 'assets/data/toll_segments.csv',
  ///   );
  Future<void> tryLoadFromDefaultAsset({
    String assetPath = 'assets/data/segments.json',
  }) async {
    try {
      final raw = await _loadSegmentsData(assetPath);

      final parseArgs = <String, Object?>{
        'raw': raw,
        'assetPath': assetPath,
      };

      List<Map<String, Object?>> serialized;
      try {
        serialized = await compute(_parseSegmentsInBackground, parseArgs);
      } on FlutterError {
        serialized = _parseSegmentsInBackground(parseArgs);
      }

      final segments = _deserializeSegments(serialized);

      if (segments.isNotEmpty) {
        await buildFromGeometries(segments);
        debugPrint(
          'Segment index built with ${segments.length} segments from $assetPath.',
        );
      } else {
        debugPrint('SegmentIndexService: no segments parsed from $assetPath.');
      }
    } catch (e) {
      debugPrint(
        'SegmentIndexService: $assetPath not loaded (${e.runtimeType}).',
      );
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
  List<SegmentGeometry> candidatesNearLatLng(
    LatLng p, {
    double radiusMeters = 150,
  }) {
    final idx = _index;
    if (idx == null) return const [];
    return idx.candidatesNear(
      GeoPoint(p.latitude, p.longitude),
      radiusMeters: radiusMeters,
    );
    // NOTE: idx returns segment geometries whose bounding boxes intersect the query bbox.
    // Do precise point-to-polyline checks in your Step 3 code after this prefilter.
  }

  List<String> candidateIdsNearLatLng(LatLng p, {double radiusMeters = 150}) {
    return candidatesNearLatLng(
      p,
      radiusMeters: radiusMeters,
    ).map((g) => g.id).toList(growable: false);
  }

  List<SegmentGeometry> segmentsWithinBounds(LatLngBounds bounds) {
    final idx = _index;
    if (idx == null) {
      return const [];
    }

    final southWest = bounds.southWest;
    final northEast = bounds.northEast;
    final geoBounds = GeoBounds(
      minLat: southWest.latitude,
      minLon: southWest.longitude,
      maxLat: northEast.latitude,
      maxLon: northEast.longitude,
    );

    return idx.segmentsWithinBounds(geoBounds);
  }

  @visibleForTesting
  List<SegmentGeometry> parsePlainArrayForTest(List list) =>
      _deserializeSegments(_parsePlainArraySerialized(list));

  @visibleForTesting
  List<SegmentGeometry> parseGeoJsonForTest(Map<String, dynamic> fc) =>
      _deserializeSegments(_parseGeoJsonSerialized(fc));

  @visibleForTesting
  List<GeoPoint> toGeoPointsFromLonLatListForTest(List coords) =>
      _toGeoPointsFromLonLatList(coords);

  Future<String> _loadSegmentsData(String assetPath) async {
    if (assetPath == kTollSegmentsAssetPath) {
      try {
        return await TollSegmentsDataStore.instance.loadCombinedCsv(
          fileSystem: _fileSystem,
          assetPath: assetPath,
        );
      } catch (error) {
        debugPrint('SegmentIndexService: falling back to asset ($error).');
      }
    }

    return rootBundle.loadString(assetPath);
  }
}

List<Map<String, Object?>> _parseSegmentsInBackground(
  Map<String, Object?> message,
) {
  final raw = message['raw'] as String? ?? '';
  final assetPath = (message['assetPath'] as String? ?? '').toLowerCase();

  if (assetPath.endsWith('.csv')) {
    return _parseCsvSerialized(raw);
  }

  final dynamic decoded = json.decode(raw);
  if (decoded is List) {
    return _parsePlainArraySerialized(decoded);
  }
  if (decoded is Map<String, dynamic> &&
      decoded['type'] == 'FeatureCollection' &&
      decoded['features'] is List) {
    return _parseGeoJsonSerialized(decoded);
  }

  throw const FormatException('Unknown segment format');
}

List<Map<String, Object?>> _parsePlainArraySerialized(List list) {
  final segments = <Map<String, Object?>>[];
  for (final entry in list) {
    if (entry is! Map) {
      continue;
    }

    final map = entry.cast<String, dynamic>();
    final id = '${map['id']}';

    List<List<double>>? path;
    if (map['points'] is List) {
      path = <List<double>>[];
      for (final point in (map['points'] as List)) {
        if (point is Map) {
          final coords = _latLonFromPointMap(point.cast<String, dynamic>());
          if (coords != null) {
            path.add(coords);
          }
        }
      }
    } else if (map['start'] is Map && map['end'] is Map) {
      final start =
          _latLonFromPointMap((map['start'] as Map).cast<String, dynamic>());
      final end =
          _latLonFromPointMap((map['end'] as Map).cast<String, dynamic>());
      if (start != null && end != null) {
        path = <List<double>>[start, end];
      }
    }

    if (path == null || path.length < 2) {
      continue;
    }

    final double? lengthMeters = _parseNullableDouble(map['length_m']);
    final double? speedLimit = _parseNullableDouble(
      map['speed_limit_kph'] ?? map['speed_limit'] ?? map['max_speed_kph'],
    );

    segments.add({
      'id': id,
      'path': path,
      if (lengthMeters != null) 'lengthMeters': lengthMeters,
      if (speedLimit != null) 'speedLimitKph': speedLimit,
    });
  }
  return segments;
}

List<Map<String, Object?>> _parseGeoJsonSerialized(
  Map<String, dynamic> featureCollection,
) {
  final features = (featureCollection['features'] as List).cast<dynamic>();
  final segments = <Map<String, Object?>>[];

  for (var index = 0; index < features.length; index += 1) {
    final feature = features[index];
    if (feature is! Map) {
      continue;
    }

    final featureMap = feature.cast<String, dynamic>();
    final geometry =
        (featureMap['geometry'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final properties =
        (featureMap['properties'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final type = (geometry['type'] ?? '').toString();

    final dynamic rawId =
        properties['segment_id'] ?? featureMap['id'] ?? properties['id'];
    final id =
        rawId == null || (rawId is String && rawId.trim().isEmpty)
            ? 'feature_$index'
            : '$rawId';

    final path = _pathFromGeoJsonGeometrySerialized(geometry, type: type);
    if (path == null || path.length < 2) {
      continue;
    }

    final lengthMeters = _parseNullableDouble(properties['length_m']);
    final speedLimit = _parseNullableDouble(
      properties['speed_limit_kph'] ?? properties['speed_limit'],
    );

    segments.add({
      'id': id,
      'path': path,
      if (lengthMeters != null) 'lengthMeters': lengthMeters,
      if (speedLimit != null) 'speedLimitKph': speedLimit,
    });
  }

  return segments;
}

List<Map<String, Object?>> _parseCsvSerialized(String raw) {
  final rows = const CsvToListConverter(
    fieldDelimiter: ';',
    shouldParseNumbers: false,
  ).convert(raw);

  if (rows.isEmpty) {
    return const [];
  }

  final header = rows.first
      .map((e) => e.toString().trim().toLowerCase())
      .toList(growable: false);
  final startIdx = header.indexOf('start');
  final endIdx = header.indexOf('end');
  final idIdx = header.indexOf('id');
  final geoJsonIdx = header.indexOf('geojson');

  if (startIdx == -1 || endIdx == -1) {
    throw FormatException(AppMessages.csvMissingStartEndColumns);
  }

  final nameIdx = header.indexOf('name');
  final roadIdx = header.indexOf('road');
  final startNameIdx = header.indexOf('start name');
  final endNameIdx = header.indexOf('end name');
  final speedLimitIdx = header.indexOf('speed_limit_kph');

  final segments = <Map<String, Object?>>[];

  var rowIdx = 0;
  for (final row in rows.skip(1)) {
    rowIdx += 1;

    final start =
        row.length > startIdx ? _latLonFromCsvCell(row[startIdx]) : null;
    final end = row.length > endIdx ? _latLonFromCsvCell(row[endIdx]) : null;

    final idParts = <String>[];
    if (nameIdx != -1 && row.length > nameIdx) {
      final name = row[nameIdx].toString().trim();
      if (name.isNotEmpty) {
        idParts.add(name);
      }
    }
    if (roadIdx != -1 && row.length > roadIdx) {
      final road = row[roadIdx].toString().trim();
      if (road.isNotEmpty) {
        idParts.add(road);
      }
    }
    if (startNameIdx != -1 && row.length > startNameIdx) {
      final startName = row[startNameIdx].toString().trim();
      if (startName.isNotEmpty) {
        idParts.add(startName);
      }
    }
    if (endNameIdx != -1 && row.length > endNameIdx) {
      final endName = row[endNameIdx].toString().trim();
      if (endName.isNotEmpty) {
        idParts.add(endName);
      }
    }

    final explicitId = idIdx != -1 && row.length > idIdx
        ? row[idIdx].toString().trim()
        : '';
    if (explicitId.isNotEmpty) {
      idParts
        ..clear()
        ..add(explicitId);
    } else {
      idParts.add('row$rowIdx');
    }

    final id = idParts.join('::');

    final speedLimit =
        speedLimitIdx != -1 && row.length > speedLimitIdx
            ? _parseNullableDouble(row[speedLimitIdx])
            : null;

    List<List<double>>? path;
    if (geoJsonIdx != -1 && row.length > geoJsonIdx) {
      path = _pathFromGeoJsonCellSerialized(row[geoJsonIdx]);
    }

    if (path == null || path.length < 2) {
      if (start == null || end == null) {
        continue;
      }
      path = <List<double>>[start, end];
    }

    segments.add({
      'id': id,
      'path': path,
      if (speedLimit != null) 'speedLimitKph': speedLimit,
    });
  }

  return segments;
}

List<double>? _latLonFromPointMap(Map<String, dynamic> map) {
  final lat = _parseNullableDouble(map['lat']);
  final lon =
      _parseNullableDouble(map['lon'] ?? map['lng'] ?? map['longitude']);
  if (lat == null || lon == null) {
    return null;
  }
  return <double>[lat, lon];
}

List<double>? _latLonFromCsvCell(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }

  final parts = text.split(',').map((part) => part.trim()).toList();
  if (parts.length < 2) {
    return null;
  }

  final lat = double.tryParse(parts[0]);
  final lon = double.tryParse(parts[1]);
  if (lat == null || lon == null) {
    return null;
  }

  return <double>[lat, lon];
}

List<List<double>>? _pathFromGeoJsonCellSerialized(Object? cell) {
  if (cell == null) {
    return null;
  }

  if (cell is String) {
    final trimmed = cell.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return _pathFromGeoJsonGeometrySerialized(json.decode(trimmed));
    } catch (_) {
      return null;
    }
  }

  return _pathFromGeoJsonGeometrySerialized(cell);
}

List<List<double>>? _pathFromGeoJsonGeometrySerialized(
  Object? geometry, {
  String? type,
}) {
  if (geometry is Map<String, dynamic>) {
    final resolvedType = type ?? (geometry['type'] ?? '').toString();
    if (resolvedType == 'Feature') {
      return _pathFromGeoJsonGeometrySerialized(geometry['geometry']);
    }
    if (resolvedType == 'LineString' && geometry['coordinates'] is List) {
      return _coordinatesToLatLonPairs(geometry['coordinates'] as List);
    }
    if (resolvedType == 'MultiLineString' && geometry['coordinates'] is List) {
      final segments = <List<double>>[];
      for (final part in geometry['coordinates'] as List) {
        if (part is List) {
          final coords = _coordinatesToLatLonPairs(part);
          if (coords != null) {
            segments.addAll(coords);
          }
        }
      }
      return segments.isEmpty ? null : segments;
    }
  } else if (geometry is List) {
    return _coordinatesToLatLonPairs(geometry);
  }

  return null;
}

List<List<double>>? _coordinatesToLatLonPairs(List coordinates) {
  final result = <List<double>>[];
  for (final entry in coordinates) {
    if (entry is List && entry.length >= 2) {
      final lon = (entry[0] as num?)?.toDouble();
      final lat = (entry[1] as num?)?.toDouble();
      if (lat != null && lon != null) {
        result.add(<double>[lat, lon]);
      }
    }
  }
  return result.isEmpty ? null : result;
}

double? _parseNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }
  return null;
}
