import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AnimatedFabSlot(
          visible: !followHeading,
          child: FloatingActionButton.small(
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
        ),
        _AnimatedFabSlot(
          visible: !followUser,
          child: FloatingActionButton.small(
            heroTag: 'recenter_btn',
            onPressed: onResetView,
            tooltip: AppLocalizations.of(context).recenter,
            child: Icon(
              followUser ? Icons.my_location : Icons.my_location_outlined,
            ),
          ),
        ),
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
    final ThemeData theme = Theme.of(context);
    final Color indicatorColor =
        theme.floatingActionButtonTheme.foregroundColor ??
        theme.colorScheme.onPrimary;

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
            child: Icon(Icons.navigation, size: 22, color: indicatorColor),
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

class _AnimatedFabSlot extends StatelessWidget {
  const _AnimatedFabSlot({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !visible,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: Align(
                alignment: Alignment.centerRight,
                child: child,
              ),
            ),
          );
        },
        child: visible
            ? Column(
                key: const ValueKey<bool>(true),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  child,
                  const SizedBox(height: 12),
                ],
              )
            : const SizedBox.shrink(key: ValueKey<bool>(false)),
      ),
    );
  }
}