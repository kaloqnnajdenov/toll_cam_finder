import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';

import 'segment_ui_service.dart';

class ForegroundNotificationService {
  ForegroundNotificationService({SegmentUiService? segmentUiService})
      : _segmentUiService = segmentUiService ?? SegmentUiService();

  final SegmentUiService _segmentUiService;

  String buildStatus({
    required SegmentTrackerEvent event,
    required AverageSpeedController avgController,
  }) {
    final String? activeId = event.activeSegmentId;
    if (activeId != null) {
      final double? limit = event.activeSegmentSpeedLimitKph;
      final double avg = avgController.average;
      final String limitText =
          (limit != null && limit.isFinite) ? '${limit.toStringAsFixed(0)} km/h' : '--';
      final String avgText = avg.isFinite ? '${avg.toStringAsFixed(0)} km/h' : '--';
      return 'On segment • Avg $avgText • Allowed $limitText';
    }

    final double? distance = _segmentUiService
        .nearestUpcomingSegmentDistance(event.debugData.candidatePaths);
    if (distance != null && distance <= 1500) {
      final int meters = distance.round();
      return '$meters m to segment start';
    }

    return 'no segment nearby';
  }
}
