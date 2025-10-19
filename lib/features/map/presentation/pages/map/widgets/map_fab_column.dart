import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';

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

  //TODO: remove unnecesery logic if not needed in FABs
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final children = <Widget>[
      if (!followHeading)
        _MapMiniFab(
          heroTag: 'heading_btn',
          tooltip: followHeading
              ? localizations.northUp
              : localizations.faceTravelDirection,
          active: false,
          onPressed: onToggleHeading,
          child: _CompassNeedle(
            followHeading: false,
            headingDegrees: headingDegrees,
            color: palette.onSurface,
          ),
        ),
      if (!followHeading && !followUser) const SizedBox(height: 12),
      if (!followUser)
        _MapMiniFab(
          heroTag: 'recenter_btn',
          tooltip: localizations.recenter,
          active: false,
          onPressed: onResetView,
          child: Icon(Icons.my_location_outlined, color: palette.onSurface),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }
}

class _CompassNeedle extends StatelessWidget {
  const _CompassNeedle({
    required this.followHeading,
    required this.headingDegrees,
    required this.color,
  });

  final bool followHeading;
  final double? headingDegrees;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool shouldRotate = followHeading && headingDegrees != null;
    final double rotationTurns = shouldRotate
        ? (headingDegrees! % 360) / 360
        : 0;

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedRotation(
            turns: rotationTurns,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.navigation, size: 22, color: color),
          ),
          AnimatedOpacity(
            opacity: followHeading ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.lock, size: 12, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _MapMiniFab extends StatelessWidget {
  const _MapMiniFab({
    required this.heroTag,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    required this.active,
  });

  final String heroTag;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor = active
        ? palette.primary
        : palette.surface.withOpacity(isDark ? 0.7 : 0.92);
    final Color borderColor = active
        ? Colors.transparent
        : palette.divider.withOpacity(isDark ? 1 : 0.7);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FloatingActionButton.small(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: backgroundColor,
        shape: CircleBorder(side: BorderSide(color: borderColor, width: 1)),
        child: child,
      ),
    );
  }
}
