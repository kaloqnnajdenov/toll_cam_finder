import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

class PermissionService {
  Future<bool> ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.whileInUse && Platform.isAndroid) {
      final upgraded = await Geolocator.requestPermission();
      if (upgraded != LocationPermission.denied &&
          upgraded != LocationPermission.deniedForever) {
        perm = upgraded;
      }
    }

    if (perm == LocationPermission.deniedForever) {
      return false;
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }
}
