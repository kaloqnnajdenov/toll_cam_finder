import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'package:toll_cam_finder/core/constants.dart';

/// Lightweight speed estimator that blends device Doppler readings with
/// distance-over-time samples. Coordinates are still smoothed with a Kalman
/// filter, but the velocity logic is intentionally simple to minimize CPU work.
class SpeedEstimator {
  final _LocationFilter _latFilter = _LocationFilter();
  final _LocationFilter _lngFilter = _LocationFilter();

  double? _lastLat;
  double? _lastLng;
  DateTime? _lastTimestamp;
  DateTime? _lastWallClock;
  double? _lastAccuracy;

  double? _smoothedSpeed;
  double? _smoothedVariance;

  /// Fuse a raw geolocator [Position] and return one whose coordinates are
  /// smoothed and whose speed is an exponentially smoothed blend of the raw
  /// Doppler measurement and the derived speed between fixes.
  Position fuse(Position raw) {
    final wallNow = DateTime.now();
    final timestamp = raw.timestamp ?? wallNow;

    final latSm = _latFilter.filter(raw.latitude);
    final lngSm = _lngFilter.filter(raw.longitude);

    final devSpeed = _validSpeed(raw.speed);
    final devVar = _speedVarianceFromAccuracy(raw.speedAccuracy);

    final derived = _deriveSpeed(
      timestamp: timestamp,
      latitude: latSm,
      longitude: lngSm,
      accuracy: raw.accuracy,
    );

    final fused = _fuseMeasurements(devSpeed, devVar, derived);
    final measurementSpeed = fused?.speed ??
        devSpeed ??
        derived?.speed ??
        _smoothedSpeed ??
        0.0;
    final measurementVar = _boundedVar(
      fused?.variance ??
          devVar ??
          derived?.variance ??
          AppConstants.speedEstimatorMinVariance,
    );

    final dtSeconds = _deltaSeconds(_lastWallClock, wallNow);
    final alpha = _emaAlpha(dtSeconds);

    if (_smoothedSpeed == null) {
      _smoothedSpeed = measurementSpeed;
    } else {
      _smoothedSpeed =
          _smoothedSpeed! + alpha * (measurementSpeed - _smoothedSpeed!);
    }

    if (_smoothedVariance == null) {
      _smoothedVariance = measurementVar;
    } else {
      _smoothedVariance =
          _smoothedVariance! + alpha * (measurementVar - _smoothedVariance!);
    }

    if (_smoothedSpeed != null &&
        _smoothedSpeed!.abs() < AppConstants.speedEstimatorSmallSpeedMps &&
        (derived?.isStationary ?? false) &&
        (devSpeed == null ||
            devSpeed.abs() < AppConstants.speedEstimatorSmallSpeedMps)) {
      _smoothedSpeed = 0.0;
    }

    final speedValue = (_smoothedSpeed ?? 0.0)
        .clamp(0.0, AppConstants.speedEstimatorMaxSpeed);
    final varianceValue = _boundedVar(
      _smoothedVariance ?? AppConstants.speedEstimatorMinVariance,
    );

    final result = Position(
      latitude: latSm,
      longitude: lngSm,
      accuracy: raw.accuracy,
      altitude: raw.altitude,
      heading: raw.heading,
      speed: speedValue,
      speedAccuracy: math.sqrt(varianceValue),
      timestamp: raw.timestamp,
      isMocked: raw.isMocked,
      altitudeAccuracy: raw.altitudeAccuracy,
      headingAccuracy: raw.headingAccuracy,
    );

    _lastLat = latSm;
    _lastLng = lngSm;
    _lastTimestamp = timestamp;
    _lastWallClock = wallNow;
    _lastAccuracy = raw.accuracy;

    return result;
  }

  double _deltaSeconds(DateTime? previous, DateTime current) {
    if (previous == null) {
      return AppConstants.speedEstimatorMinDtSeconds;
    }
    final dt =
        current.difference(previous).inMilliseconds.toDouble() / 1000.0;
    if (!dt.isFinite || dt <= 0) {
      return AppConstants.speedEstimatorMinDtSeconds;
    }
    return dt.clamp(
      AppConstants.speedEstimatorMinDtSeconds,
      AppConstants.speedEstimatorMaxDtSeconds,
    );
  }

