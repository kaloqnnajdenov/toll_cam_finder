library segment_tracker;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/segments/domain/index/segment_index_service.dart';

part 'segment_tracker_models.dart';
part 'segment_match.dart';
part 'active_segment_state.dart';
part 'segment_transition.dart';
part 'debug_extensions.dart';
part 'geometry_extensions.dart';

class SegmentTracker {
  SegmentTracker({
    required SegmentIndexService indexService,
    this.candidateRadiusMeters = AppConstants.candidateRadiusMeters,
    this.onPathToleranceMeters = AppConstants.segmentOnPathToleranceMeters,
    this.startGeofenceRadiusMeters =
        AppConstants.segmentStartGeofenceRadiusMeters,
    this.endGeofenceRadiusMeters = AppConstants.segmentEndGeofenceRadiusMeters,
  }) : _index = indexService;

  static const int _strictMissThreshold = 3;
  static const int _looseMissThreshold = 6;
  static const int _maxCandidateMisses = 4;
  static const double _looseExitMultiplier = 2.5;
  static const Duration _reloadKeepAliveDuration = Duration(seconds: 15);
  static const double _endReentryAllowanceMeters = 5.0;
  static const double _entryHeadingHalfFovDegrees = 90.0;
  static const double _minimumHeadingSegmentLengthMeters = 3.0;

  final SegmentIndexService _index;

  final double candidateRadiusMeters;
  final double onPathToleranceMeters;
  final double startGeofenceRadiusMeters;
  final double endGeofenceRadiusMeters;
  bool _isReady = false;
  SegmentTrackerDebugData _latestDebugData =
      const SegmentTrackerDebugData.empty();
  _ActiveSegmentState? _active;
  _ActiveSegmentSnapshot? _pendingRestore;

  final Set<String> _ignoredSegmentIds = <String>{};
  SegmentGeometry? _lastExitedGeometry;
  String? _lastEndExitSegmentId;
  double? _lastEndExitRemainingDistance;

  bool get isReady => _isReady;
  SegmentTrackerDebugData get debugData => _latestDebugData;
  String? get activeSegmentId => _active?.geometry.id;

  Future<bool> initialise({required String assetPath}) async {
    _resetTrackingState(preserveActive: false);
    if (!_index.isReady) {
      await _index.tryLoadFromDefaultAsset(assetPath: assetPath);
    }
    _isReady = _index.isReady;
    if (!_isReady) {
      _latestDebugData = const SegmentTrackerDebugData.empty();
    }
    return _isReady;
  }

  Future<bool> reload({required String assetPath}) async {
    _resetTrackingState(preserveActive: true);
    await _index.tryLoadFromDefaultAsset(assetPath: assetPath);
    _isReady = _index.isReady;
    if (!_isReady) {
      _latestDebugData = const SegmentTrackerDebugData.empty();
    }
    return _isReady;
  }

  void updateIgnoredSegments(Set<String> ignoredIds) {
    _ignoredSegmentIds
      ..clear()
      ..addAll(ignoredIds);

    if (_active != null &&
        _ignoredSegmentIds.contains(_active!.geometry.id)) {
      _clearActiveSegment(reason: 'ignored');
    }
  }

