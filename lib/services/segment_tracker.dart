import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/core/constants.dart';

import '../core/spatial/geo.dart';
import '../core/spatial/segment_geometry.dart';
import '../features/segemnt_index_service.dart';

class SegmentTracker {
  SegmentTracker({
    required SegmentIndexService indexService,
    this.candidateRadiusMeters = AppConstants.candidateRadiusMeters,
    this.distanceThresholdMeters = 40,
    this.startGeofenceRadiusMeters = 35,
    this.directionToleranceDeg = 60,
    this.minMovementForBearingMeters = 5,
    this.onSegmentEntered,
    this.onSegmentExited,
  }) : _indexService = indexService;

  final SegmentIndexService _indexService;
  final double candidateRadiusMeters;
  final double distanceThresholdMeters;
  final double startGeofenceRadiusMeters;
  final double directionToleranceDeg;
  final double minMovementForBearingMeters;
  final void Function(SegmentGeometry segment)? onSegmentEntered;
  final void Function(SegmentGeometry segment)? onSegmentExited;

  SegmentGeometry? _activeSegment;
  static const Distance _distance = Distance();

  void handleLocationUpdate({
    required LatLng current,
    LatLng? previous,
    double? headingDegrees,
  }) {
    if (!_indexService.isReady) {
      return;
    }

    final userPoint = GeoPoint(current.latitude, current.longitude);
    final GeoPoint? previousPoint =
        previous == null ? null : GeoPoint(previous.latitude, previous.longitude);
    final movementBearing = _resolveMovementBearing(
      previous: previousPoint,
      current: userPoint,
      headingDegrees: headingDegrees,
    );

    final candidates = _indexService.candidatesNearLatLng(
      current,
      radiusMeters: candidateRadiusMeters,
    );

    _SegmentMatch? bestMatch;
    for (final segment in candidates) {
      final match = _evaluateSegment(
        segment: segment,
        user: userPoint,
        movementBearing: movementBearing,
      );
      if (!match.isOnSegment) continue;
      if (bestMatch == null || match.distanceMeters < bestMatch.distanceMeters) {
        bestMatch = match;
      }
    }

    if (bestMatch != null) {
      final isNewSegment = _activeSegment?.id != bestMatch.segment.id;
      _activeSegment = bestMatch.segment;
      if (isNewSegment) {
        if (kDebugMode) {
          debugPrint(
            '[SegmentTracker] Entered segment ${bestMatch.segment.id} '
            '(distance=${bestMatch.distanceMeters.toStringAsFixed(1)}m'
            '${bestMatch.directionDeltaDeg != null ? ', directionΔ=${bestMatch.directionDeltaDeg!.toStringAsFixed(1)}°' : ''})',
          );
        }
        onSegmentEntered?.call(bestMatch.segment);
      }
      return;
    }

    if (_activeSegment != null) {
      final distanceToActive =
          _distanceToPolylineMeters(userPoint, _activeSegment!.path);
      final startDistance =
          _distanceBetweenMeters(userPoint, _activeSegment!.path.first);
      if (distanceToActive > distanceThresholdMeters * 1.5 &&
          startDistance > startGeofenceRadiusMeters * 1.5) {
        final exited = _activeSegment!;
        _activeSegment = null;
        if (kDebugMode) {
          debugPrint('[SegmentTracker] Exited segment ${exited.id}');
        }
        onSegmentExited?.call(exited);
      }
    }
  }

  _SegmentMatch _evaluateSegment({
    required SegmentGeometry segment,
    required GeoPoint user,
    double? movementBearing,
  }) {
    final distanceMeters = _distanceToPolylineMeters(user, segment.path);
    final distanceToStart = _distanceBetweenMeters(user, segment.path.first);
    final geofenceHit = distanceToStart <= startGeofenceRadiusMeters;

    final directionDelta = movementBearing == null
        ? null
        : _bearingDifferenceDeg(
            movementBearing,
            _segmentBearing(segment.path),
          );
    final directionOk = directionDelta == null || directionDelta <= directionToleranceDeg;
    final onPath = distanceMeters <= distanceThresholdMeters;

    final isOnSegment = (onPath && directionOk) || geofenceHit;

    return _SegmentMatch(
      segment: segment,
      distanceMeters: distanceMeters,
      directionDeltaDeg: directionDelta,
      isOnSegment: isOnSegment,
    );
  }

