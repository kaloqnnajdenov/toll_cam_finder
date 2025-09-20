import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:toll_cam_finder/presentation/widgets/avg_speed_dial.dart';
import 'package:toll_cam_finder/presentation/widgets/curretn_speed_dial.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

class MapControlsPanel extends StatelessWidget {
  const MapControlsPanel({
    super.key,
    required this.speedKmh,
    required this.avgController,
    required this.showDebugBadge,
    required this.segmentCount,
    required this.segmentRadiusMeters,
  });

  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool showDebugBadge;
  final int segmentCount;
  final double segmentRadiusMeters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentSpeedDial(speedKmh: speedKmh, unit: 'km/h'),
        const SizedBox(height: 12),
        AverageSpeedDial(controller: avgController, unit: 'km/h'),
        if (showDebugBadge && kDebugMode)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Segments: $segmentCount  r=${segmentRadiusMeters.toInt()}m',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );
  }
}