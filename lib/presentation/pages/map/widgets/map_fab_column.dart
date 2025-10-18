import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

class MapFabColumn extends StatelessWidget {
  const MapFabColumn({
    super.key,
    required this.isHeadingUp,
    required this.onToggleHeadingAlignment,
    required this.followUser,
    required this.onResetView,
    required this.avgController,
  });

  final bool isHeadingUp;
  final VoidCallback onToggleHeadingAlignment;
  final bool followUser;
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
          onPressed: onToggleHeadingAlignment,
          icon: Icon(
            isHeadingUp ? Icons.navigation : Icons.navigation_outlined,
          ),
          label: Text(
            isHeadingUp
                ? AppLocalizations.of(context).northUp
                : AppLocalizations.of(context).headingUp,
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
