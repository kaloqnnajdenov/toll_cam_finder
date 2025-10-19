library segment_tracker;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/segments/domain/index/segment_index_service.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/osrm_path_fetcher.dart';

part 'segment_tracker_models.dart';
part 'segment_match.dart';
part 'active_segment_state.dart';
part 'segment_transition.dart';
part 'debug_extensions.dart';
part 'geometry_extensions.dart';
part 'path_fetch_extensions.dart';

class SegmentTracker {
  SegmentTracker({
    required SegmentIndexService indexService,
    http.Client? httpClient,
    this.candidateRadiusMeters = AppConstants.candidateRadiusMeters,
    this.onPathToleranceMeters = AppConstants.segmentOnPathToleranceMeters,
    this.startGeofenceRadiusMeters =
        AppConstants.segmentStartGeofenceRadiusMeters,
    this.endGeofenceRadiusMeters = AppConstants.segmentEndGeofenceRadiusMeters,
  }) : _index = indexService,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  static const int _strictMissThreshold = 3;
  static const int _looseMissThreshold = 6;
  static const int _maxCandidateMisses = 4;
  static const double _looseExitMultiplier = 2.5;

  final SegmentIndexService _index;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  final double candidateRadiusMeters;
  final double onPathToleranceMeters;
  final double startGeofenceRadiusMeters;
  final double endGeofenceRadiusMeters;
  bool _isReady = false;
  SegmentTrackerDebugData _latestDebugData =
      const SegmentTrackerDebugData.empty();
  _ActiveSegmentState? _active;

  final Map<String, List<GeoPoint>> _pathOverrides = <String, List<GeoPoint>>{};
  final Set<String> _fetchFailures = <String>{};
  final Set<String> _fetching = <String>{};
  final Set<String> _ignoredSegmentIds = <String>{};
  SegmentGeometry? _lastExitedGeometry;

  bool get isReady => _isReady;
  SegmentTrackerDebugData get debugData => _latestDebugData;
  String? get activeSegmentId => _active?.geometry.id;

  Future<bool> initialise({required String assetPath}) async {
    _resetTrackingState();
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
    _resetTrackingState();
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
  }) {
    final SegmentGeometry? exitedGeometry = _lastExitedGeometry;
    _lastExitedGeometry = null;

    if (!_isReady) {
      return SegmentTrackerEvent(
        startedSegment: false,
        endedSegment: false,
        activeSegmentId: _active?.geometry.id,
        activeSegmentSpeedLimitKph: _active?.geometry.speedLimitKph,
        activeSegmentLengthMeters: _active?.geometry.lengthMeters,
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
      final path = _effectivePathFor(geom);
      final nearest = _nearestPointOnPath(userPoint, path);
      final double startDist = _distanceBetween(userPoint, path.first);
      final double endDist = _distanceBetween(userPoint, path.last);
      final double remainingDist = _distanceToPathEnd(
        path,
        nearest.segmentIndex,
        nearest.segmentFraction,
      );
      final bool detailed = _isPathDetailed(geom, path);

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
    
    final transition = _updateActiveSegment(matches);

    return SegmentTrackerEvent(
      startedSegment: transition.started,
      endedSegment: transition.ended,
      activeSegmentId: _active?.geometry.id,
      activeSegmentSpeedLimitKph: _active?.geometry.speedLimitKph,
      activeSegmentLengthMeters: _active?.geometry.lengthMeters,
      completedSegmentLengthMeters: exitedGeometry?.lengthMeters,
      debugData: _latestDebugData,
    );
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  void _resetTrackingState() {
    if (_active != null) {
      _clearActiveSegment(reason: 'reset');
    }
    _isReady = false;
    _pathOverrides.clear();
    _fetchFailures.clear();
    _fetching.clear();
    _lastExitedGeometry = null;
    _latestDebugData = const SegmentTrackerDebugData.empty();
  }

  _SegmentTransition _updateActiveSegment(List<SegmentMatch> matches) {
    if (_active == null) {
      final entry = _chooseEntryMatch(matches);
      if (entry != null) {
        _startSegment(entry);
        return const _SegmentTransition(started: true);
      }
      return const _SegmentTransition();
    }

    final active = _active!;
    SegmentMatch? current;
    for (final match in matches) {
      if (match.geometry.id == active.geometry.id) {
        current = match;
        break;
      }
    }

    if (current == null) {
      active.consecutiveMisses++;
      if (active.consecutiveMisses >= _maxCandidateMisses) {
        _clearActiveSegment(reason: 'no candidates');
        return const _SegmentTransition(ended: true);
      }
      return const _SegmentTransition();
    }

    active.lastMatch = current;

    if (current.endHit) {
      _clearActiveSegment(reason: 'end geofence');
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

  SegmentMatch? _chooseEntryMatch(List<SegmentMatch> matches) {
    if (matches.isEmpty) return null;

    final startCandidates =
        matches.where((m) => m.startHit).toList()
          ..sort(
            (a, b) => a.startDistanceMeters.compareTo(b.startDistanceMeters),
          );

    return startCandidates.isNotEmpty ? startCandidates.first : null;
  }

  void _startSegment(SegmentMatch entry) {
    final bool fetchFailed = _fetchFailures.contains(entry.geometry.id);
    final active = _ActiveSegmentState(
      geometry: entry.geometry,
      path: entry.path,
      forceKeepUntilEnd: !entry.isDetailed,
      enteredAt: DateTime.now(),
    )..lastMatch = entry;

    _active = active;

    if (!entry.isDetailed && !fetchFailed) {
      _ensureEnhancedPath(entry.geometry);
    }

    if (!entry.isDetailed && fetchFailed) {
      active.forceKeepUntilEnd = true;
    }

    if (kDebugMode) {
      debugPrint(
        '[SEG] entered segment ${entry.geometry.id} '
        '(detailed=${entry.isDetailed}, fetchFailed=$fetchFailed)',
      );
    }
  }

  void _clearActiveSegment({required String reason}) {
    if (kDebugMode && _active != null) {
      debugPrint('[SEG] exit segment ${_active!.geometry.id} ($reason)');
    }
    if (_active != null) {
      _lastExitedGeometry = _active!.geometry;
    }
    _active = null;
  }
}
