import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

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
    final double horizontalPadding =
        mediaQuery.padding.left + mediaQuery.padding.right + 32;
    final double availableWidth =
        math.max(0, mediaQuery.size.width - horizontalPadding);
    final double panelMaxWidth = math.min(
      availableWidth,
      mediaQuery.size.width * 0.25,
    );

    double? panelMaxHeight;
    final double availableHeight = mediaQuery.size.height -
        (mediaQuery.padding.top + mediaQuery.padding.bottom + 32);
    if (availableHeight.isFinite && availableHeight > 0) {
      panelMaxHeight = availableHeight;
    }

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          mediaQuery.padding.left + 16,
          mediaQuery.padding.top + 16,
          16,
          mediaQuery.padding.bottom + 16,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: MapControlsPanelCard(
            colorScheme: Theme.of(context).colorScheme,
            speedKmh: speedKmh,
            avgController: avgController,
            hasActiveSegment: hasActiveSegment,
            segmentSpeedLimitKph: segmentSpeedLimitKph,
            segmentDebugPath: segmentDebugPath,
            distanceToSegmentStartMeters: distanceToSegmentStartMeters,
            maxWidth: panelMaxWidth,
            maxHeight: panelMaxHeight,
            stackMetricsVertically: false,
            forceSingleRow: true,
            isLandscape: isLandscape,
          ),
        ),
      ),
    );
  }
}
