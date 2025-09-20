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
  static const double _forwardCameraOffsetDeg =
      -90.0; // Keep the travel direction at the top of the device.

  final MapController _mapController;

  bool _mapReady = false;
  bool _followHeading = false;
  double _mapRotationDeg = 0.0;
  double? _lastHeadingDeg;

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
  }) {
    final heading = _resolveHeading(
      previous: previous,
      next: next,
      rawHeading: rawHeading,
      speedKmh: speedKmh,
    );

    if (heading == null) return;

    final normalized = _normalizeRotation(heading);
    final smoothed = _applyHeadingSmoothing(normalized);
    _lastHeadingDeg = smoothed;

    if (_followHeading) {
      _rotateMap(_headingToRotation(smoothed));
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
  }) {
    if (rawHeading.isFinite && rawHeading >= 0) {
      return rawHeading;
    }

    if (previous == null || speedKmh < speedDeadbandKmh) {
      return null;
    }

    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      next.latitude,
      next.longitude,
    );

    if (distance < _headingDistanceThresholdMeters) {
      return null;
    }

    return _bearingBetween(previous, next);
  }

  double _normalizeRotation(double rotationDeg) {
    final normalized = rotationDeg % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _rotationDelta(double fromDeg, double toDeg) {
    return ((toDeg - fromDeg + 540) % 360) - 180;
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
}