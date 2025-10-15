// location_service.dart
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:toll_cam_finder/core/constants.dart';

class LocationService {

  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
    );
  }

  /// Stream aiming for ~1 Hz updates (best-effort on iOS).
  Stream<Position> getPositionStream({
    bool useForegroundNotification = false,
  }) {
    LocationSettings settings;

    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.gpsDistanceFilterMeters,
        intervalDuration: Duration(milliseconds: AppConstants.gpsSampleIntervalMs),
        foregroundNotificationConfig: useForegroundNotification
            ? const ForegroundNotificationConfig(
                notificationTitle: AppConstants.backgroundNotificationTitle,
                notificationText: AppConstants.backgroundNotificationText,
                notificationChannelName:
                    AppConstants.backgroundNotificationChannelName,
                notificationIcon: const AndroidResource(
                  name: AppConstants.backgroundNotificationIconName,
                  defType: AppConstants.backgroundNotificationIconType,
                ),
                enableWakeLock: true,
                setOngoing: true,
              )
            : null,
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
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
