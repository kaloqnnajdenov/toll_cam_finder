import 'package:geolocator/geolocator.dart';

class PermissionService {
  Future<bool> ensureLocationPermission() async {
    return ensureForegroundPermission();
  }

  Future<bool> ensureForegroundPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return false;
    }
    if (perm == LocationPermission.unableToDetermine) {
      perm = await Geolocator.requestPermission();
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<bool> ensureBackgroundPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever ||
        perm == LocationPermission.unableToDetermine) {
      perm = await Geolocator.requestPermission();
    } else if (perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always) {
      return false;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return true;
  }

  Future<bool> hasLocationPermission() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever ||
        perm == LocationPermission.unableToDetermine) {
      return false;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<bool> hasBackgroundPermission() async {
    final perm = await Geolocator.checkPermission();
    if (perm != LocationPermission.always) {
      return false;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return true;
  }
}