  double _emaAlpha(double dtSeconds) {
    if (!dtSeconds.isFinite || dtSeconds <= 0) {
      return 1.0;
    }
    final halfLife = AppConstants.speedEstimatorEmaHalfLifeSeconds;
    if (halfLife <= 0) {
      return 1.0;
    }
    final ratio = dtSeconds / halfLife;
    final value = 1 - math.pow(0.5, ratio);
    if (value.isNaN) {
      return 1.0;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }

  double? _validSpeed(double value) {
    if (!value.isFinite || value < 0) {
      return null;
    }
    return value.clamp(0.0, AppConstants.speedEstimatorMaxSpeed);
  }

  double? _speedVarianceFromAccuracy(double? speedAccuracy) {
    if (speedAccuracy == null || !speedAccuracy.isFinite) {
      return null;
    }
    if (speedAccuracy <= 0) {
      return AppConstants.speedEstimatorMinVariance;
    }
    return _boundedVar(speedAccuracy * speedAccuracy);
  }

  _SpeedSample? _deriveSpeed({
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required double? accuracy,
  }) {
    if (_lastLat == null ||
        _lastLng == null ||
        _lastTimestamp == null ||
        _lastAccuracy == null) {
      return null;
    }

    final dt = timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0;
    if (!dt.isFinite || dt < AppConstants.speedEstimatorMinDtSeconds) {
      return null;
    }

    final distance = Geolocator.distanceBetween(
      _lastLat!,
      _lastLng!,
      latitude,
      longitude,
    );
    final speed = (distance / dt).clamp(0.0, AppConstants.speedEstimatorMaxSpeed);

    final acc1 = _finiteOr(
      _lastAccuracy,
      AppConstants.speedEstimatorAccuracyFallbackMeters,
    );
    final acc2 =
        _finiteOr(accuracy, AppConstants.speedEstimatorAccuracyFallbackMeters);

    double? variance;
    if (acc1 <= AppConstants.speedEstimatorHorizAccBadMeters &&
        acc2 <= AppConstants.speedEstimatorHorizAccBadMeters) {
      final sigmaMeters = math.max(acc1, acc2);
      final sigmaSpeed =
          sigmaMeters / math.max(dt, AppConstants.speedEstimatorMinDtSeconds);
      variance = _boundedVar(sigmaSpeed * sigmaSpeed);
    }

    final isStationary = distance <= AppConstants.speedEstimatorStationaryDispMeters;

    return _SpeedSample(
      speed: speed,
      variance: variance,
      isStationary: isStationary,
    );
  }

  _SpeedSample? _fuseMeasurements(
    double? devSpeed,
    double? devVar,
    _SpeedSample? derived,
  ) {
    final hasDev = devSpeed != null;
    final hasDerived = derived != null;

    if (!hasDev && !hasDerived) {
      return null;
    }

    if (hasDev && devVar != null && hasDerived && derived!.variance != null) {
      final wDev = 1.0 / devVar;
      final wDerived = 1.0 / derived.variance!;
      final total = wDev + wDerived;
      final speed =
          (wDev * devSpeed! + wDerived * derived.speed) / total;
      final variance = _boundedVar(1.0 / total);
      final stationary = derived.isStationary &&
          devSpeed.abs() < AppConstants.speedEstimatorSmallSpeedMps;
      return _SpeedSample(
        speed: speed,
        variance: variance,
        isStationary: stationary,
      );
    }

    if (hasDev) {
      final variance = devVar ?? AppConstants.speedEstimatorMinVariance;
      return _SpeedSample(
        speed: devSpeed!,
        variance: _boundedVar(variance),
        isStationary:
            devSpeed.abs() < AppConstants.speedEstimatorSmallSpeedMps,
      );
    }

    if (hasDerived) {
      return _SpeedSample(
        speed: derived!.speed,
        variance: _boundedVar(
          derived.variance ?? AppConstants.speedEstimatorMinVariance,
        ),
        isStationary: derived.isStationary,
      );
    }

    return null;
  }

  static double _finiteOr(double? v, double fallback) {
    if (v == null || !v.isFinite) {
      return fallback;
    }
    return v;
  }

  static double _boundedVar(double v) {
    if (!v.isFinite) {
      return AppConstants.speedEstimatorMinVariance;
    }
    return v.clamp(
      AppConstants.speedEstimatorMinVariance,
      AppConstants.speedEstimatorMaxVariance,
    );
  }
}

/// Simple scalar Kalman filter used for smoothing latitude and longitude.
class _LocationFilter {
  double _errorEstimate = AppConstants.locationFilterInitialErrorEstimate;
  double _lastEstimate = AppConstants.locationFilterInitialEstimate;
  double _kalmanGain = AppConstants.locationFilterInitialKalmanGain;
  final double _errorMeasure = AppConstants.locationFilterMeasurementError;
  final double _errorProcess = AppConstants.locationFilterProcessError;
  bool _initialized = false;

  double filter(double currentMeasurement) {
    if (!_initialized) {
      _initialized = true;
      _lastEstimate = currentMeasurement;
      return currentMeasurement;
    }

    final prediction = _lastEstimate;
    _errorEstimate = _errorEstimate + _errorProcess;

    _kalmanGain = _errorEstimate / (_errorEstimate + _errorMeasure);
    final currentEstimate =
        prediction + _kalmanGain * (currentMeasurement - prediction);
    _errorEstimate = (1.0 - _kalmanGain) * _errorEstimate;

    _lastEstimate = currentEstimate;
    return currentEstimate;
  }

  void reset() {
    _errorEstimate = AppConstants.locationFilterInitialErrorEstimate;
    _lastEstimate = AppConstants.locationFilterInitialEstimate;
    _kalmanGain = AppConstants.locationFilterInitialKalmanGain;
    _initialized = false;
  }
}

class _SpeedSample {
  const _SpeedSample({
    required this.speed,
    this.variance,
    this.isStationary = false,
  });

  final double speed;
  final double? variance;
  final bool isStationary;
}
