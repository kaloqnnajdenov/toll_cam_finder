import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';

class SegmentTrackerEvent {
  const SegmentTrackerEvent({
    required this.startedSegment,
    required this.endedSegment,
    required this.activeSegmentId,
    required this.debugData,
  });

  final bool startedSegment;
  final bool endedSegment;
  final String? activeSegmentId;
  final SegmentTrackerDebugData debugData;
}

class SegmentTrackerDebugData {
  const SegmentTrackerDebugData({
    required this.isReady,
    required this.querySquare,
    required this.boundingCandidates,
    required this.candidatePaths,
    required this.startGeofenceRadius,
    required this.endGeofenceRadius,
  });

  const SegmentTrackerDebugData.empty()
      : isReady = false,
        querySquare = const [],
        boundingCandidates = const [],
        candidatePaths = const [],
        startGeofenceRadius = 0,
        endGeofenceRadius = 0;

  final bool isReady;
  final List<LatLng> querySquare;
  final List<SegmentGeometry> boundingCandidates;
  final List<SegmentDebugPath> candidatePaths;
  final double startGeofenceRadius;
  final double endGeofenceRadius;

  int get candidateCount => boundingCandidates.length;
}

class SegmentDebugPath {
  const SegmentDebugPath({
    required this.id,
    required this.polyline,
    required this.distanceMeters,
    required this.isWithinTolerance,
    required this.passesDirection,
    required this.startHit,
    required this.endHit,
    required this.isActive,
    required this.isDetailed,
    this.nearestPoint,
    this.headingDiffDeg,
  });

  final String id;
  final List<LatLng> polyline;
  final double distanceMeters;
  final bool isWithinTolerance;
  final bool passesDirection;
  final bool startHit;
  final bool endHit;
  final bool isActive;
  final bool isDetailed;
  final LatLng? nearestPoint;
  final double? headingDiffDeg;
}

class SegmentTracker {
  SegmentTracker({
    required SegmentIndexService indexService,
    http.Client? httpClient,
    this.candidateRadiusMeters = AppConstants.candidateRadiusMeters,
    this.onPathToleranceMeters = AppConstants.segmentOnPathToleranceMeters,
    this.startGeofenceRadiusMeters = AppConstants.segmentStartGeofenceRadiusMeters,
    this.endGeofenceRadiusMeters = AppConstants.segmentEndGeofenceRadiusMeters,
    this.directionToleranceDegrees = AppConstants.segmentDirectionToleranceDegrees,
    this.directionMinSpeedKmh = AppConstants.segmentDirectionMinSpeedKmh,
  })  : _index = indexService,
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
  final double directionToleranceDegrees;
  final double directionMinSpeedKmh;

  bool _isReady = false;
  SegmentTrackerDebugData _latestDebugData = const SegmentTrackerDebugData.empty();
  _ActiveSegmentState? _active;

  final Map<String, List<GeoPoint>> _pathOverrides = <String, List<GeoPoint>>{};
  final Set<String> _fetchFailures = <String>{};
  final Set<String> _fetching = <String>{};

  bool get isReady => _isReady;
  SegmentTrackerDebugData get debugData => _latestDebugData;
  String? get activeSegmentId => _active?.geometry.id;

  Future<bool> initialise({required String assetPath}) async {
    if (!_index.isReady) {
      await _index.tryLoadFromDefaultAsset(assetPath: assetPath);
    }
    _isReady = _index.isReady;
    if (!_isReady) {
      _latestDebugData = const SegmentTrackerDebugData.empty();
    }
    return _isReady;
  }

  SegmentTrackerEvent handleLocationUpdate({
    required LatLng current,
    LatLng? previous,
    double? rawHeading,
    double? speedKmh,
  }) {
    if (!_isReady) {
      return SegmentTrackerEvent(
        startedSegment: false,
        endedSegment: false,
        activeSegmentId: _active?.geometry.id,
        debugData: _latestDebugData,
      );
    }

    final GeoPoint userPoint = GeoPoint(current.latitude, current.longitude);
    final double? heading = _resolveHeading(
      current,
      previous,
      rawHeading,
      speedKmh,
    );

    final List<SegmentGeometry> candidates = _index.candidatesNearLatLng(
      current,
      radiusMeters: candidateRadiusMeters,
    );

    final matches = <SegmentMatch>[];
    for (final geom in candidates) {
      final path = _effectivePathFor(geom);
      final nearest = _nearestPointOnPath(userPoint, path);
      final double startDist = _distanceBetween(userPoint, path.first);
      final double endDist = _distanceBetween(userPoint, path.last);
      final bool detailed = _isPathDetailed(geom, path);

      double? headingDiff;
      bool passesDirection = true;
      if (heading != null && nearest.bearingDeg != null && detailed) {
        headingDiff = _angularDifferenceDegrees(heading, nearest.bearingDeg!);
        passesDirection = headingDiff <= directionToleranceDegrees;
      }

      matches.add(
        SegmentMatch(
          geometry: geom,
          path: path,
          distanceMeters: nearest.distanceMeters,
          nearestPoint: nearest.point,
          startDistanceMeters: startDist,
          endDistanceMeters: endDist,
          headingDiffDeg: headingDiff,
          withinTolerance: nearest.distanceMeters <= onPathToleranceMeters,
          startHit: startDist <= startGeofenceRadiusMeters,
          endHit: endDist <= endGeofenceRadiusMeters,
          passesDirection: passesDirection,
          isDetailed: detailed,
        ),
      );
    }

    matches.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    _updateDebugData(current, candidates, matches);

    final transition = _updateActiveSegment(matches);

    return SegmentTrackerEvent(
      startedSegment: transition.started,
      endedSegment: transition.ended,
      activeSegmentId: _active?.geometry.id,
      debugData: _latestDebugData,
    );
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

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

    final double looseExitDistance = onPathToleranceMeters * _looseExitMultiplier;
    final bool distanceOk = active.forceKeepUntilEnd
        ? current.distanceMeters <= looseExitDistance
        : current.withinTolerance;
    final bool directionOk = active.enforceDirection ? current.passesDirection : true;

    if (distanceOk && directionOk) {
      active.consecutiveMisses = 0;
      return const _SegmentTransition();
    }

    active.consecutiveMisses++;
    final int threshold = active.forceKeepUntilEnd ? _looseMissThreshold : _strictMissThreshold;
    if (active.consecutiveMisses >= threshold) {
      _clearActiveSegment(reason: 'lost track');
      return const _SegmentTransition(ended: true);
    }

    return const _SegmentTransition();
  }

