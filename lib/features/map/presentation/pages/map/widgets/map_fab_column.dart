import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';

class MapFabColumn extends StatelessWidget {
  const MapFabColumn({
    super.key,
    required this.followUser,
    required this.followHeading,
    required this.onToggleHeading,
    required this.onResetView,
    this.headingDegrees,
  });

  final bool followUser;
  final bool followHeading;
  final VoidCallback onToggleHeading;
  final VoidCallback onResetView;
  final double? headingDegrees;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final children = <Widget>[
      if (!followHeading)
        _MapMiniFab(
          heroTag: 'heading_btn',
          tooltip: localizations.faceTravelDirection,
          onPressed: onToggleHeading,
          child: _CompassNeedle(
            headingDegrees: headingDegrees,
          ),
        ),
      if (!followHeading && !followUser) const SizedBox(height: 12),
      if (!followUser)
        _MapMiniFab(
          heroTag: 'recenter_btn',
          tooltip: localizations.recenter,
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
    required this.headingDegrees,
  });

  final double? headingDegrees;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final color = palette.onSurface;
    final bool hasHeading = headingDegrees != null;
    final double rotationTurns = hasHeading ? (headingDegrees! % 360) / 360 : 0;

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
          Icon(Icons.lock, size: 12, color: color.withOpacity(0.7)),
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
  });

  final String heroTag;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor =
        palette.surface.withOpacity(isDark ? 0.7 : 0.92);
    final Color borderColor =
        palette.divider.withOpacity(isDark ? 1 : 0.7);

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
