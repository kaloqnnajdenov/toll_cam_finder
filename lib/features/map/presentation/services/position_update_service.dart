import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/map/domain/utils/speed_smoother.dart';
import 'package:toll_cam_finder/features/map/services/speed_service.dart';

class PositionUpdateResult {
  const PositionUpdateResult({
    required this.position,
    required this.timestamp,
    required this.speedKmh,
    required this.headingDegrees,
  });

  final LatLng position;
  final DateTime timestamp;
  final double speedKmh;
  final double? headingDegrees;
}

/// Handles speed/heading resolution for raw [Position] samples so the
/// page stays focused on UI concerns.
class PositionUpdateService {
  PositionUpdateService({
    Distance? distanceCalculator,
    SpeedService? speedService,
    SpeedSmoother? speedSmoother,
  })  : _distanceCalculator = distanceCalculator ?? const Distance(),
        _speedService = speedService ?? const SpeedService(),
        _speedSmoother = speedSmoother ?? SpeedSmoother();

  final Distance _distanceCalculator;
  final SpeedService _speedService;
  final SpeedSmoother _speedSmoother;

  LatLng? _lastPosition;
  DateTime? _lastTimestamp;

  PositionUpdateResult handleInitialPosition(Position position) {
    reset();
    final DateTime sampleTime = position.timestamp ?? DateTime.now();
    final LatLng next = LatLng(position.latitude, position.longitude);

    final double speedKmh = _speedSmoother.next(
      _speedService.normalizeSpeed(_deviceSpeed(position)),
    );
    final double? heading = 0;

    _lastPosition = next;
    _lastTimestamp = sampleTime;

    return PositionUpdateResult(
      position: next,
      timestamp: sampleTime,
      speedKmh: speedKmh,
      headingDegrees: heading,
    );
  }

  PositionUpdateResult handlePosition(Position position) {
    if (_lastPosition == null || _lastTimestamp == null) {
      return handleInitialPosition(position);
    }

    final DateTime sampleTime = position.timestamp ?? DateTime.now();
    final LatLng previous = _lastPosition!;
    final LatLng next = LatLng(position.latitude, position.longitude);

    final double speedMps = _resolveSpeedMps(
      position: position,
      previous: previous,
      next: next,
      sampleTime: sampleTime,
    );
    final double speedKmh = _speedSmoother.next(
      _speedService.normalizeSpeed(speedMps),
    );
    final double? heading = _resolveHeadingDegrees(
      deviceHeading: position.heading,
      previous: previous,
      next: next,
    );

    _lastPosition = next;
    _lastTimestamp = sampleTime;

    return PositionUpdateResult(
      position: next,
      timestamp: sampleTime,
      speedKmh: speedKmh,
      headingDegrees: heading,
    );
  }

  void reset() {
    _lastPosition = null;
    _lastTimestamp = null;
    _speedSmoother.reset();
  }

  void resetSmoothing() {
    _speedSmoother.reset();
  }

  double _resolveSpeedMps({
    required Position position,
    required LatLng previous,
    required LatLng next,
    required DateTime sampleTime,
  }) {
    final double rawSpeed = position.speed;
    final double? deviceSpeed =
        rawSpeed.isFinite && rawSpeed >= 0 ? rawSpeed : null;

    double? derivedSpeed;
    if (_lastTimestamp != null) {
      final double dtSeconds =
          sampleTime.difference(_lastTimestamp!).inMilliseconds / 1000.0;
      if (dtSeconds > 0) {
        final double distanceMeters =
            _distanceCalculator.as(LengthUnit.Meter, previous, next);
        if (distanceMeters.isFinite && distanceMeters >= 0) {
          derivedSpeed = distanceMeters / dtSeconds;
        }
      }
    }

    if (deviceSpeed != null && deviceSpeed > 0) {
      return deviceSpeed;
    }
    if (derivedSpeed != null && derivedSpeed.isFinite) {
      return derivedSpeed;
    }
    return 0.0;
  }

  double? _resolveHeadingDegrees({
    required double? deviceHeading,
    required LatLng previous,
    required LatLng next,
  }) {
    if (deviceHeading != null &&
        deviceHeading.isFinite &&
        deviceHeading >= 0) {
      return deviceHeading % 360;
    }

    final double travelDistance =
        _distanceCalculator.as(LengthUnit.Meter, previous, next);
    if (!travelDistance.isFinite || travelDistance < 0.5) {
      return null;
    }

    final double bearing = _distanceCalculator.bearing(previous, next);
    if (!bearing.isFinite) {
      return null;
    }

    final double normalized = bearing % 360;
    return normalized.isNegative ? normalized + 360 : normalized;
  }

  double _deviceSpeed(Position position) {
    final double rawSpeed = position.speed;
    return rawSpeed.isFinite && rawSpeed >= 0 ? rawSpeed : 0.0;
  }
}
