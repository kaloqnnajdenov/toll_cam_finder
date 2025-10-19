import 'package:flutter/material.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/shared/widgets/smooth_number_text.dart';

/// Live "current speed" dial to mirror the Avg Speed dial.
/// Pure UI: you pass [speedKmh]. Handles null/NaN gracefully.
class CurrentSpeedDial extends StatelessWidget {
  const CurrentSpeedDial({
    super.key,
    required this.speedKmh,
    this.title,
    this.decimals = AppConstants.speedDialDefaultDecimals,
    this.unit,
    this.width = AppConstants.speedDialDefaultWidth,
  });

  final double? speedKmh;
  final String? title;
  final int decimals;
  final String? unit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final resolvedTitle = title ?? AppMessages.speedDialCurrentTitle;
    final resolvedUnit = unit ?? AppMessages.speedDialUnitKmh;

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
                    resolvedTitle,
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
                      child: Text(resolvedUnit, style: textTheme.titleSmall),
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
