import 'package:flutter/material.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

/// Mini FAB that toggles Start/Reset for average speed.
class AverageSpeedButton extends StatelessWidget {
  const AverageSpeedButton({super.key, required this.controller});

  final AverageSpeedController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final running = controller.isRunning;
        final l10n = AppLocalizations.of(context);
        return FloatingActionButton.small(
          heroTag: 'avg_speed_btn',
          onPressed: () => running ? controller.reset() : controller.start(),
          tooltip: running
              ? l10n.averageSpeedResetTooltip
              : l10n.averageSpeedStartTooltip,
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: AppConstants.avgSpeedButtonAnimationMs,
            ),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              running ? Icons.refresh : Icons.play_arrow,
              key: ValueKey<bool>(running),
            ),
          ),
        );
      },
    );
  }
}
