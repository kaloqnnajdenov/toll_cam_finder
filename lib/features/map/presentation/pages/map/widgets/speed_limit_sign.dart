import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_colors.dart';

class SpeedLimitSign extends StatelessWidget {
  const SpeedLimitSign({super.key, this.speedLimit, this.currentSpeedKmh});

  final String? speedLimit;
  final double? currentSpeedKmh;

  @override
  Widget build(BuildContext context) {
    final String trimmed = speedLimit?.trim() ?? '';
    final String displayText = trimmed.isEmpty ? '–' : trimmed;
    final double? limitValue = double.tryParse(trimmed);
    final double? current = currentSpeedKmh;
    final bool isOverspeed =
        limitValue != null && current != null && limitValue > 0 && current >= limitValue;

    final AppPalette palette = AppColors.of(context);
    final Color fillColor = isOverspeed ? palette.danger : Colors.white;
    final double borderWidth = isOverspeed ? 0 : 6;
    final Color textColor = isOverspeed ? Colors.white : palette.onSurface;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: fillColor,
          shape: BoxShape.circle,
          border: Border.all(color: palette.danger, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ).copyWith(color: textColor),
        ),
      ),
    );
  }
}