  SegmentMatch? _chooseEntryMatch(List<SegmentMatch> matches) {
    if (matches.isEmpty) return null;

    final startCandidates = matches
        .where((m) => m.startHit && _entryDirectionAllowed(m))
        .toList()
      ..sort((a, b) => a.startDistanceMeters.compareTo(b.startDistanceMeters));

    if (startCandidates.isNotEmpty) {
      return startCandidates.first;
    }

    final onPath = matches
        .where((m) => m.withinTolerance && _entryDirectionAllowed(m))
        .toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return onPath.isNotEmpty ? onPath.first : null;
  }

  bool _entryDirectionAllowed(SegmentMatch match) {
    if (!match.isDetailed) {
      return true;
    }
    return match.passesDirection;
  }

  void _startSegment(SegmentMatch entry) {
    final bool fetchFailed = _fetchFailures.contains(entry.geometry.id);
    final active = _ActiveSegmentState(
      geometry: entry.geometry,
      path: entry.path,
      forceKeepUntilEnd: !entry.isDetailed,
      enforceDirection: entry.isDetailed,
      enteredAt: DateTime.now(),
    )
      ..lastMatch = entry;

    _active = active;

    if (!entry.isDetailed && !fetchFailed) {
      _ensureEnhancedPath(entry.geometry);
    }

    if (!entry.isDetailed && fetchFailed) {
      active.forceKeepUntilEnd = true;
      active.enforceDirection = false;
    }

    if (kDebugMode) {
      debugPrint('[SEG] entered segment ${entry.geometry.id} '
          '(detailed=${entry.isDetailed}, fetchFailed=$fetchFailed)');
    }
  }

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

  void _clearActiveSegment({required String reason}) {
    if (kDebugMode && _active != null) {
      debugPrint('[SEG] exit segment ${_active!.geometry.id} ($reason)');
    }
    _active = null;
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

  List<LatLng> _pathToLatLngList(List<GeoPoint> path) {
    return path.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);
  }

  List<LatLng> _computeQuerySquare(LatLng center, double radiusMeters) {
    const double mPerDegLat = 111320.0;
    final double latRad = center.latitude * math.pi / 180.0;
    final double mPerDegLon = (mPerDegLat * math.cos(latRad)).clamp(1e-9, double.infinity);
    final double dLat = radiusMeters / mPerDegLat;
    final double dLon = radiusMeters / mPerDegLon;

    final double minLat = center.latitude - dLat;
    final double maxLat = center.latitude + dLat;
    final double minLon = center.longitude - dLon;
    final double maxLon = center.longitude + dLon;

    return <LatLng>[
      LatLng(minLat, minLon),
      LatLng(minLat, maxLon),
      LatLng(maxLat, maxLon),
      LatLng(maxLat, minLon),
      LatLng(minLat, minLon),
    ];
  }

  double? _resolveHeading(
    LatLng current,
    LatLng? previous,
    double? rawHeading,
    double? speedKmh,
  ) {
    double? heading = _normalizeHeading(rawHeading);
    final bool speedOk = speedKmh == null || speedKmh >= directionMinSpeedKmh;
    if (heading != null && speedOk) {
      return heading;
    }

    if (previous != null) {
      final GeoPoint prevPoint = GeoPoint(previous.latitude, previous.longitude);
      final GeoPoint currPoint = GeoPoint(current.latitude, current.longitude);
      if (_distanceBetween(prevPoint, currPoint) >= 3) {
        return _bearingBetween(previous, current);
      }
    }

    return heading;
  }

