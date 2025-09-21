import 'package:flutter/material.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

class SegmentDebugStyles {
  const SegmentDebugStyles._();

  static Color colorForMatch(
    SegmentTrackerDebugMatch match, {
    required bool isActive,
  }) {
    if (isActive) {
      return Colors.greenAccent;
    }
    if (match.isBestCandidate) {
      return Colors.lightGreenAccent;
    }
    if (match.isOnSegment) {
      if (match.geofenceHit && (!match.onPath || !match.directionOk)) {
        return Colors.cyanAccent;
      }
      return Colors.blueAccent;
    }
    if (!match.onPath) {
      return Colors.redAccent;
    }
    if (!match.directionOk) {
      return Colors.orangeAccent;
    }
    return Colors.purpleAccent;
  }

  static double strokeWidthForMatch(
    SegmentTrackerDebugMatch match, {
    required bool isActive,
  }) {
    if (isActive) {
      return 6.0;
    }
    if (match.isBestCandidate) {
      return 5.0;
    }
    if (match.isOnSegment) {
      return 4.0;
    }
    return 3.0;
  }

  static List<SegmentDebugFlag> flagsForMatch(
    SegmentTrackerDebugMatch match,
  ) {
    final flags = <SegmentDebugFlag>[
      SegmentDebugFlag(
        match.onPath ? 'path✓' : 'path✗',
        match.onPath ? Colors.greenAccent : Colors.redAccent,
      ),
    ];

    if (match.directionDeltaDeg != null) {
      flags.add(
        SegmentDebugFlag(
          match.directionOk ? 'bearing✓' : 'bearing✗',
          match.directionOk ? Colors.greenAccent : Colors.orangeAccent,
        ),
      );
    } else {
      flags.add(
        const SegmentDebugFlag('bearing–', Colors.blueGrey),
      );
    }

    if (match.geofenceHit) {
      flags.add(
        const SegmentDebugFlag('geofence', Colors.cyanAccent),
      );
    }

    if (match.isBestCandidate) {
      flags.add(
        const SegmentDebugFlag('best', Colors.amberAccent),
      );
    } else if (match.isOnSegment) {
      flags.add(
        const SegmentDebugFlag('eligible', Colors.lightBlueAccent),
      );
    }

    return flags;
  }
}

class SegmentDebugFlag {
  final String label;
  final Color color;

  const SegmentDebugFlag(this.label, this.color);
}
