part of segment_tracker;

/// Handles downloading and storing enhanced segment polylines from OSRM so the
/// tracker can make more precise spatial decisions when basic geometry is too
/// coarse.
extension _SegmentTrackerPathFetching on SegmentTracker {
  /// Triggers an asynchronous fetch for a more detailed path when the supplied
  /// [geometry] contains only a coarse line segment. Multiple guards ensure we
  /// do not spam the remote API or repeat previous failures.
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

  /// Downloads a detailed path for [geometry] and updates the local caches. The
  /// active segment is also refreshed so it can immediately benefit from the
  /// higher resolution geometry.
  Future<void> _downloadAndStorePath(SegmentGeometry geometry) async {
    List<GeoPoint>? enhanced;
    try {
      enhanced =
          await _fetchDetailedPath(geometry.path.first, geometry.path.last);
    } finally {
      if (enhanced != null && enhanced.length >= 2) {
        final stored = List<GeoPoint>.unmodifiable(enhanced);
        _pathOverrides[geometry.id] = stored;
        _fetchFailures.remove(geometry.id);
        if (_active != null && _active!.geometry.id == geometry.id) {
          _active!
            ..path = stored
            ..forceKeepUntilEnd = false
            ..consecutiveMisses = 0
            ..lastMatch = null;
        }
        if (kDebugMode) {
          debugPrint('[SEG] enhanced path ready for ${geometry.id} '
              '(${enhanced.length} pts)');
        }
      } else {
        _fetchFailures.add(geometry.id);
        if (_active != null && _active!.geometry.id == geometry.id) {
          _active!
            .forceKeepUntilEnd = true;
        }
        if (kDebugMode) {
          debugPrint('[SEG] enhanced path unavailable for ${geometry.id}');
        }
      }
      _fetching.remove(geometry.id);
    }
  }

  /// Requests a detailed polyline between [start] and [end] from the public
  /// OSRM demo server. The result is decoded into a list of [GeoPoint]s when the
  /// request succeeds.
  Future<List<GeoPoint>?> _fetchDetailedPath(GeoPoint start, GeoPoint end) {
    return fetchOsrmRoute(
      client: _httpClient,
      start: start,
      end: end,
      onDebug: (message) {
        if (kDebugMode) {
          debugPrint('[SEG] enhanced path $message');
        }
      },
    );
  }

  /// Returns the best available path for [geom], preferring enhanced overrides
  /// when present.
  List<GeoPoint> _effectivePathFor(SegmentGeometry geom) {
    return _pathOverrides[geom.id] ?? geom.path;
  }

  /// Determines whether [path] already contains detailed geometry for [geom].
  bool _isPathDetailed(SegmentGeometry geom, List<GeoPoint> path) {
    if (_pathOverrides.containsKey(geom.id)) {
      return true;
    }
    return path.length > 2;
  }
}
