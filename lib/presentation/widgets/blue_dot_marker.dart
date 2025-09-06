// lib/widgets/blue_dot_marker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BlueDotMarker extends StatelessWidget {
  final LatLng? point;

  const BlueDotMarker({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    if (point == null) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        Marker(
          point: point!,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.25),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
