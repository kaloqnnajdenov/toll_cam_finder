import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

class PermissionService {
  Future<bool> ensureLocationPermission() async {
    return ensureForegroundPermission();
  }

  Future<bool> ensureForegroundPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return _hasForegroundGrant(permission);
  }

  Future<bool> ensureBackgroundPermission() async {
    // Background alerts rely on the same foreground grant; we no longer
    // require the iOS "Always" level to keep working while the screen is off.
    return ensureForegroundPermission();
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!_hasForegroundGrant(permission)) {
      return false;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return true;
  }

  Future<bool> hasBackgroundPermission() async {
    return hasLocationPermission();
  }

  bool _hasForegroundGrant(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
