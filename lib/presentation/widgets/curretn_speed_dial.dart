import 'package:flutter/material.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/presentation/widgets/smooth_number_text.dart';

/// Live "current speed" dial to mirror the Avg Speed dial.
/// Pure UI: you pass [speedKmh]. Handles null/NaN gracefully.
class CurrentSpeedDial extends StatelessWidget {
  const CurrentSpeedDial({
    super.key,
    required this.speedKmh,
    this.title = 'Speed',
    this.decimals = AppConstants.speedDialDefaultDecimals,
    this.unit = 'km/h',
    this.width = AppConstants.speedDialDefaultWidth,
  });

  final double? speedKmh;
  final String title;
  final int decimals;
  final String unit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final double? value = (speedKmh != null && speedKmh!.isFinite)
        ? speedKmh!.clamp(0, double.infinity).toDouble()
        : null;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.speedDialCardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.speedDialCardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.speedDialHeaderGap),
              // Big numeric + unit
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SmoothNumberText(
                      value: value,
                      decimals: decimals,
                      style: textTheme.displaySmall,
                    ),
                    const SizedBox(width: AppConstants.speedDialValueUnitSpacing),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.speedDialUnitBaselinePadding,
                      ),
                      child: Text(unit, style: textTheme.titleSmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
