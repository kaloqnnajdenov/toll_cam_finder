import 'package:flutter/material.dart';

import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

import 'map_controls/map_controls_panel_bottom.dart';
import 'map_controls/map_controls_panel_left.dart';

enum MapControlsPlacement { bottom, left }

class MapControlsPanel extends StatelessWidget {
  const MapControlsPanel({
    super.key,
    required this.speedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    this.segmentSpeedLimitKph,
    this.segmentDebugPath,
    this.distanceToSegmentStartMeters,
    this.placement = MapControlsPlacement.bottom,
  });

  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? segmentSpeedLimitKph;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;
  final MapControlsPlacement placement;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    switch (placement) {
      case MapControlsPlacement.left:
        return LeftMapControlsPanel(
          mediaQuery: mediaQuery,
          speedKmh: speedKmh,
          avgController: avgController,
          hasActiveSegment: hasActiveSegment,
          segmentSpeedLimitKph: segmentSpeedLimitKph,
          segmentDebugPath: segmentDebugPath,
          distanceToSegmentStartMeters: distanceToSegmentStartMeters,
          isLandscape: isLandscape,
        );
      case MapControlsPlacement.bottom:
      default:
        return BottomMapControlsPanel(
          mediaQuery: mediaQuery,
          speedKmh: speedKmh,
          avgController: avgController,
          hasActiveSegment: hasActiveSegment,
          segmentSpeedLimitKph: segmentSpeedLimitKph,
          segmentDebugPath: segmentDebugPath,
          distanceToSegmentStartMeters: distanceToSegmentStartMeters,
          isLandscape: isLandscape,
        );
    }
  }
}
