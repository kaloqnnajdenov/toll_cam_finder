import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

import 'upcoming_segment_cue_service.dart';

class SegmentUiService {
  String? _previousActiveSegmentId;

  SegmentDebugPath? resolveActiveSegmentPath(
    Iterable<SegmentDebugPath> paths,
    SegmentTrackerEvent event,
  ) {
    final String? activeId = event.activeSegmentId;
    if (activeId == null) {
      return null;
    }

    return _firstPathMatching(
          paths,
          (p) => p.id == activeId && p.isActive,
        ) ??
        _firstPathMatching(paths, (p) => p.id == activeId) ??
        _firstPathMatching(paths, (p) => p.isActive);
  }

  String? buildSegmentProgressLabel({
    required SegmentTrackerEvent event,
    required SegmentDebugPath? activePath,
    required AppLocalizations localizations,
    required UpcomingSegmentCueService cueService,
  }) {
    if (event.endedSegment) {
      cueService.notifySegmentExit(segmentId: _previousActiveSegmentId);
    }

    final Iterable<SegmentDebugPath> paths = event.debugData.candidatePaths;
    String? label;

    if (paths.isEmpty) {
      cueService.reset();
    } else if (event.activeSegmentId != null) {
      cueService.reset();
      final SegmentDebugPath? path =
          activePath ?? resolveActiveSegmentPath(paths, event);

      if (path != null &&
          path.remainingDistanceMeters.isFinite &&
          path.remainingDistanceMeters >= 0) {
        final double remaining = path.remainingDistanceMeters;
        if (remaining >= 1000) {
          label = localizations.translate(
            'segmentProgressEndKilometers',
            {'distance': (remaining / 1000).toStringAsFixed(2)},
          );
        } else if (remaining >= 1) {
          label = localizations.translate(
            'segmentProgressEndMeters',
            {'distance': remaining.toStringAsFixed(0)},
          );
        } else {
          label = localizations.translate('segmentProgressEndNearby');
        }
      }
    } else {
      SegmentDebugPath? upcoming;
      for (final path in paths) {
        final double startDist = path.startDistanceMeters;
        if (!startDist.isFinite) continue;
        if (startDist <= 500) {
          if (upcoming == null || startDist < upcoming!.startDistanceMeters) {
            upcoming = path;
          }
        }
      }

      if (upcoming == null) {
        cueService.reset();
      } else {
        final double distance = upcoming.startDistanceMeters;
        cueService.updateCue(upcoming);
        if (distance >= 1000) {
          label = localizations.translate(
            'segmentProgressStartKilometers',
            {'distance': (distance / 1000).toStringAsFixed(2)},
          );
        } else if (distance >= 1) {
          label = localizations.translate(
            'segmentProgressStartMeters',
            {'distance': distance.toStringAsFixed(0)},
          );
        } else {
          label = localizations.translate('segmentProgressStartNearby');
        }
      }
    }

    _previousActiveSegmentId = event.activeSegmentId;
    return label;
  }

  double? nearestUpcomingSegmentDistance(Iterable<SegmentDebugPath> paths) {
    double? closest;
    for (final SegmentDebugPath path in paths) {
      final double distance = path.startDistanceMeters;
      if (!distance.isFinite || distance < 0) continue;
      if (closest == null || distance < closest) {
        closest = distance;
      }
    }
    return closest;
  }

  SegmentDebugPath? _firstPathMatching(
    Iterable<SegmentDebugPath> paths,
    bool Function(SegmentDebugPath) predicate,
  ) {
    for (final SegmentDebugPath path in paths) {
      if (predicate(path)) {
        return path;
      }
    }
    return null;
  }
}
