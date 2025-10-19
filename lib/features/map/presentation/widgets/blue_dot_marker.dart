import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/core/constants.dart';

/// Draws a subtle blue accuracy dot at [point].
/// Defaults match previous visuals; added params for future flexibility.
class BlueDotMarker extends StatelessWidget {
  final LatLng? point;
  final double size;
  final double innerSize;
  final double outerOpacity;

  const BlueDotMarker({
    super.key,
    required this.point,
    this.size = AppConstants.blueDotMarkerSize,
    this.innerSize = AppConstants.blueDotMarkerInnerSize,
    this.outerOpacity = AppConstants.blueDotMarkerOuterOpacity,
  });

  @override
  Widget build(BuildContext context) {
    if (point == null) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        Marker(
          point: point!,
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(outerOpacity),
            ),
            child: Center(
              child: Container(
                width: innerSize,
                height: innerSize,
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
