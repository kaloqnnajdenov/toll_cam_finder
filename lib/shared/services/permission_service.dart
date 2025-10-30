import 'package:geolocator/geolocator.dart';

class PermissionService {
  Future<bool> ensureLocationPermission() async {
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
    if (perm == LocationPermission.whileInUse) {
      final upgradedPermission = await Geolocator.requestPermission();
      if (upgradedPermission != LocationPermission.denied &&
          upgradedPermission != LocationPermission.deniedForever) {
        perm = upgradedPermission;
      }
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }
}
