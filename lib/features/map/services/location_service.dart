import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Stream aiming for ~1 Hz updates (best-effort on iOS).
  Stream<Position> getPositionStream() {
    LocationSettings settings;

    if (Platform.isAndroid) {
      settings =  AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,                    // don't gate by meters
        intervalDuration: Duration(milliseconds: 300), // request 1s interval
        // Uncomment if you use the FusedLocationProvider fallback:
        // forceLocationManager: false,
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      settings =  AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // request all updates
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        // allowBackgroundLocationUpdates: true, // if you’ve enabled background modes
      );
    } else {
      // Fallback for other platforms
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
