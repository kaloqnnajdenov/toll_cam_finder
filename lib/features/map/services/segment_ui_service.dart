import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

class SegmentUiService {
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
  }) {
    final Iterable<SegmentDebugPath> paths = event.debugData.candidatePaths;
    if (paths.isEmpty) {
      return null;
    }

    if (event.activeSegmentId != null) {
      final SegmentDebugPath? path =
          activePath ?? resolveActiveSegmentPath(paths, event);

      if (path != null &&
          path.remainingDistanceMeters.isFinite &&
          path.remainingDistanceMeters >= 0) {
        final double remaining = path.remainingDistanceMeters;
        if (remaining >= 1000) {
          return localizations.translate(
            'segmentProgressEndKilometers',
            {'distance': (remaining / 1000).toStringAsFixed(2)},
          );
        }
        if (remaining >= 1) {
          return localizations.translate(
            'segmentProgressEndMeters',
            {'distance': remaining.toStringAsFixed(0)},
          );
        }
        return localizations.translate('segmentProgressEndNearby');
      }
      return null;
    }

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
      return null;
    }

    final double distance = upcoming.startDistanceMeters;
    if (distance >= 1000) {
      return localizations.translate(
        'segmentProgressStartKilometers',
        {'distance': (distance / 1000).toStringAsFixed(2)},
      );
    }
    if (distance >= 1) {
      return localizations.translate(
        'segmentProgressStartMeters',
        {'distance': distance.toStringAsFixed(0)},
      );
    }
    return localizations.translate('segmentProgressStartNearby');
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
