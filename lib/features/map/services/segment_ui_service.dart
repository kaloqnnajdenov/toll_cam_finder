import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

import 'upcoming_segment_cue_service.dart';

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

  static const double _forwardHeadingToleranceDegrees = 70.0;
  static const double _headingFlipThresholdDegrees = 135.0;
  static const double _slowSpeedThresholdKph = 10.0;

  String? buildSegmentProgressLabel({
    required SegmentTrackerEvent event,
    required SegmentDebugPath? activePath,
    required AppLocalizations localizations,
    UpcomingSegmentCueService? cueService,
    double? headingDegrees,
    double? speedKph,
  }) {
    final Iterable<SegmentDebugPath> paths = event.debugData.candidatePaths;
    if (paths.isEmpty) {
      cueService?.reset();
      return null;
    }

    if (event.activeSegmentId != null) {
      cueService?.reset();
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

    final List<SegmentDebugPath> filteredPaths = _filterCandidatesByHeading(
      paths,
      headingDegrees: headingDegrees,
      speedKph: speedKph,
    );

    SegmentDebugPath? upcoming;
    for (final path in filteredPaths) {
      final double startDist = path.startDistanceMeters;
      if (!startDist.isFinite) continue;
      if (startDist <= 500) {
        if (upcoming == null || startDist < upcoming!.startDistanceMeters) {
          upcoming = path;
        }
      }
    }

    if (upcoming == null) {
      cueService?.reset();
      return null;
    }

    final double distance = upcoming.startDistanceMeters;
    cueService?.updateCue(upcoming);
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

  double? nearestUpcomingSegmentDistance(
    Iterable<SegmentDebugPath> paths, {
    double? headingDegrees,
    double? speedKph,
  }) {
    final List<SegmentDebugPath> filteredPaths = _filterCandidatesByHeading(
      paths,
      headingDegrees: headingDegrees,
      speedKph: speedKph,
    );
    double? closest;
    for (final SegmentDebugPath path in filteredPaths) {
      final double distance = path.startDistanceMeters;
      if (!distance.isFinite || distance < 0) continue;
      if (closest == null || distance < closest) {
        closest = distance;
      }
    }
    return closest;
  }

  List<SegmentDebugPath> _filterCandidatesByHeading(
    Iterable<SegmentDebugPath> paths, {
    double? headingDegrees,
    double? speedKph,
  }) {
    final List<SegmentDebugPath> candidates =
        List<SegmentDebugPath>.from(paths, growable: false);
    if (candidates.isEmpty) {
      return const <SegmentDebugPath>[];
    }

    if (headingDegrees == null) {
      return candidates;
    }

    if (speedKph != null && speedKph < _slowSpeedThresholdKph) {
      return candidates;
    }

    bool shouldFallback = false;
    final List<SegmentDebugPath> filtered = <SegmentDebugPath>[];
    for (final SegmentDebugPath path in candidates) {
      final double? bearing = _forwardBearing(path.polyline);
      if (bearing == null) {
        filtered.add(path);
        continue;
      }

      final double delta =
          _minimalHeadingDeltaDegrees(headingDegrees, bearing);
      if (delta >= _headingFlipThresholdDegrees) {
        shouldFallback = true;
        break;
      }

      if (delta <= _forwardHeadingToleranceDegrees) {
        filtered.add(path);
      }
    }

    if (shouldFallback || filtered.isEmpty) {
      return candidates;
    }

    return filtered;
  }

  double? _forwardBearing(List<LatLng> polyline) {
    if (polyline.length < 2) {
      return null;
    }

    for (int i = 0; i < polyline.length - 1; i++) {
      final LatLng current = polyline[i];
      final LatLng next = polyline[i + 1];
      final double? bearing = _bearingBetween(current, next);
      if (bearing != null) {
        return bearing;
      }
    }
    return null;
  }

  double? _bearingBetween(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180.0;
    final double lat2 = to.latitude * math.pi / 180.0;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180.0;

    if (dLon.abs() <= 1e-9 && (lat2 - lat1).abs() <= 1e-9) {
      return null;
    }

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = bearingRad * 180.0 / math.pi;
    final double normalized = (bearingDeg + 360.0) % 360.0;
    return normalized.isFinite ? normalized : null;
  }

  double _minimalHeadingDeltaDegrees(double a, double b) {
    double diff = (a - b).abs();
    while (diff > 360) {
      diff -= 360;
    }
    if (diff > 180) {
      diff = 360 - diff;
    }
    return diff.abs();
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
