import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

import 'map_controls_panel_card.dart';

class BottomMapControlsPanel extends StatelessWidget {
  const BottomMapControlsPanel({
    super.key,
    required this.mediaQuery,
    required this.speedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    required this.segmentSpeedLimitKph,
    required this.segmentDebugPath,
    required this.distanceToSegmentStartMeters,
    required this.distanceToSegmentStartIsCapped,
    required this.isLandscape,
  });

  final MediaQueryData mediaQuery;
  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? segmentSpeedLimitKph;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;
  final bool distanceToSegmentStartIsCapped;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final double availableWidth =
        math.max(0, mediaQuery.size.width - _horizontalPadding);

    return SafeArea(
      top: false,
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              mediaQuery.padding.bottom + 12,
            ),
            child: MapControlsPanelCard(
              colorScheme: Theme.of(context).colorScheme,
              speedKmh: speedKmh,
              avgController: avgController,
              hasActiveSegment: hasActiveSegment,
              segmentSpeedLimitKph: segmentSpeedLimitKph,
              segmentDebugPath: segmentDebugPath,
              distanceToSegmentStartMeters: distanceToSegmentStartMeters,
              distanceToSegmentStartIsCapped: distanceToSegmentStartIsCapped,
              maxWidth: availableWidth,
              maxHeight: null,
              stackMetricsVertically: true,
              forceSingleRow: false,
              isLandscape: isLandscape,
            ),
          ),
        ),
      ),
    );
  }

  static const double _horizontalPadding = 32;
}
