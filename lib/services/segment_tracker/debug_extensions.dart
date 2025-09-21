part of segment_tracker;

extension _SegmentTrackerDebugging on SegmentTracker {
  void _updateDebugData(
    LatLng current,
    List<SegmentGeometry> candidates,
    List<SegmentMatch> matches,
  ) {
    final List<LatLng> square = _computeQuerySquare(current, candidateRadiusMeters);
    final activeId = _active?.geometry.id;
    final debugPaths = <SegmentDebugPath>[];

    for (final match in matches) {
      debugPaths.add(
        SegmentDebugPath(
          id: match.geometry.id,
          polyline: List<LatLng>.unmodifiable(_pathToLatLngList(match.path)),
          distanceMeters: match.distanceMeters,
          isWithinTolerance: match.withinTolerance,
          passesDirection: match.passesDirection,
          startHit: match.startHit,
          endHit: match.endHit,
          isActive: match.geometry.id == activeId,
          isDetailed: match.isDetailed,
          nearestPoint: LatLng(match.nearestPoint.lat, match.nearestPoint.lon),
          headingDiffDeg: match.headingDiffDeg,
        ),
      );
    }

    if (_active != null &&
        _active!.lastMatch != null &&
        !matches.any((m) => m.geometry.id == _active!.geometry.id)) {
      final match = _active!.lastMatch!;
      debugPaths.add(
        SegmentDebugPath(
          id: match.geometry.id,
          polyline: List<LatLng>.unmodifiable(_pathToLatLngList(match.path)),
          distanceMeters: match.distanceMeters,
          isWithinTolerance: match.withinTolerance,
          passesDirection: match.passesDirection,
          startHit: match.startHit,
          endHit: match.endHit,
          isActive: true,
          isDetailed: match.isDetailed,
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
