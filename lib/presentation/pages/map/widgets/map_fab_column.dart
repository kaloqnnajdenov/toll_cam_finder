import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/presentation/widgets/avg_speed_button.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

class MapFabColumn extends StatelessWidget {
  const MapFabColumn({
    super.key,
    required this.followUser,
    required this.onResetView,
    required this.avgController,
    required this.followHeading,
    required this.onToggleHeading,
    required this.mapRotationDeg,
  });

  final bool followUser;
  final VoidCallback onResetView;
  final AverageSpeedController avgController;
  final bool followHeading;
  final VoidCallback onToggleHeading;
  final double mapRotationDeg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool headingActive = followHeading;
    final Color background = headingActive
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final Color foreground = headingActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'heading_btn',
          onPressed: onToggleHeading,
          backgroundColor: background,
          foregroundColor: foreground,
          child: Transform.rotate(
            angle: -mapRotationDeg * math.pi / 180,
            child: const Text(
              'N',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'recenter_btn',
          onPressed: onResetView,
          icon: Icon(
            followUser ? Icons.my_location : Icons.my_location_outlined,
          ),
          label: const Text('Recenter'),
        ),
        const SizedBox(height: 12),
        AverageSpeedButton(controller: avgController),
      ],
    );
  }
}
