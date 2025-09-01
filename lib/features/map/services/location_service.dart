import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'speed_estimator.dart';

class LocationService {
  final _latFilter = LocationFilter();
  final _lngFilter = LocationFilter();
  final _speedEstimator = SpeedEstimator();

  Future<Position> getCurrentPosition() async {
    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final smoothedLat = _latFilter.filter(p.latitude);
    final smoothedLng = _lngFilter.filter(p.longitude);
    final smoothed = _copyWithLatLng(p, smoothedLat, smoothedLng);
    return _speedEstimator.fuse(smoothed);
  }

  /// Stream aiming for ~1 Hz updates (best-effort on iOS).
  Stream<Position> getPositionStream() {
    LocationSettings settings;

    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: Duration(milliseconds: AppConstants.gpsSampleIntervalMs),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings).map((p) {
      final smoothedLat = _latFilter.filter(p.latitude);
      final smoothedLng = _lngFilter.filter(p.longitude);
      final smoothed = _copyWithLatLng(p, smoothedLat, smoothedLng);
      return _speedEstimator.fuse(smoothed);
    });
  }

  Position _copyWithLatLng(Position p, double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      accuracy: p.accuracy,
      altitude: p.altitude,
      heading: p.heading,
      speed: p.speed,
      speedAccuracy: p.speedAccuracy,
      timestamp: p.timestamp ?? DateTime.now(),
      // Remove if your geolocator version doesn't have these:
      isMocked: p.isMocked, altitudeAccuracy: p.accuracy, headingAccuracy: p.accuracy,
      // headingAccuracy: p.headingAccuracy,
      // altitudeAccuracy: p.altitudeAccuracy,
      // floor: p.floor,
    );
  }
}

class LocationFilter {
  // Simplified Kalman filter parameters
  double _errorEstimate = 1.0;
  double _lastEstimate = 0.0;
  double _kalmanGain = 0.0;
  final double _errorMeasure = 0.1;
  final double _errorProcess = 0.01;
  bool _initialized = false;

  // Convenience: filter a single measurement (what we use in the service).
  double filter(double currentMeasurement) {
    if (!_initialized) {
      _initialized = true;
      _lastEstimate = currentMeasurement; // avoid huge first-step bias
      return currentMeasurement;
    }

    // Prediction
    final prediction = _lastEstimate;
    _errorEstimate = _errorEstimate + _errorProcess;

    // Update
    _kalmanGain = _errorEstimate / (_errorEstimate + _errorMeasure);
    final currentEstimate =
        prediction + _kalmanGain * (currentMeasurement - prediction);
    _errorEstimate = (1.0 - _kalmanGain) * _errorEstimate;

    _lastEstimate = currentEstimate;
    return currentEstimate;
  }

  // Keeps your original list-based API (now uses the single-step helper).
  List<double> filterCoordinates(List<double> rawValues) {
    final filteredValues = <double>[];
    for (final v in rawValues) {
      filteredValues.add(filter(v));
    }
    return filteredValues;
  }

  void reset() {
    _errorEstimate = 1.0;
    _lastEstimate = 0.0;
    _kalmanGain = 0.0;
    _initialized = false;
  }
}