  SegmentTrackerEvent handleLocationUpdate({
    required LatLng current,
    double? headingDegrees,
  }) {
    final SegmentGeometry? exitedGeometry = _lastExitedGeometry;
    _lastExitedGeometry = null;

    final SegmentGeometry? activeGeometry = _active?.geometry;
    final _ActiveSegmentSnapshot? snapshot = _pendingRestore;
    final String? activeSegmentId =
        activeGeometry?.id ?? snapshot?.segmentId;
    final double? activeSegmentSpeedLimit =
        activeGeometry?.speedLimitKph ?? snapshot?.segmentSpeedLimitKph;
    final double? activeSegmentLength =
        activeGeometry?.lengthMeters ?? snapshot?.segmentLengthMeters;

    if (!_isReady) {
      return SegmentTrackerEvent(
        startedSegment: false,
        endedSegment: false,
        activeSegmentId: activeSegmentId,
        activeSegmentSpeedLimitKph: activeSegmentSpeedLimit,
        activeSegmentLengthMeters: activeSegmentLength,
        completedSegmentLengthMeters: exitedGeometry?.lengthMeters,
        debugData: _latestDebugData,
      );
    }

    final GeoPoint userPoint = GeoPoint(current.latitude, current.longitude);

    final List<SegmentGeometry> candidates = _index.candidatesNearLatLng(
      current,
      radiusMeters: candidateRadiusMeters,
    );

    final matches = <SegmentMatch>[];
    final filteredCandidates = <SegmentGeometry>[];
    for (final geom in candidates) {
      if (_ignoredSegmentIds.contains(geom.id)) {
        continue;
      }

      filteredCandidates.add(geom);
      final path = geom.path;
      final nearest = _nearestPointOnPath(userPoint, path);
      final double startDist = _distanceBetween(userPoint, path.first);
      final double endDist = _distanceBetween(userPoint, path.last);
      final double remainingDist = _distanceToPathEnd(
        path,
        nearest.segmentIndex,
        nearest.segmentFraction,
      );
      final bool detailed = path.length > 2;

      matches.add(
        SegmentMatch(
          geometry: geom,
          path: path,
          distanceMeters: nearest.distanceMeters,
          nearestPoint: nearest.point,
          startDistanceMeters: startDist,
          endDistanceMeters: endDist,
          remainingDistanceMeters: remainingDist,
          withinTolerance: nearest.distanceMeters <= onPathToleranceMeters,
          startHit: startDist <= startGeofenceRadiusMeters,
          endHit: endDist <= endGeofenceRadiusMeters,
          isDetailed: detailed,
        ),
      );
    }

    matches.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    _updateDebugData(current, filteredCandidates, matches);
    
    final transition = _updateActiveSegment(
      matches,
      headingDegrees: headingDegrees,
    );

    final SegmentGeometry? refreshedGeometry = _active?.geometry;
    final _ActiveSegmentSnapshot? refreshedSnapshot = _pendingRestore;

    return SegmentTrackerEvent(
      startedSegment: transition.started,
      endedSegment: transition.ended,
      activeSegmentId: refreshedGeometry?.id ?? refreshedSnapshot?.segmentId,
      activeSegmentSpeedLimitKph:
          refreshedGeometry?.speedLimitKph ?? refreshedSnapshot?.segmentSpeedLimitKph,
      activeSegmentLengthMeters:
          refreshedGeometry?.lengthMeters ?? refreshedSnapshot?.segmentLengthMeters,
      completedSegmentLengthMeters: exitedGeometry?.lengthMeters,
      debugData: _latestDebugData,
    );
  }

  double? findUpcomingSegmentDistance({
    required LatLng current,
    required double headingDegrees,
    double fieldOfViewDegrees = 120,
    double maxDistanceMeters = 5000,
  }) {
    if (!_isReady) {
      return null;
    }

    final GeoPoint userPoint = GeoPoint(current.latitude, current.longitude);
    final double normalizedHeading = _normalizeHeading(headingDegrees);
    final double halfFov = (fieldOfViewDegrees / 2).clamp(0, 180);

    final List<SegmentGeometry> candidates = _index.candidatesNearLatLng(
      current,
      radiusMeters: maxDistanceMeters,
    );

    double? closestStartDistance;

    for (final SegmentGeometry geom in candidates) {
      if (_ignoredSegmentIds.contains(geom.id)) {
        continue;
      }

      final List<GeoPoint> path = geom.path;
      if (path.isEmpty) {
        continue;
      }

      final _NearestPointResult nearest = _nearestPointOnPath(
        userPoint,
        path,
      );

      final double? bearingToNearest = _bearingBetweenPoints(
        userPoint,
        nearest.point,
      );

      final double relativeBearing =
          bearingToNearest ?? normalizedHeading;
      final double headingDelta = _headingDeltaDegrees(
        normalizedHeading,
        relativeBearing,
      );

      if (headingDelta > halfFov) {
        continue;
      }

      final double startDistance = _distanceBetween(
        userPoint,
        path.first,
      );

      if (!startDistance.isFinite || startDistance < 0) {
        continue;
      }
      if (startDistance > maxDistanceMeters) {
        continue;
      }

      if (closestStartDistance == null ||
          startDistance < closestStartDistance) {
        closestStartDistance = startDistance;
      }
    }

    return closestStartDistance;
  }

