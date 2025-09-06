import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/core/constants.dart';

class MapControllerFacade {
void onResetView(double animatedLatLng, LatLng? userLatLng, LatLng center, bool followUser, double currentZoom, MapController mapController) {
    LatLng target;
    if (userLatLng != null) {
      target = userLatLng;
    } else {
      target = center;
    }

    followUser = true;

    double zoom = currentZoom;
    if (currentZoom < AppConstants.zoomWhenFocused) {
      zoom = AppConstants.zoomWhenFocused;
    }

    mapController.move(target, zoom);
  }
}
