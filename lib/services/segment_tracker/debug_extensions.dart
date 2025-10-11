part of segment_tracker;

/// Adds utilities that populate [SegmentTrackerDebugData] so callers can
/// visualise what the tracker considered during the last update cycle.
extension _SegmentTrackerDebugging on SegmentTracker {
  /// Recomputes the cached debug snapshot from the current candidates and
  /// matches. This method is intentionally side-effect free aside from writing
  /// [_latestDebugData]; callers decide when to surface the information.
  void _updateDebugData(
    LatLng current,
    List<SegmentGeometry> candidates,
    List<SegmentMatch> matches,
  ) {
    // Build a bounding square representing the spatial query that produced the
    // current candidate set. The square is reused by the UI overlay.
    final List<LatLng> square = _computeQuerySquare(
      current,
      candidateRadiusMeters,
    );
    final activeId = _active?.geometry.id;
    final debugPaths = <SegmentDebugPath>[];

    // Convert every match into a debug-friendly representation so the caller
    // can inspect distances, direction flags, and the path that was evaluated.
    for (final match in matches) {
      debugPaths.add(
        SegmentDebugPath(
          id: match.geometry.id,
          polyline: List<LatLng>.unmodifiable(_pathToLatLngList(match.path)),
          distanceMeters: match.distanceMeters,
          startDistanceMeters: match.startDistanceMeters,
          isWithinTolerance: match.withinTolerance,
          passesDirection: match.passesDirection,
          startHit: match.startHit,
          endHit: match.endHit,
          isActive: match.geometry.id == activeId,
          isDetailed: match.isDetailed,
          remainingDistanceMeters: match.remainingDistanceMeters,
          distanceAlongPathToStartMeters:
              match.distanceAlongPathToStartMeters,
          nearestPoint: LatLng(match.nearestPoint.lat, match.nearestPoint.lon),
          headingDiffDeg: match.headingDiffDeg,
        ),
      );
    }

    // If the currently active segment was not part of the latest match list we
    // still surface its last good match so operators see where it was lost.
    if (_active != null &&
        _active!.lastMatch != null &&
        !matches.any((m) => m.geometry.id == _active!.geometry.id)) {
      final match = _active!.lastMatch!;
      debugPaths.add(
        SegmentDebugPath(
          id: match.geometry.id,
          polyline: List<LatLng>.unmodifiable(_pathToLatLngList(match.path)),
          distanceMeters: match.distanceMeters,
          startDistanceMeters: match.startDistanceMeters,
          isWithinTolerance: match.withinTolerance,
          passesDirection: match.passesDirection,
          startHit: match.startHit,
          endHit: match.endHit,
          isActive: true,
          isDetailed: match.isDetailed,
          remainingDistanceMeters: match.remainingDistanceMeters,
          distanceAlongPathToStartMeters:
              match.distanceAlongPathToStartMeters,
          nearestPoint: LatLng(match.nearestPoint.lat, match.nearestPoint.lon),
          headingDiffDeg: match.headingDiffDeg,
        ),
      );
    }

    _latestDebugData = SegmentTrackerDebugData(
      isReady: _isReady,
      querySquare: List<LatLng>.unmodifiable(square),
      boundingCandidates: List<SegmentGeometry>.unmodifiable(candidates),
      candidatePaths: List<SegmentDebugPath>.unmodifiable(debugPaths),
      startGeofenceRadius: startGeofenceRadiusMeters,
      endGeofenceRadius: endGeofenceRadiusMeters,
    );
  }
}