  void dispose() {}

  void _resetTrackingState({required bool preserveActive}) {
    _lastEndExitSegmentId = null;
    _lastEndExitRemainingDistance = null;
    if (preserveActive && _active != null) {
      _active!
        ..consecutiveMisses = 0
        ..extendKeepAlive(_reloadKeepAliveDuration);
      _pendingRestore = _ActiveSegmentSnapshot(
        segmentId: _active!.geometry.id,
        forceKeepUntilEnd: _active!.forceKeepUntilEnd,
        enteredAt: _active!.enteredAt,
        keepAliveUntil: _active!.keepAliveUntil,
        segmentLengthMeters: _active!.geometry.lengthMeters,
        segmentSpeedLimitKph: _active!.geometry.speedLimitKph,
      );
      if (kDebugMode) {
        debugPrint(
          '[SEG] suspending segment ${_active!.geometry.id} for reload',
        );
      }
    } else {
      _pendingRestore = null;
      _active = null;
      _lastExitedGeometry = null;
      _lastEndExitSegmentId = null;
      _lastEndExitRemainingDistance = null;
    }

    _isReady = false;
    _latestDebugData = const SegmentTrackerDebugData.empty();
  }

  _SegmentTransition _updateActiveSegment(
    List<SegmentMatch> matches, {
    double? headingDegrees,
  }) {
    if (_active == null) {
      if (_maybeRestoreActive(matches)) {
        return const _SegmentTransition();
      }
      final entry = _chooseEntryMatch(
        matches,
        headingDegrees: headingDegrees,
      );
      if (entry != null) {
        _startSegment(entry);
        return const _SegmentTransition(started: true);
      }
      return const _SegmentTransition();
    }

    final active = _active!;
    final DateTime now = DateTime.now();
    SegmentMatch? current;
    for (final match in matches) {
      if (match.geometry.id == active.geometry.id) {
        current = match;
        break;
      }
    }

    if (current == null) {
      if (active.hasKeepAlive(now)) {
        return const _SegmentTransition();
      }

      active.consecutiveMisses++;
      if (active.consecutiveMisses >= _maxCandidateMisses) {
        _clearActiveSegment(reason: 'no candidates');
        return const _SegmentTransition(ended: true);
      }
      return const _SegmentTransition();
    }

    active.lastMatch = current;
    active.path = current.path;
    active.forceKeepUntilEnd = active.forceKeepUntilEnd || !current.isDetailed;
    active.clearKeepAlive();

    if (current.endHit) {
      _clearActiveSegment(reason: 'end geofence', exitAtEnd: true);
      return const _SegmentTransition(ended: true);
    }

    final double looseExitDistance =
        onPathToleranceMeters * _looseExitMultiplier;
    final bool distanceOk = active.forceKeepUntilEnd
        ? current.distanceMeters <= looseExitDistance
        : current.withinTolerance;
    if (distanceOk) {
      active.consecutiveMisses = 0;
      return const _SegmentTransition();
    }

    active.consecutiveMisses++;
    final int threshold = active.forceKeepUntilEnd
        ? _looseMissThreshold
        : _strictMissThreshold;
    if (active.consecutiveMisses >= threshold) {
      _clearActiveSegment(reason: 'lost track');
      return const _SegmentTransition(ended: true);
    }

    return const _SegmentTransition();
  }

  SegmentMatch? _chooseEntryMatch(
    List<SegmentMatch> matches, {
    double? headingDegrees,
  }) {
    if (matches.isEmpty) return null;

    final startCandidates =
        matches.where((m) => m.startHit).toList()
          ..sort(
            (a, b) => a.startDistanceMeters.compareTo(b.startDistanceMeters),
          );

    startCandidates.removeWhere(_shouldDeferEndReentry);

    final double? normalizedHeading =
        headingDegrees != null && headingDegrees.isFinite
            ? _normalizeHeading(headingDegrees)
            : null;

    if (normalizedHeading != null) {
      startCandidates.removeWhere((candidate) {
        final double? segmentHeading = _segmentHeadingAtStart(candidate.path);
        if (segmentHeading == null) {
          return false;
        }

        final double delta =
            _headingDeltaDegrees(normalizedHeading, segmentHeading);
        return delta > _entryHeadingHalfFovDegrees;
      });
    }

    return startCandidates.isNotEmpty ? startCandidates.first : null;
  }

