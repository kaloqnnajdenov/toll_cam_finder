import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/controller/map_controller_impl.dart' as fm_impl;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapHeadingController extends ChangeNotifier {
  MapHeadingController({required MapController mapController})
      : _mapController = mapController;

  static const double speedDeadbandKmh = 1.0;

  final MapController _mapController;

  bool _mapReady = false;
  bool _followHeading = false;
  double _mapBearingDeg = 0.0;

  double? _smoothedHeadingDeg;
  double? _lastAcceptedHeadingDeg;
  double? _compassHeadingDeg;
  double? _frozenHeadingDeg;
  double _lastSpeedMps = 0.0;

  bool _isFrozen = false;
  DateTime? _stationarySince;

  static const double _minCourseSpeedMps = 2.0;
  static const double _rawHeadingFullTrustSpeedMps = 8.0;
  static const double _freezeEnterSpeedMps = 1.8;
  static const double _freezeExitSpeedMps = 2.3;
  static const Duration _stationaryTimeout = Duration(seconds: 3);

  static const double _bearingAccuracyReliableDeg = 25.0;
  static const double _bearingAccuracyRejectDeg = 60.0;

  static const double _emaAlpha = 0.25;
  static const double _maxHeadingJumpDeg = 100.0;
  static const double _rotationSnapEpsilonDeg = 0.1;

  static const double _minTrackDistanceMeters = 4.0;
  static const double _courseDeviationClampDeg = 80.0;

  static const double _maxAngularVelocityDegPerSec = 150.0;
  static const double _minAnimationDurationSeconds = 0.12;
  static const double _maxAnimationDurationSeconds = 0.75;

  static const double _freezeCompassBlend = 0.05;

  static const double _lookAheadMinMeters = 6.0;
  static const double _lookAheadMaxMeters = 28.0;
  static const double _lookAheadMaxSpeedMps = 22.0;

  static const double _earthRadiusMeters = 6378137.0;
  static const double _cameraBearingOffsetDeg = 0.0;

  bool get followHeading => _followHeading;
  double get mapRotationDeg => _mapBearingDeg;

  void onMapReady() {
    _mapReady = true;
    if (_mapBearingDeg.abs() > _rotationSnapEpsilonDeg) {
      _applyCameraRotation(_mapBearingDeg, animate: false);
    }
  }

  void enableFollowHeading() {
    if (_followHeading) return;
    _followHeading = true;
    notifyListeners();
  }

  bool disableFollowHeading({bool resetRotation = false}) {
    if (!_followHeading) return false;
    _followHeading = false;
    if (resetRotation) {
      _applyCameraRotation(0.0, animate: true);
    } else {
      notifyListeners();
    }
    return true;
  }

  bool updateRotationFromMap(double rotation) {
    final double normalized = _normalizeAngle(rotation);
    final double delta = _shortestDelta(_mapBearingDeg, normalized).abs();
    if (delta <= _rotationSnapEpsilonDeg) {
      return false;
    }
    _mapBearingDeg = normalized;
    notifyListeners();
    return true;
  }

  void forceRotateToLastHeading() {
    final double? heading = _currentHeadingForCamera;
    if (heading == null) return;
    _applyCameraRotation(_headingToMapRotation(heading), animate: true);
  }

  void updateCompassHeading(double? compassHeading) {
    final double? normalized = _normalizeOptionalAngle(compassHeading);
    _compassHeadingDeg = normalized;
    if (!_isFrozen || normalized == null) {
      return;
    }

    final double? heading = _computeFrozenHeading();
    if (heading == null) {
      return;
    }

    if (_followHeading) {
      _applyCameraRotation(_headingToMapRotation(heading), animate: true);
    } else {
      notifyListeners();
    }
  }

  void updateHeading({
    required LatLng? previous,
    required LatLng next,
    required double rawHeading,
    required double speedKmh,
    double? headingAccuracyDeg,
    double? compassHeading,
  }) {
    final double sanitizedSpeedKmh = speedKmh.isFinite ? speedKmh : 0.0;
    final double speedMps = sanitizedSpeedKmh / 3.6;
    _lastSpeedMps = speedMps;

    if (compassHeading != null) {
      _compassHeadingDeg = _normalizeAngle(compassHeading);
    }

    final DateTime now = DateTime.now();
    _updateFreezeState(speedMps, now);

    final double? candidate = _selectCourseHeading(
      previous: previous,
      next: next,
      rawHeading: rawHeading,
      speedMps: speedMps,
      headingAccuracyDeg: headingAccuracyDeg,
    );

    if (candidate == null) {
      if (_isFrozen && _followHeading) {
        final double? frozen = _computeFrozenHeading();
        if (frozen != null) {
          _applyCameraRotation(_headingToMapRotation(frozen), animate: true);
        }
      }
      return;
    }

    final double normalizedCandidate = _normalizeAngle(candidate);

    if (_shouldRejectSample(normalizedCandidate, headingAccuracyDeg)) {
      return;
    }

    _lastAcceptedHeadingDeg = normalizedCandidate;

    if (_isFrozen) {
      _smoothedHeadingDeg = _applyEma(normalizedCandidate);
      final double? frozen = _computeFrozenHeading();
      if (frozen != null && _followHeading) {
        _applyCameraRotation(_headingToMapRotation(frozen), animate: true);
      }
      return;
    }

    final double smoothed = _applyEma(normalizedCandidate);
    _smoothedHeadingDeg = smoothed;
    _frozenHeadingDeg = smoothed;

    if (_followHeading) {
      _applyCameraRotation(_headingToMapRotation(smoothed), animate: true);
    }
  }

  LatLng lookAheadTarget({required LatLng userPosition}) {
    if (!_followHeading) {
      return userPosition;
    }

    final double? heading = _currentHeadingForCamera;
    final double speed = _lastSpeedMps;
    if (heading == null || speed < 0.5) {
      return userPosition;
    }

    final double distance = _lookAheadDistanceForSpeed(speed);
    if (distance <= 0) {
      return userPosition;
    }

    return _offsetLatLng(userPosition, heading, distance);
  }

  double? get _currentHeadingForCamera {
    if (_isFrozen) {
      return _computeFrozenHeading();
    }
    return _smoothedHeadingDeg ?? _lastAcceptedHeadingDeg ?? _compassHeadingDeg;
  }

  double? _selectCourseHeading({
    required LatLng? previous,
    required LatLng next,
    required double rawHeading,
    required double speedMps,
    double? headingAccuracyDeg,
  }) {
    double? sensorHeading = _sanitizeHeading(rawHeading);
    final bool accuracyReliable =
        headingAccuracyDeg != null && headingAccuracyDeg <= _bearingAccuracyReliableDeg;
    if (headingAccuracyDeg != null && headingAccuracyDeg >= _bearingAccuracyRejectDeg) {
      sensorHeading = null;
    }

    if (sensorHeading != null &&
        !(speedMps >= _minCourseSpeedMps || accuracyReliable)) {
      sensorHeading = null;
    }

    double? pathHeading;
    if (previous != null) {
      final double distance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        next.latitude,
        next.longitude,
      );
      if (distance >= _minTrackDistanceMeters) {
        pathHeading = _bearingBetween(previous, next);
      }
    }

    if (sensorHeading != null && pathHeading != null) {
      final double deviation =
          _shortestDelta(pathHeading, sensorHeading).abs();
      if (!accuracyReliable && deviation > _courseDeviationClampDeg) {
        return pathHeading;
      }
      final double weight = _rawHeadingWeight(speedMps, accuracyReliable);
      return _blendAngles(pathHeading, sensorHeading, weight);
    }

    return sensorHeading ?? pathHeading;
  }

  void _updateFreezeState(double speedMps, DateTime timestamp) {
    if (speedMps >= _freezeExitSpeedMps) {
      _stationarySince = null;
      if (_isFrozen) {
        _isFrozen = false;
        _frozenHeadingDeg = _smoothedHeadingDeg ?? _lastAcceptedHeadingDeg;
      }
      return;
    }

    if (speedMps <= _freezeEnterSpeedMps) {
      _stationarySince ??= timestamp;
    } else if (!_isFrozen) {
      _stationarySince = null;
    }

    if (_stationarySince != null &&
        timestamp.difference(_stationarySince!) >= _stationaryTimeout) {
      if (!_isFrozen) {
        _isFrozen = true;
        _frozenHeadingDeg ??=
            _smoothedHeadingDeg ?? _lastAcceptedHeadingDeg ?? _compassHeadingDeg ?? _mapBearingDeg;
      }
    }
  }

  double? _computeFrozenHeading() {
    double? heading =
        _frozenHeadingDeg ?? _smoothedHeadingDeg ?? _lastAcceptedHeadingDeg ?? _compassHeadingDeg;
    if (heading == null) {
      return null;
    }
    final double? compass = _compassHeadingDeg;
    if (compass != null) {
      final double delta = _shortestDelta(heading, compass);
      heading = _normalizeAngle(heading + delta * _freezeCompassBlend);
    }
    _frozenHeadingDeg = heading;
    return heading;
  }

  bool _shouldRejectSample(double candidate, double? headingAccuracyDeg) {
    if (headingAccuracyDeg != null && headingAccuracyDeg > _bearingAccuracyRejectDeg) {
      return true;
    }
    final double? reference = _smoothedHeadingDeg ?? _lastAcceptedHeadingDeg;
    if (reference == null) {
      return false;
    }
    final double delta = _shortestDelta(reference, candidate).abs();
    if (delta <= _maxHeadingJumpDeg) {
      return false;
    }
    final bool accuracyReliable =
        headingAccuracyDeg != null && headingAccuracyDeg <= _bearingAccuracyReliableDeg;
    return !accuracyReliable;
  }

  double _applyEma(double headingDeg) {
    final double normalized = _normalizeAngle(headingDeg);
    final double? previous = _smoothedHeadingDeg;
    if (previous == null) {
      return normalized;
    }
    final double delta = _shortestDelta(previous, normalized);
    if (delta.abs() <= _rotationSnapEpsilonDeg) {
      return previous;
    }
    final double blended = previous + delta * _emaAlpha;
    return _normalizeAngle(blended);
  }

  double _rawHeadingWeight(double speedMps, bool accuracyReliable) {
    final double range =
        (_rawHeadingFullTrustSpeedMps - _minCourseSpeedMps).clamp(0.1, double.infinity);
    final double normalized = ((speedMps - _minCourseSpeedMps) / range).clamp(0.0, 1.0);
    return accuracyReliable ? math.max(normalized, 0.75) : normalized;
  }

  void _applyCameraRotation(double bearingDeg, {required bool animate}) {
    final double normalized = _normalizeAngle(bearingDeg);
    final double delta = _shortestDelta(_mapBearingDeg, normalized);

    if (!animate || !_mapReady) {
      _mapBearingDeg = normalized;
      if (_mapReady) {
        _mapController.rotate(normalized);
      }
      notifyListeners();
      return;
    }

    if (delta.abs() <= _rotationSnapEpsilonDeg) {
      return;
    }

    final Duration duration = _rotationDuration(delta.abs());
    _mapBearingDeg = normalized;

    if (_mapController is fm_impl.MapControllerImpl) {
      final fm_impl.MapControllerImpl impl =
          _mapController as fm_impl.MapControllerImpl;
      impl.rotateAnimatedRaw(
        normalized,
        offset: Offset.zero,
        duration: duration,
        curve: Curves.easeOut,
        hasGesture: false,
        source: MapEventSource.mapController,
      );
    } else {
      _mapController.rotate(normalized);
    }

    notifyListeners();
  }

  Duration _rotationDuration(double deltaDegrees) {
    final double clamped = deltaDegrees.clamp(0.0, 180.0);
    final double rawSeconds =
        clamped / _maxAngularVelocityDegPerSec;
    final double boundedSeconds = rawSeconds.isFinite
        ? rawSeconds.clamp(_minAnimationDurationSeconds, _maxAnimationDurationSeconds)
        : _maxAnimationDurationSeconds;
    final int millis = math.max((boundedSeconds * 1000).round(), 1);
    return Duration(milliseconds: millis);
  }

  double? _sanitizeHeading(double heading) {
    if (!heading.isFinite || heading < 0) {
      return null;
    }
    return _normalizeAngle(heading);
  }

  double _normalizeAngle(double value) {
    final double mod = value % 360;
    return mod < 0 ? mod + 360 : mod;
  }

  double? _normalizeOptionalAngle(double? value) =>
      value == null ? null : _normalizeAngle(value);

  double _shortestDelta(double from, double to) {
    final double diff = (to - from) % 360;
    return diff > 180 ? diff - 360 : diff;
  }

  double _blendAngles(double fromDeg, double toDeg, double weight) {
    final double clamped = weight.clamp(0.0, 1.0);
    final double delta = _shortestDelta(fromDeg, toDeg);
    return _normalizeAngle(fromDeg + delta * clamped);
  }

  double _headingToMapRotation(double headingDeg) =>
      _normalizeAngle(headingDeg + _cameraBearingOffsetDeg);

  double _bearingBetween(LatLng from, LatLng to) {
    final double fromLat = _degToRad(from.latitude);
    final double fromLng = _degToRad(from.longitude);
    final double toLat = _degToRad(to.latitude);
    final double toLng = _degToRad(to.longitude);
    final double dLng = toLng - fromLng;

    final double y = math.sin(dLng) * math.cos(toLat);
    final double x = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(dLng);
    final double bearing = math.atan2(y, x);
    return _normalizeAngle(_radToDeg(bearing));
  }

  double _lookAheadDistanceForSpeed(double speedMps) {
    if (speedMps <= 0.5) {
      return 0.0;
    }
    final double clamped = speedMps.clamp(0.0, _lookAheadMaxSpeedMps);
    final double t = clamped / _lookAheadMaxSpeedMps;
    return _lookAheadMinMeters +
        (_lookAheadMaxMeters - _lookAheadMinMeters) * t;
  }

  LatLng _offsetLatLng(LatLng origin, double headingDeg, double distanceMeters) {
    final double headingRad = _degToRad(headingDeg);
    final double distanceRatio = distanceMeters / _earthRadiusMeters;

    final double latRad = _degToRad(origin.latitude);
    final double lonRad = _degToRad(origin.longitude);

    final double newLatRad = math.asin(math.sin(latRad) * math.cos(distanceRatio) +
        math.cos(latRad) * math.sin(distanceRatio) * math.cos(headingRad));

    final double newLonRad = lonRad +
        math.atan2(
          math.sin(headingRad) * math.sin(distanceRatio) * math.cos(latRad),
          math.cos(distanceRatio) - math.sin(latRad) * math.sin(newLatRad),
        );

    return LatLng(
      _radToDeg(newLatRad),
      _normalizeLongitude(_radToDeg(newLonRad)),
    );
  }

  double _normalizeLongitude(double lon) {
    final double mod = (lon + 540) % 360 - 180;
    return mod == -180 ? 180 : mod;
  }

  double _degToRad(double value) => value * math.pi / 180;

  double _radToDeg(double value) => value * 180 / math.pi;
}
