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
        _RoundActionButton(
          heroTag: 'heading_btn',
          onPressed: onToggleHeading,
          tooltip: followHeading
              ? AppLocalizations.of(context).northUp
              : AppLocalizations.of(context).faceTravelDirection,
          gradientColors: const [
            Color(0xFF7EB7FF),
            Color(0xFF4C8DFF),
          ],
          child: _CompassNeedle(
            followHeading: followHeading,
            headingDegrees: headingDegrees,
          ),
        ),
        const SizedBox(height: 12),
        _RoundActionButton(
          heroTag: 'recenter_btn',
          onPressed: onResetView,
          tooltip: AppLocalizations.of(context).recenter,
          gradientColors: const [
            Color(0xFFF5F7FB),
            Color(0xFFE1E7F2),
          ],
          child: Icon(
            followUser ? Icons.my_location : Icons.radio_button_unchecked,
            color: const Color(0xFF3A4B66),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.heroTag,
    required this.onPressed,
    required this.tooltip,
    required this.gradientColors,
    required this.child,
  });

  final String heroTag;
  final VoidCallback onPressed;
  final String tooltip;
  final List<Color> gradientColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color shadowColor = Colors.black.withOpacity(0.12);

    return Hero(
      tag: heroTag,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: shadowColor,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
              shape: BoxShape.circle,
            ),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
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
    final Color indicatorColor = Colors.white;

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
            child: Icon(Icons.navigation, size: 24, color: indicatorColor),
          ),
          AnimatedOpacity(
            opacity: followHeading ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.lock,
              size: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
