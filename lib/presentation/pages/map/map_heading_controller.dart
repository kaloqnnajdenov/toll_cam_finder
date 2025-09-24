import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapHeadingController extends ChangeNotifier {
  MapHeadingController({required MapController mapController})
      : _mapController = mapController;

  static const double speedDeadbandKmh = 1.0;
  static const double _headingDistanceThresholdMeters = 5.0;
  static const double _rotationEpsilonDeg = 0.5;
  static const double _headingSmoothingFactor = 0.2; // Low-pass heading noise.
  static const double _headingBlendMinSpeedKmh = 2.0;
  static const double _headingBlendMaxSpeedKmh = 12.0;
  static const double _forwardCameraOffsetDeg =
      -90.0; // Keep the travel direction at the top of the device.

  final MapController _mapController;

  bool _mapReady = false;
  bool _followHeading = false;
  double _mapRotationDeg = 0.0;
  double? _lastHeadingDeg;
  double? _lastCompassHeadingDeg;
  double? _lastCourseHeadingDeg;

  bool get followHeading => _followHeading;
  double get mapRotationDeg => _mapRotationDeg;

  void onMapReady() {
    _mapReady = true;
    if (_mapRotationDeg != 0.0) {
      _mapController.rotate(_mapRotationDeg);
    }
  }

  void updateHeading({
    required LatLng? previous,
    required LatLng next,
    required double rawHeading,
    required double speedKmh,
    double? compassHeading,
  }) {
    final heading = _resolveHeading(
      previous: previous,
      next: next,
      rawHeading: rawHeading,
      speedKmh: speedKmh,
      compassHeading: compassHeading,
    );

    if (heading == null) return;

    final normalized = _normalizeRotation(heading);
    final smoothed = _applyHeadingSmoothing(normalized);
    _lastHeadingDeg = smoothed;

    if (_followHeading) {
      _rotateMap(_headingToRotation(smoothed));
    }
  }

  void updateCompassHeading(double? compassHeading) {
    final double? normalized = _normalizeOptionalHeading(compassHeading);
    if (normalized == null) {
      _lastCompassHeadingDeg = null;
      return;
    }

    _lastCompassHeadingDeg = normalized;

    final smoothed = _applyHeadingSmoothing(normalized);
    _lastHeadingDeg = smoothed;

    if (_followHeading) {
      _rotateMap(_headingToRotation(smoothed));
    } else {
      notifyListeners();
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
      _rotateMap(0, force: true);
    } else {
      notifyListeners();
    }
    return true;
  }

  bool updateRotationFromMap(double rotation) {
    final normalized = _normalizeRotation(rotation);
    final changed =
        _rotationDelta(_mapRotationDeg, normalized).abs() > _rotationEpsilonDeg;
    if (!changed) return false;

    _mapRotationDeg = normalized;
    notifyListeners();
    return true;
  }

  void forceRotateToLastHeading() {
    final lastHeading = _lastHeadingDeg;
    if (lastHeading == null) return;
    _rotateMap(_headingToRotation(lastHeading), force: true);
  }

  double? _resolveHeading({
    required LatLng? previous,
    required LatLng next,
    required double rawHeading,
    required double speedKmh,
    double? compassHeading,
  }) {
    final double speed = speedKmh.isFinite ? speedKmh : 0.0;

    final double? normalizedCompass = _normalizeOptionalHeading(compassHeading);
    if (normalizedCompass != null) {
      _lastCompassHeadingDeg = normalizedCompass;
    }

    double? courseHeading = _resolveCourseHeading(
      previous: previous,
      next: next,
      rawHeading: rawHeading,
      speedKmh: speed,
    );
    if (courseHeading != null) {
      _lastCourseHeadingDeg = courseHeading;
    } else {
      courseHeading = _lastCourseHeadingDeg;
    }

    final double? compassForFusion =
        normalizedCompass ?? _lastCompassHeadingDeg;

    double? fusedHeading = _fuseCompassAndCourse(
      compass: compassForFusion,
      course: courseHeading,
      speedKmh: speed,
    );

    fusedHeading ??= courseHeading ?? compassForFusion;

    if (fusedHeading == null) {
      return null;
    }

    return _normalizeRotation(fusedHeading);
  }

  double _normalizeRotation(double rotationDeg) {
    final normalized = rotationDeg % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double? _normalizeOptionalHeading(double? heading) {
    if (heading == null || !heading.isFinite) return null;
    return _normalizeRotation(heading);
  }

  double _rotationDelta(double fromDeg, double toDeg) {
    return ((toDeg - fromDeg + 540) % 360) - 180;
  }

  double? _resolveCourseHeading({
    required LatLng? previous,
    required LatLng next,
    required double rawHeading,
    required double speedKmh,
  }) {
    double? normalizedRaw;
    if (rawHeading.isFinite && rawHeading >= 0) {
      normalizedRaw = _normalizeRotation(rawHeading);
    }

    double? pathHeading;
    if (previous != null) {
      final distance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        next.latitude,
        next.longitude,
      );

      if (distance >= _headingDistanceThresholdMeters) {
        pathHeading = _bearingBetween(previous, next);
      }
    }

    if (pathHeading == null) {
      return normalizedRaw;
    }

    if (normalizedRaw == null) {
      return pathHeading;
    }

    final double weight = _courseBlendWeight(speedKmh);
    if (weight <= 0.0) {
      return pathHeading;
    }
    if (weight >= 1.0) {
      return normalizedRaw;
    }

    return _interpolateHeadings(pathHeading, normalizedRaw, weight);
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final double fromLat = _degToRad(from.latitude);
    final double fromLng = _degToRad(from.longitude);
    final double toLat = _degToRad(to.latitude);
    final double toLng = _degToRad(to.longitude);
    final double dLng = toLng - fromLng;

    final double y = math.sin(dLng) * math.cos(toLat);
    final double x = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(dLng);
    final double bearingRad = math.atan2(y, x);
    return _normalizeRotation(_radToDeg(bearingRad));
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  double _radToDeg(double rad) => rad * 180 / math.pi;

  double _headingToRotation(double headingDeg) {
    return _normalizeRotation(headingDeg + _forwardCameraOffsetDeg);
  }

  double _applyHeadingSmoothing(double headingDeg) {
    final previous = _lastHeadingDeg;
    if (previous == null) {
      return headingDeg;
    }

    final delta = _rotationDelta(previous, headingDeg);
    if (delta.abs() <= _rotationEpsilonDeg) {
      return headingDeg;
    }

    final smoothed = previous + delta * _headingSmoothingFactor;
    return _normalizeRotation(smoothed);
  }

  void _rotateMap(double targetDeg, {bool force = false}) {
    final normalizedTarget = _normalizeRotation(targetDeg);
    final delta = _rotationDelta(_mapRotationDeg, normalizedTarget).abs();
    if (!force && delta < _rotationEpsilonDeg) {
      return;
    }

    _mapRotationDeg = normalizedTarget;

    if (_mapReady) {
      _mapController.rotate(_mapRotationDeg);
    }

    notifyListeners();
  }

  double? _fuseCompassAndCourse({
    double? compass,
    double? course,
    required double speedKmh,
  }) {
    if (course == null) return compass;
    if (compass == null) return course;

    double weight = _courseBlendWeight(speedKmh);
    if (weight <= 0.0) return compass;
    if (weight >= 1.0) return course;

    final double delta = _rotationDelta(compass, course).abs();
    if (delta > 90.0) {
      final double severity = ((delta - 90.0).clamp(0.0, 90.0)) / 90.0;
      weight *= 1 - 0.5 * severity;
      if (weight <= 0.0) return compass;
    }

    if (weight >= 1.0) return course;

    return _interpolateHeadings(compass, course, weight);
  }

  double _courseBlendWeight(double speedKmh) {
    if (!speedKmh.isFinite) return 0.0;
    if (speedKmh <= _headingBlendMinSpeedKmh) return 0.0;
    if (speedKmh >= _headingBlendMaxSpeedKmh) return 1.0;
    final double range =
        _headingBlendMaxSpeedKmh - _headingBlendMinSpeedKmh;
    return (speedKmh - _headingBlendMinSpeedKmh) / range;
  }

  double _interpolateHeadings(double fromDeg, double toDeg, double t) {
    final double clamped = t.clamp(0.0, 1.0) as double;
    final double delta = _rotationDelta(fromDeg, toDeg);
    final double interpolated = fromDeg + delta * clamped;
    return _normalizeRotation(interpolated);
  }
}
