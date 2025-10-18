import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(1, 1, 1, 1),
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
    );
  }
}
