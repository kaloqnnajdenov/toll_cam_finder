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
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
      ..addListener(onTick);
  }

  late final AnimationController _controller;
  late final Animation<double> _curve;

  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  DateTime? _lastFixAt;

  /// Current interpolated location.
  LatLng? get position {
    if (_latTween == null || _lngTween == null) return null;
    final t = _curve.value;
    return LatLng(_latTween!.transform(t), _lngTween!.transform(t));
  }

  /// Starts a smooth animation between [from] and [to].
  void animate({required LatLng from, required LatLng to}) {
    final now = DateTime.now();
    final intervalMs = _lastFixAt != null
        ? now.difference(_lastFixAt!).inMilliseconds
        : null;
    final distanceMeters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );

    if (_shouldTeleport(distanceMeters, intervalMs)) {
      _latTween = Tween<double>(begin: to.latitude, end: to.latitude);
      _lngTween = Tween<double>(begin: to.longitude, end: to.longitude);
      _lastFixAt = now;
      _controller
        ..stop()
        ..value = 1.0;
      return;
    }

    _latTween = Tween<double>(begin: from.latitude, end: to.latitude);
    _lngTween = Tween<double>(begin: from.longitude, end: to.longitude);

    int ms = 500; //TODO: remove hardcoded value
    if (intervalMs != null) {
      ms = (intervalMs * AppConstants.fillRatio).toInt();
      if (ms < AppConstants.minMs) ms = AppConstants.minMs;
      if (ms > AppConstants.maxMs) ms = AppConstants.maxMs;
    }
    _lastFixAt = now;

    _controller
      ..duration = Duration(milliseconds: ms)
      ..stop()
      ..reset()
      ..forward();
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

  void dispose() {
    _controller.dispose();
  }
}
