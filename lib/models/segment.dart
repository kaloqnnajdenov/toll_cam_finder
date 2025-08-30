import 'package:latlong2/latlong.dart';

class TollSegment {
  final int? id;
  final String? roadNo;
  final String? name;
  final List<LatLng> coords;

  TollSegment({
    required this.id,
    required this.roadNo,
    required this.name,
    required this.coords,
  });
}
