import 'package:latlong2/latlong.dart';

class AppConstants {
  // Bulgaria center
  static const LatLng initialCenter = LatLng(42.7339, 25.4858);
  static const double initialZoom = 7.0;
  static const double zoomWhenFocused = 16;
  static const int minMs = 1;
  static const int maxMs = 1200;
  static const double fillRatio = 0.85;
  
  static const int gpsSampleIntervalMs = 100;
  // For OSM etiquette. Replace with your real app id when you set it.
  static const String userAgentPackageName = 'com.example.toll_cam';
  static const String mapURL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    static const String camerasAsset = 'assets/data/toll_cameras_points.geojson';

}
