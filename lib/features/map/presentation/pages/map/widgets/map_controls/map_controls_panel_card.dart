import 'dart:ui';

import 'package:flutter/material.dart';

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
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final BorderRadius borderRadius = BorderRadius.circular(28);

    final Color primaryOverlay = Color.lerp(
          colorScheme.surface,
          Colors.white,
          isDark ? 0.35 : 0.85,
        )!
        .withOpacity(isDark ? 0.65 : 0.92);
    final Color secondaryOverlay = Color.lerp(
          colorScheme.surface,
          Colors.white,
          isDark ? 0.25 : 0.75,
        )!
        .withOpacity(isDark ? 0.58 : 0.85);
    final Color borderColor = Color.lerp(
          Colors.white,
          colorScheme.onSurface,
          isDark ? 0.65 : 0.1,
        )!
        .withOpacity(isDark ? 0.32 : 0.45);

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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryOverlay,
                  secondaryOverlay,
                ],
              ),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                   color: Colors.black.withOpacity(isDark ? 0.36 : 0.12),
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
