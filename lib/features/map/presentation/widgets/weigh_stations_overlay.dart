import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:toll_cam_finder/features/map/presentation/pages/map/weigh_station_controller.dart';

class WeighStationsOverlay extends StatelessWidget {
  const WeighStationsOverlay({
    super.key,
    required this.visibleStations,
  });

  final List<WeighStationMarker> visibleStations;

  @override
  Widget build(BuildContext context) {
    if (visibleStations.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: visibleStations
          .map(
            (station) => Marker(
              point: station.position,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                child: const Icon(
                  Icons.scale,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
