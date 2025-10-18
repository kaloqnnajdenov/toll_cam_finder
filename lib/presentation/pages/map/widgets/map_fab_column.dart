import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

class MapFabColumn extends StatelessWidget {
  const MapFabColumn({
    super.key,
    required this.followUser,
    required this.followHeading,
    required this.onToggleHeading,
    required this.onResetView,
    required this.avgController,
  });

  final bool followUser;
  final bool followHeading;
  final VoidCallback onToggleHeading;
  final VoidCallback onResetView;
  final AverageSpeedController avgController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'heading_btn',
          onPressed: onToggleHeading,
          icon: Icon(
            followHeading ? Icons.explore : Icons.navigation,
          ),
          label: Text(
            followHeading
                ? AppLocalizations.of(context).northUp
                : AppLocalizations.of(context).faceTravelDirection,
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'recenter_btn',
          onPressed: onResetView,
          icon: Icon(
            followUser ? Icons.my_location : Icons.my_location_outlined,
          ),
          label: Text(AppLocalizations.of(context).recenter),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
