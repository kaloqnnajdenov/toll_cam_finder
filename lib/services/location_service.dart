// location_service.dart
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'speed_estimator.dart';

class LocationService {
  final _speedEstimator = SpeedEstimator();

  Future<Position> getCurrentPosition() async {
    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // Hand raw fix to the estimator; it will smooth coords and estimate speed.
    return _speedEstimator.fuse(p);
  }

  /// Stream aiming for ~1 Hz updates (best-effort on iOS).
  Stream<Position> getPositionStream() {
    LocationSettings settings;

    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.gpsDistanceFilterMeters,
        intervalDuration: Duration(milliseconds: AppConstants.gpsSampleIntervalMs),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.gpsDistanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.gpsDistanceFilterMeters,
      );
    }

    // No pre-smoothing here. Estimator owns all smoothing/logic.
    return Geolocator.getPositionStream(locationSettings: settings)
        .map(_speedEstimator.fuse);
  }
}
