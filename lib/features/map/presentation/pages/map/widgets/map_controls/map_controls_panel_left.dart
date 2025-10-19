import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

import 'map_controls_panel_card.dart';

class LeftMapControlsPanel extends StatelessWidget {
  const LeftMapControlsPanel({
    super.key,
    required this.mediaQuery,
    required this.speedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    required this.segmentSpeedLimitKph,
    required this.segmentDebugPath,
    required this.distanceToSegmentStartMeters,
    required this.isLandscape,
  });

  final MediaQueryData mediaQuery;
  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? segmentSpeedLimitKph;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    // Horizontal space available after safe-area insets.
    final double horizontalPadding =
        mediaQuery.padding.left + mediaQuery.padding.right;
    final double availableWidth =
        math.max(0, mediaQuery.size.width - horizontalPadding);
    final double panelMaxWidth = math.min(
      availableWidth,
      mediaQuery.size.width * 0.25,
    );

    // Fill the safe-area vertical space.
    final double panelHeight = math.max(
      0,
      mediaQuery.size.height -
          (mediaQuery.padding.top + mediaQuery.padding.bottom),
    );

    return Material(
      color: Colors.transparent,
      child: Padding(
        // Keep the same external padding as before.
        padding: EdgeInsets.fromLTRB(
          mediaQuery.padding.left + 16,
          mediaQuery.padding.top,
          16,
          mediaQuery.padding.bottom,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          // Constrain the child so it can use the full vertical space.
          child: SizedBox(
            width: panelMaxWidth,
            height: panelHeight,
            child: MapControlsPanelCard(
              colorScheme: Theme.of(context).colorScheme,
              speedKmh: speedKmh,
              avgController: avgController,
              hasActiveSegment: hasActiveSegment,
              segmentSpeedLimitKph: segmentSpeedLimitKph,
              segmentDebugPath: segmentDebugPath,
              distanceToSegmentStartMeters: distanceToSegmentStartMeters,
              maxWidth: panelMaxWidth,
              maxHeight: panelHeight,
              stackMetricsVertically: false,
              forceSingleRow: true,
              isLandscape: isLandscape,
            ),
          ),
        ),
      ),
    );
  }
}
