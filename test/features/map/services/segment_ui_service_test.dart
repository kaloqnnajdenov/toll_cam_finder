import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/map/services/segment_ui_service.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double forwardStartDistance = 120;
  const double reverseStartDistance = 30;

  SegmentTrackerEvent _eventWithCandidates(List<SegmentDebugPath> candidates) {
    return SegmentTrackerEvent(
      startedSegment: false,
      endedSegment: true,
      activeSegmentId: null,
      activeSegmentSpeedLimitKph: null,
      activeSegmentLengthMeters: null,
      completedSegmentLengthMeters: null,
      debugData: SegmentTrackerDebugData(
        isReady: true,
        querySquare: const [],
        boundingCandidates: const <SegmentGeometry>[],
        candidatePaths: candidates,
        startGeofenceRadius: 0,
        endGeofenceRadius: 0,
      ),
    );
  }

  SegmentDebugPath _forwardCandidate() {
    return const SegmentDebugPath(
      id: 'forward',
      polyline: <LatLng>[
        LatLng(0, 0),
        LatLng(0.001, 0),
      ],
      distanceMeters: 15,
      startDistanceMeters: forwardStartDistance,
      remainingDistanceMeters: 800,
      isWithinTolerance: true,
      startHit: false,
      endHit: false,
      isActive: false,
      isDetailed: true,
    );
  }

  SegmentDebugPath _reverseCandidate() {
    return const SegmentDebugPath(
      id: 'reverse',
      polyline: <LatLng>[
        LatLng(0, 0),
        LatLng(-0.001, 0),
      ],
      distanceMeters: 12,
      startDistanceMeters: reverseStartDistance,
      remainingDistanceMeters: 600,
      isWithinTolerance: true,
      startHit: false,
      endHit: false,
      isActive: false,
      isDetailed: true,
    );
  }

  group('SegmentUiService heading filtering', () {
    late SegmentUiService service;
    late AppLocalizations localizations;

    setUp(() {
      service = SegmentUiService();
      localizations = AppLocalizations(const Locale('en'));
    });

    test('prefers forward candidate while heading maintained', () {
      final SegmentTrackerEvent event =
          _eventWithCandidates(<SegmentDebugPath>[
        _forwardCandidate(),
        _reverseCandidate(),
      ]);

      final String? label = service.buildSegmentProgressLabel(
        event: event,
        activePath: null,
        localizations: localizations,
        cueService: null,
        headingDegrees: 0,
        speedKph: 60,
      );

      expect(label, isNotNull);
      expect(label!, contains(forwardStartDistance.toStringAsFixed(0)));

      final double? distance = service.nearestUpcomingSegmentDistance(
        event.debugData.candidatePaths,
        headingDegrees: 0,
        speedKph: 60,
      );

      expect(distance, forwardStartDistance);
    });

    test('falls back when heading reverses', () {
      final SegmentTrackerEvent event =
          _eventWithCandidates(<SegmentDebugPath>[
        _forwardCandidate(),
        _reverseCandidate(),
      ]);

      final String? label = service.buildSegmentProgressLabel(
        event: event,
        activePath: null,
        localizations: localizations,
        cueService: null,
        headingDegrees: 180,
        speedKph: 55,
      );

      expect(label, isNotNull);
      expect(label!, contains(reverseStartDistance.toStringAsFixed(0)));

      final double? distance = service.nearestUpcomingSegmentDistance(
        event.debugData.candidatePaths,
        headingDegrees: 180,
        speedKph: 55,
      );

      expect(distance, reverseStartDistance);
    });

    test('falls back when travelling slowly', () {
      final SegmentTrackerEvent event =
          _eventWithCandidates(<SegmentDebugPath>[
        _forwardCandidate(),
        _reverseCandidate(),
      ]);

      final String? label = service.buildSegmentProgressLabel(
        event: event,
        activePath: null,
        localizations: localizations,
        cueService: null,
        headingDegrees: 0,
        speedKph: 5,
      );

      expect(label, isNotNull);
      expect(label!, contains(reverseStartDistance.toStringAsFixed(0)));

      final double? distance = service.nearestUpcomingSegmentDistance(
        event.debugData.candidatePaths,
        headingDegrees: 0,
        speedKph: 5,
      );

      expect(distance, reverseStartDistance);
    });
  });
}
