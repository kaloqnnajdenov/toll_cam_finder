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
    required this.showHeadingButton,
    required this.showRecenterButton,
    this.headingDegrees,
  });

  final bool followUser;
  final bool followHeading;
  final VoidCallback onToggleHeading;
  final VoidCallback onResetView;
  final AverageSpeedController avgController;
  final double? headingDegrees;
  final bool showHeadingButton;
  final bool showRecenterButton;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AnimatedFabVisibility(
          hiddenKey: 'heading_hidden',
          visible: showHeadingButton,
          axisAlignment: -1,
          child: _MapMiniFab(
            key: const ValueKey('heading_btn'),
            heroTag: 'heading_btn',
            tooltip: followHeading
                ? localizations.northUp
                : localizations.faceTravelDirection,
            active: followHeading,
            onPressed: onToggleHeading,
            child: _CompassNeedle(
              followHeading: followHeading,
              headingDegrees: headingDegrees,
              color: followHeading ? Colors.white : palette.onSurface,
            ),
          ),
        ),
        _AnimatedFabSpacing(visible: showHeadingButton && showRecenterButton),
        _AnimatedFabVisibility(
          hiddenKey: 'recenter_hidden',
          visible: showRecenterButton,
          axisAlignment: 1,
          child: _MapMiniFab(
            key: const ValueKey('recenter_btn'),
            heroTag: 'recenter_btn',
            tooltip: localizations.recenter,
            active: followUser,
            onPressed: onResetView,
            child: Icon(
              followUser ? Icons.my_location : Icons.my_location_outlined,
              color: followUser ? Colors.white : palette.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

const Duration _kFabAnimationDuration = Duration(milliseconds: 240);

class _AnimatedFabVisibility extends StatelessWidget {
  const _AnimatedFabVisibility({
    required this.visible,
    required this.child,
    required this.hiddenKey,
    this.axisAlignment = 0,
  });

  final bool visible;
  final Widget child;
  final String hiddenKey;
  final double axisAlignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _kFabAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: axisAlignment,
            child: child,
          ),
        );
      },
      child: visible
          ? child
          : SizedBox.shrink(key: ValueKey(hiddenKey)),
    );
  }
}

class _AnimatedFabSpacing extends StatelessWidget {
  const _AnimatedFabSpacing({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _kFabAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 1,
          child: child,
        );
      },
      child: visible
          ? const SizedBox(height: 12, key: ValueKey('fab_spacing'))
          : const SizedBox(key: ValueKey('fab_spacing_empty')),
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
            child: Icon(
              Icons.lock,
              size: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMiniFab extends StatelessWidget {
  const _MapMiniFab({
    super.key,
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
        shape: CircleBorder(
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: child,
      ),
    );
  }
}