  double? _resolveMovementBearing({
    GeoPoint? previous,
    required GeoPoint current,
    double? headingDegrees,
  }) {
    if (previous != null) {
      final distanceMeters = _distanceBetweenMeters(previous, current);
      if (distanceMeters >= minMovementForBearingMeters) {
        return _initialBearing(previous, current);
      }
    }

    if (headingDegrees != null && headingDegrees.isFinite && headingDegrees >= 0) {
      return headingDegrees % 360;
    }

    return null;
  }

  double _segmentBearing(List<GeoPoint> path) {
    final start = path.first;
    GeoPoint end = path.last;
    for (var i = path.length - 1; i >= 0; i--) {
      final candidate = path[i];
      if (candidate.lat != start.lat || candidate.lon != start.lon) {
        end = candidate;
        break;
      }
    }
    return _initialBearing(start, end);
  }

  double _initialBearing(GeoPoint from, GeoPoint to) {
    final lat1 = _degToRad(from.lat);
    final lat2 = _degToRad(to.lat);
    final dLon = _degToRad(to.lon - from.lon);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x);
    return (_radToDeg(brng) + 360) % 360;
  }

  double _bearingDifferenceDeg(double a, double b) {
    final diff = (a - b + 540) % 360 - 180;
    return diff.abs();
  }

  double _distanceBetweenMeters(GeoPoint a, GeoPoint b) {
    return _distance(LatLng(a.lat, a.lon), LatLng(b.lat, b.lon));
  }

  double _distanceToPolylineMeters(GeoPoint origin, List<GeoPoint> path) {
    if (path.length < 2) return _distanceBetweenMeters(origin, path.first);
    var minDistance = double.infinity;
    const originPoint = _ProjectedPoint(0, 0);

    for (var i = 0; i < path.length - 1; i++) {
      final a = _projectToMeters(origin, path[i]);
      final b = _projectToMeters(origin, path[i + 1]);
      final distance = _distancePointToSegment(originPoint, a, b);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  _ProjectedPoint _projectToMeters(GeoPoint origin, GeoPoint point) {
    const mPerDegLat = 111320.0;
    final latRad = _degToRad(origin.lat);
    final mPerDegLon = (mPerDegLat * math.cos(latRad)).clamp(1e-9, double.infinity);
    final dx = (point.lon - origin.lon) * mPerDegLon;
    final dy = (point.lat - origin.lat) * mPerDegLat;
    return _ProjectedPoint(dx, dy);
  }

  double _distancePointToSegment(
    _ProjectedPoint p,
    _ProjectedPoint a,
    _ProjectedPoint b,
  ) {
    final abx = b.x - a.x;
    final aby = b.y - a.y;
    final apx = p.x - a.x;
    final apy = p.y - a.y;
    final abLen2 = abx * abx + aby * aby;

    var t = 0.0;
    if (abLen2 > 0) {
      t = ((apx * abx) + (apy * aby)) / abLen2;
      if (t < 0) {
        t = 0;
      } else if (t > 1) {
        t = 1;
      }
    }

    final closestX = a.x + abx * t;
    final closestY = a.y + aby * t;
    final dx = p.x - closestX;
    final dy = p.y - closestY;
    return math.sqrt(dx * dx + dy * dy);
  }

  double _degToRad(double deg) => deg * math.pi / 180;
  double _radToDeg(double rad) => rad * 180 / math.pi;
}

class _SegmentMatch {
  const _SegmentMatch({
    required this.segment,
    required this.distanceMeters,
    required this.directionDeltaDeg,
    required this.isOnSegment,
  });

  final SegmentGeometry segment;
  final double distanceMeters;
  final double? directionDeltaDeg;
  final bool isOnSegment;
}

class _ProjectedPoint {
  const _ProjectedPoint(this.x, this.y);

  final double x;
  final double y;
}