import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system_stub.dart'
    if (dart.library.io) 'package:toll_cam_finder/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/services/toll_segments_paths.dart';

/// Persists detailed segment paths fetched from remote routing services so they
/// can be reused across app launches.
class SegmentPathCacheService {
  SegmentPathCacheService({
    TollSegmentsFileSystem? fileSystem,
    TollSegmentsPathResolver? pathResolver,
  })  : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
        _pathResolver = pathResolver;

  final TollSegmentsFileSystem _fileSystem;
  final TollSegmentsPathResolver? _pathResolver;
  Map<String, List<GeoPoint>>? _cache;

  /// Loads all cached segment paths from disk.
  Future<Map<String, List<GeoPoint>>> loadAllPaths() async {
    if (kIsWeb) {
      _cache = const <String, List<GeoPoint>>{};
      return _cache!;
    }

    if (_cache != null) {
      return _cache!;
    }

    try {
      final path = await resolveSegmentPathsCachePath(
        overrideResolver: _pathResolver,
      );
      if (!await _fileSystem.exists(path)) {
        _cache = const <String, List<GeoPoint>>{};
        return _cache!;
      }

      final raw = await _fileSystem.readAsString(path);
      if (raw.trim().isEmpty) {
        _cache = const <String, List<GeoPoint>>{};
        return _cache!;
      }

      final dynamic decoded = jsonDecode(raw);
      final parsed = _parseFeatureCollection(decoded);
      _cache = _asUnmodifiable(parsed);
      return _cache!;
    } on TollSegmentsFileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SegmentPathCacheException(
          'Failed to access the stored segment paths.',
          cause: error,
        ),
        stackTrace,
      );
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SegmentPathCacheException(
          'Failed to parse the stored segment paths.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  /// Stores or replaces the cached path for [segmentId].
  Future<void> savePath(String segmentId, List<GeoPoint> path) async {
    if (kIsWeb) {
      return;
    }

    final normalized = List<GeoPoint>.unmodifiable(
      path.map((p) => GeoPoint(p.lat, p.lon)),
    );

    final current = Map<String, List<GeoPoint>>.from(await loadAllPaths());
    current[segmentId] = normalized;

    final unmodifiable = _asUnmodifiable(current);
    final payload = jsonEncode(_buildFeatureCollection(unmodifiable));

    try {
      final path = await resolveSegmentPathsCachePath(
        overrideResolver: _pathResolver,
      );
      await _fileSystem.ensureParentDirectory(path);
      await _fileSystem.writeAsString(path, payload);
      _cache = unmodifiable;
    } on TollSegmentsFileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SegmentPathCacheException(
          'Failed to persist the segment path for $segmentId.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  Map<String, List<GeoPoint>> _parseFeatureCollection(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('GeoJSON must be an object.');
    }
    if (data['type'] != 'FeatureCollection') {
      throw const FormatException('GeoJSON must be a FeatureCollection.');
    }
    final features = data['features'];
    if (features is! List) {
      throw const FormatException('GeoJSON FeatureCollection missing features.');
    }

    final result = <String, List<GeoPoint>>{};
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) {
        continue;
      }

      final props = feature['properties'];
      String? id;
      if (props is Map<String, dynamic>) {
        final dynamic rawId = props['segment_id'] ?? props['id'];
        if (rawId != null) {
          id = '$rawId';
        }
      }
      id ??= feature['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }

      final geometry = feature['geometry'];
      if (geometry is! Map<String, dynamic>) {
        continue;
      }

      if (geometry['type'] != 'LineString') {
        continue;
      }

      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) {
        continue;
      }

      final path = <GeoPoint>[];
      for (final coord in coords) {
        if (coord is List && coord.length >= 2) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          path.add(GeoPoint(lat, lon));
        }
      }

      if (path.length < 2) {
        continue;
      }

      result[id] = List<GeoPoint>.unmodifiable(path);
    }

    return result;
  }

  Map<String, List<GeoPoint>> _asUnmodifiable(
    Map<String, List<GeoPoint>> input,
  ) {
    return Map<String, List<GeoPoint>>.unmodifiable(
      input.map(
        (key, value) => MapEntry(
          key,
          List<GeoPoint>.unmodifiable(value),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildFeatureCollection(
    Map<String, List<GeoPoint>> data,
  ) {
    final features = <Map<String, dynamic>>[];
    data.forEach((id, points) {
      if (points.length < 2) {
        return;
      }
      features.add({
        'type': 'Feature',
        'properties': <String, dynamic>{'segment_id': id},
        'geometry': <String, dynamic>{
          'type': 'LineString',
          'coordinates': points
              .map((point) => <double>[point.lon, point.lat])
              .toList(growable: false),
        },
      });
    });

    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': features,
    };
  }
}

class SegmentPathCacheException implements Exception {
  const SegmentPathCacheException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'SegmentPathCacheException: $message';
}