  void _startSegment(SegmentMatch entry) {
    final active = _ActiveSegmentState(
      geometry: entry.geometry,
      path: entry.path,
      forceKeepUntilEnd: !entry.isDetailed,
      enteredAt: DateTime.now(),
    )..lastMatch = entry;

    _active = active;
    _pendingRestore = null;
    _lastEndExitSegmentId = null;
    _lastEndExitRemainingDistance = null;
    active.clearKeepAlive();

    if (kDebugMode) {
      debugPrint(
        '[SEG] entered segment ${entry.geometry.id} '
        '(detailed=${entry.isDetailed})',
      );
    }
  }

  void _clearActiveSegment({required String reason, bool exitAtEnd = false}) {
    if (kDebugMode && _active != null) {
      debugPrint('[SEG] exit segment ${_active!.geometry.id} ($reason)');
    }
    if (_active != null) {
      _lastExitedGeometry = _active!.geometry;
      _active!.clearKeepAlive();
      if (exitAtEnd) {
        _lastEndExitSegmentId = _active!.geometry.id;
        _lastEndExitRemainingDistance =
            _active!.lastMatch?.remainingDistanceMeters;
      } else {
        _lastEndExitSegmentId = null;
        _lastEndExitRemainingDistance = null;
      }
    }
    _active = null;
    _pendingRestore = null;
  }

  bool _maybeRestoreActive(List<SegmentMatch> matches) {
    final snapshot = _pendingRestore;
    if (snapshot == null) {
      return false;
    }

    for (final match in matches) {
      if (match.geometry.id != snapshot.segmentId) {
        continue;
      }

      final double looseExitDistance =
          onPathToleranceMeters * _looseExitMultiplier;
      final bool distanceOk =
          match.withinTolerance || match.distanceMeters <= looseExitDistance;
      if (!distanceOk) {
        continue;
      }

      _active = _ActiveSegmentState(
        geometry: match.geometry,
        path: match.path,
        forceKeepUntilEnd: snapshot.forceKeepUntilEnd || !match.isDetailed,
        enteredAt: snapshot.enteredAt,
      )..lastMatch = match;

      _active!.restoreKeepAlive(snapshot.keepAliveUntil);

      _pendingRestore = null;
      _lastEndExitSegmentId = null;
      _lastEndExitRemainingDistance = null;

      if (kDebugMode) {
        debugPrint('[SEG] restored segment ${match.geometry.id}');
      }
      return true;
    }

    return false;
  }

  bool _shouldDeferEndReentry(SegmentMatch match) {
    final String? lastEndId = _lastEndExitSegmentId;
    if (lastEndId == null || match.geometry.id != lastEndId) {
      return false;
    }

    if (match.endHit) {
      return true;
    }

    final double exitRemaining =
        _lastEndExitRemainingDistance?.isFinite == true
            ? _lastEndExitRemainingDistance!
            : 0.0;
    final double remaining = match.remainingDistanceMeters;
    if (!remaining.isFinite) {
      return false;
    }

    final double segmentLength = match.geometry.lengthMeters ??
        _distanceToPathEnd(match.path, 0, 0.0);
    if (!segmentLength.isFinite || segmentLength <= 0) {
      return remaining <= exitRemaining + _endReentryAllowanceMeters;
    }

    final double exitProgress = segmentLength - exitRemaining;
    final double currentProgress = segmentLength - remaining;
    return currentProgress >=
        exitProgress - _endReentryAllowanceMeters;
  }
}

class _ActiveSegmentSnapshot {
  const _ActiveSegmentSnapshot({
    required this.segmentId,
    required this.forceKeepUntilEnd,
    required this.enteredAt,
    this.keepAliveUntil,
    this.segmentLengthMeters,
    this.segmentSpeedLimitKph,
  });

  final String segmentId;
  final bool forceKeepUntilEnd;
  final DateTime enteredAt;
  final DateTime? keepAliveUntil;
  final double? segmentLengthMeters;
  final double? segmentSpeedLimitKph;
}

