import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapControllerFacade {
  void move(MapController controller, LatLng target, double zoom) {
    controller.move(target, zoom);
  }
}
