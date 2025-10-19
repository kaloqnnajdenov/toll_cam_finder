import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_colors.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

import 'segment_metrics_card.dart';

class MapControlsPanelCard extends StatelessWidget {
  const MapControlsPanelCard({
    super.key,
    required this.colorScheme,
    required this.speedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    required this.segmentSpeedLimitKph,
    required this.segmentDebugPath,
    required this.distanceToSegmentStartMeters,
    required this.maxWidth,
    required this.maxHeight,
    required this.stackMetricsVertically,
    required this.forceSingleRow,
    required this.isLandscape,
  });

  final ColorScheme colorScheme;
  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? segmentSpeedLimitKph;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;
  final double maxWidth;
  final double? maxHeight;
  final bool stackMetricsVertically;
  final bool forceSingleRow;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(28);
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = AppColors.surface.withOpacity(0.72);
    final Color borderColor = AppColors.divider.withOpacity(isDark ? 1 : 0.9);
    final Color shadowColor = Colors.black.withOpacity(isDark ? 0.42 : 0.25);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              child: SegmentMetricsCard(
                currentSpeedKmh: speedKmh,
                avgController: avgController,
                hasActiveSegment: hasActiveSegment,
                speedLimitKph: segmentSpeedLimitKph,
                distanceToSegmentStartMeters: distanceToSegmentStartMeters,
                distanceToSegmentEndMeters:
                    segmentDebugPath?.remainingDistanceMeters,
                stackMetricsVertically: stackMetricsVertically,
                forceSingleRow: forceSingleRow,
                maxAvailableHeight: maxHeight,
                isLandscape: isLandscape,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