  double? _normalizeHeading(double? heading) {
    if (heading == null || !heading.isFinite) return null;
    double value = heading % 360.0;
    if (value < 0) value += 360.0;
    return value;
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180.0;
    final double lat2 = to.latitude * math.pi / 180.0;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180.0;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x) * 180.0 / math.pi;
    if (bearing < 0) bearing += 360.0;
    return bearing;
  }

  double _angularDifferenceDegrees(double a, double b) {
    double diff = (a - b).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    return diff;
  }

  double _distanceBetween(GeoPoint a, GeoPoint b) {
    const double earthRadius = 6371000.0; // meters
    final double lat1 = a.lat * math.pi / 180.0;
    final double lat2 = b.lat * math.pi / 180.0;
    final double dLat = lat2 - lat1;
    final double dLon = (b.lon - a.lon) * math.pi / 180.0;

    final double sinLat = math.sin(dLat / 2);
    final double sinLon = math.sin(dLon / 2);
    final double h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadius * c;
  }

  _NearestPointResult _nearestPointOnPath(GeoPoint point, List<GeoPoint> path) {
    const double mPerDegLat = 111320.0;
    final double latRad = point.lat * math.pi / 180.0;
    final double mPerDegLon = (mPerDegLat * math.cos(latRad)).clamp(1e-9, double.infinity);
    final double refLat = point.lat;
    final double refLon = point.lon;

    double bestDistSq = double.infinity;
    double bestX = 0;
    double bestY = 0;
    double? bestBearingDeg;

    final offsets = <math.Point<double>>[];
    for (final p in path) {
      final double x = (p.lon - refLon) * mPerDegLon;
      final double y = (p.lat - refLat) * mPerDegLat;
      offsets.add(math.Point<double>(x, y));
    }

    for (var i = 0; i < offsets.length - 1; i++) {
      final math.Point<double> a = offsets[i];
      final math.Point<double> b = offsets[i + 1];
      final double dx = b.x - a.x;
      final double dy = b.y - a.y;
      final double lenSq = dx * dx + dy * dy;
      if (lenSq <= 1e-6) continue;

      var t = (-(a.x * dx + a.y * dy)) / lenSq;
      if (t < 0) t = 0;
      if (t > 1) t = 1;

      final double projX = a.x + dx * t;
      final double projY = a.y + dy * t;
      final double distSq = projX * projX + projY * projY;
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        bestX = projX;
        bestY = projY;
        final double bearingRad = math.atan2(dx, dy);
        double bearingDeg = bearingRad * 180.0 / math.pi;
        if (bearingDeg < 0) bearingDeg += 360.0;
        bestBearingDeg = bearingDeg;
      }
    }

    if (bestDistSq.isInfinite && offsets.isNotEmpty) {
      final math.Point<double> first = offsets.first;
      bestX = first.x;
      bestY = first.y;
      bestDistSq = bestX * bestX + bestY * bestY;
      if (offsets.length >= 2) {
        final math.Point<double> next = offsets[1];
        final double dx = next.x - first.x;
        final double dy = next.y - first.y;
        final double bearingRad = math.atan2(dx, dy);
        double bearingDeg = bearingRad * 180.0 / math.pi;
        if (bearingDeg < 0) bearingDeg += 360.0;
        bestBearingDeg = bearingDeg;
      }
    }

    final double nearestLat = refLat + (bestY / mPerDegLat);
    final double nearestLon = refLon + (bestX / mPerDegLon);
    final double distance = math.sqrt(bestDistSq.abs());

    return _NearestPointResult(
      distanceMeters: distance,
      point: GeoPoint(nearestLat, nearestLon),
      bearingDeg: bestBearingDeg,
    );
  }
}

class SegmentMatch {
  SegmentMatch({
    required this.geometry,
    required this.path,
    required this.distanceMeters,
    required this.nearestPoint,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.headingDiffDeg,
    required this.withinTolerance,
    required this.startHit,
    required this.endHit,
    required this.passesDirection,
    required this.isDetailed,
  });

  final SegmentGeometry geometry;
  final List<GeoPoint> path;
  final double distanceMeters;
  final GeoPoint nearestPoint;
  final double startDistanceMeters;
  final double endDistanceMeters;
  final double? headingDiffDeg;
  final bool withinTolerance;
  final bool startHit;
  final bool endHit;
  final bool passesDirection;
  final bool isDetailed;
}

class _ActiveSegmentState {
  _ActiveSegmentState({
    required this.geometry,
    required this.path,
    required this.forceKeepUntilEnd,
    required this.enforceDirection,
    required this.enteredAt,
  });

  final SegmentGeometry geometry;
  List<GeoPoint> path;
  bool forceKeepUntilEnd;
  bool enforceDirection;
  final DateTime enteredAt;
  int consecutiveMisses = 0;
  SegmentMatch? lastMatch;
}

class _NearestPointResult {
  const _NearestPointResult({
    required this.distanceMeters,
    required this.point,
    this.bearingDeg,
  });

  final double distanceMeters;
  final GeoPoint point;
  final double? bearingDeg;
}

class _SegmentTransition {
  const _SegmentTransition({this.started = false, this.ended = false});

  final bool started;
  final bool ended;
}