import 'package:flutter/animation.dart';
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
    _latTween = Tween<double>(begin: from.latitude, end: to.latitude);
    _lngTween = Tween<double>(begin: from.longitude, end: to.longitude);

    final now = DateTime.now();
    int ms = 500;
    if (_lastFixAt != null) {
      final intervalMs = now.difference(_lastFixAt!).inMilliseconds;
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

  void dispose() {
    _controller.dispose();
  }
}