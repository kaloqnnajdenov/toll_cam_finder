part of segment_tracker;

extension _SegmentTrackerPathFetching on SegmentTracker {
  void _ensureEnhancedPath(SegmentGeometry geometry) {
    if (geometry.path.length > 2) {
      return;
    }
    if (_pathOverrides.containsKey(geometry.id)) {
      return;
    }
    if (_fetchFailures.contains(geometry.id)) {
      return;
    }
    if (_fetching.contains(geometry.id)) {
      return;
    }

    _fetching.add(geometry.id);
    unawaited(_downloadAndStorePath(geometry));
  }

  Future<void> _downloadAndStorePath(SegmentGeometry geometry) async {
    List<GeoPoint>? enhanced;
    try {
      enhanced = await _fetchDetailedPath(geometry.path.first, geometry.path.last);
    } finally {
      if (enhanced != null && enhanced.length >= 2) {
        final stored = List<GeoPoint>.unmodifiable(enhanced);
        _pathOverrides[geometry.id] = stored;
        _fetchFailures.remove(geometry.id);
        if (_active != null && _active!.geometry.id == geometry.id) {
          _active!
            ..path = stored
            ..forceKeepUntilEnd = false
            ..enforceDirection = true
            ..consecutiveMisses = 0
            ..lastMatch = null;
        }
        if (kDebugMode) {
          debugPrint('[SEG] enhanced path ready for ${geometry.id} (${enhanced.length} pts)');
        }
      } else {
        _fetchFailures.add(geometry.id);
        if (_active != null && _active!.geometry.id == geometry.id) {
          _active!
            ..forceKeepUntilEnd = true
            ..enforceDirection = false;
        }
        if (kDebugMode) {
          debugPrint('[SEG] enhanced path unavailable for ${geometry.id}');
        }
      }
      _fetching.remove(geometry.id);
    }
  }

  Future<List<GeoPoint>?> _fetchDetailedPath(GeoPoint start, GeoPoint end) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.lon},${start.lat};${end.lon},${end.lat}?overview=full&geometries=geojson',
    );

    try {
      final response = await _httpClient.get(uri, headers: const {
        'User-Agent': 'toll_cam_finder/segment-tracker',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[SEG] enhanced path status ${response.statusCode} for ${uri.path}');
        }
        return null;
      }

      final dynamic decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first;
      if (route is! Map<String, dynamic>) return null;

      dynamic geometry = route['geometry'];
      List? coords;
      if (geometry is Map<String, dynamic> && geometry['coordinates'] is List) {
        coords = geometry['coordinates'] as List;
      } else if (geometry is List) {
        coords = geometry;
      }
      if (coords == null) return null;

      final path = <GeoPoint>[];
      for (final coord in coords) {
        if (coord is List && coord.length >= 2) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          path.add(GeoPoint(lat, lon));
        }
      }

      if (path.length < 2) {
        return null;
      }

      if (_distanceBetween(path.first, start) > 5) {
        path.insert(0, start);
      }
      if (_distanceBetween(path.last, end) > 5) {
        path.add(end);
      }

      return path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SEG] failed to fetch enhanced path: $e');
      }
      return null;
    }
  }

  List<GeoPoint> _effectivePathFor(SegmentGeometry geom) {
    return _pathOverrides[geom.id] ?? geom.path;
  }

  bool _isPathDetailed(SegmentGeometry geom, List<GeoPoint> path) {
    if (_pathOverrides.containsKey(geom.id)) {
      return true;
    }
    return path.length > 2;
  }
}
