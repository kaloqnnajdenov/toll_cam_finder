import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';

/// Handles interpolation of the blue user-dot position between GPS fixes.
class BlueDotAnimator {
  BlueDotAnimator({
    required TickerProvider vsync,
    required VoidCallback onTick,
  }) {
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    )..addListener(onTick);
  }

  late final AnimationController _controller;

  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  LatLng? _lastRawFix;
  LatLng? _smoothedTarget;
  DateTime? _lastFixAt;

  static const double _smoothingHalfLifeMs = 1600.0;
  static const double _catchUpDistanceMeters = 18.0;

  /// Current interpolated location.
  LatLng? get position {
    if (_latTween == null || _lngTween == null) return null;
    final t = _controller.value;
    return LatLng(_latTween!.transform(t), _lngTween!.transform(t));
  }

  /// Starts a smooth animation between [from] and [to].
  void animate({required LatLng from, required LatLng to}) {
    final now = DateTime.now();
    final intervalMs = _lastFixAt != null
        ? now.difference(_lastFixAt!).inMilliseconds
        : null;
    final double distanceFromLastRaw = (_lastRawFix == null)
        ? 0.0
        : Geolocator.distanceBetween(
            _lastRawFix!.latitude,
            _lastRawFix!.longitude,
            to.latitude,
            to.longitude,
          );

    _lastFixAt = now;
    _lastRawFix = to;

    if (_shouldTeleport(distanceFromLastRaw, intervalMs)) {
      _smoothedTarget = to;
      _latTween = Tween<double>(begin: to.latitude, end: to.latitude);
      _lngTween = Tween<double>(begin: to.longitude, end: to.longitude);
      _controller
        ..stop()
        ..value = 1.0;
      return;
    }

    final smoothedTarget = _smoothTarget(
      raw: to,
      currentDisplayed: from,
      intervalMs: intervalMs,
      distanceFromLastRaw: distanceFromLastRaw,
    );

    _smoothedTarget = smoothedTarget;

    _latTween = Tween<double>(begin: from.latitude, end: smoothedTarget.latitude);
    _lngTween = Tween<double>(begin: from.longitude, end: smoothedTarget.longitude);

    int ms = 500; //TODO: remove hardcoded value
    if (intervalMs != null) {
      ms = (intervalMs * AppConstants.fillRatio).toInt();
      if (ms < AppConstants.minMs) ms = AppConstants.minMs;
      if (ms > AppConstants.maxMs) ms = AppConstants.maxMs;
    }
    _controller
      ..stop()
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0.0);
  }

  bool _shouldTeleport(double distanceMeters, int? intervalMs) {
    if (distanceMeters > AppConstants.blueDotTeleportDistanceMeters) {
      return true;
    }
    if (intervalMs != null && intervalMs > 0) {
      final seconds = intervalMs / 1000.0;
      final speed = distanceMeters / seconds;
      if (speed > AppConstants.blueDotTeleportSpeedMps) {
        return true;
      }
    }
    return false;
  }

  LatLng _smoothTarget({
    required LatLng raw,
    required LatLng currentDisplayed,
    required int? intervalMs,
    required double distanceFromLastRaw,
  }) {
    final previous = _smoothedTarget ?? currentDisplayed;
    var alpha = _timeBasedAlpha(intervalMs);

    final distanceToSmoothed = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      raw.latitude,
      raw.longitude,
    );
    final catchUpMeters = math.max(distanceFromLastRaw, distanceToSmoothed);
    final catchUp = (catchUpMeters / _catchUpDistanceMeters).clamp(0.0, 1.0);
    alpha = alpha + (1 - alpha) * catchUp;
    alpha = alpha.clamp(0.0, 1.0);

    final lat = previous.latitude + alpha * (raw.latitude - previous.latitude);
    final lng = previous.longitude + alpha * (raw.longitude - previous.longitude);
    return LatLng(lat, lng);
  }

  double _timeBasedAlpha(int? intervalMs) {
    if (intervalMs == null || intervalMs <= 0) {
      return 1.0;
    }
    final ratio = intervalMs / _smoothingHalfLifeMs;
    final powTerm = math.pow(0.5, ratio).toDouble();
    final alpha = 1 - powTerm;
    return alpha.clamp(0.0, 1.0);
  }

  void dispose() {
    _controller.dispose();
  }
}
