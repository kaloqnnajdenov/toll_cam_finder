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
    this.headingDegrees,
  });

  final bool followUser;
  final bool followHeading;
  final VoidCallback onToggleHeading;
  final VoidCallback onResetView;
  final AverageSpeedController avgController;
  final double? headingDegrees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'heading_btn',
          onPressed: onToggleHeading,
          tooltip: followHeading
              ? AppLocalizations.of(context).northUp
              : AppLocalizations.of(context).faceTravelDirection,
          child: _CompassNeedle(
            followHeading: followHeading,
            headingDegrees: headingDegrees,
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

class _CompassNeedle extends StatelessWidget {
  const _CompassNeedle({
    required this.followHeading,
    required this.headingDegrees,
  });

  final bool followHeading;
  final double? headingDegrees;

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor =
        Theme.of(context).colorScheme.onPrimary.withOpacity(0.95);
    final TextStyle northStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: indicatorColor.withOpacity(0.8),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ) ??
        TextStyle(
          color: indicatorColor.withOpacity(0.8),
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0.4,
        );

    final bool shouldRotate = followHeading && headingDegrees != null;
    final double rotationTurns = shouldRotate ? (headingDegrees! % 360) / 360 : 0;

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: Text('N', style: northStyle),
          ),
          AnimatedRotation(
            turns: rotationTurns,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.navigation,
              size: 22,
              color: indicatorColor,
            ),
          ),
          AnimatedOpacity(
            opacity: followHeading ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.lock,
              size: 12,
              color: indicatorColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
