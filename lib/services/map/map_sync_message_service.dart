import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/services/toll_segments_sync_service.dart';

class MapSyncMessageService {
  const MapSyncMessageService();

  String buildSuccessMessage(TollSegmentsSyncResult result) {
    return AppMessages.syncCompleteSummary(
      addedSegments: result.addedSegments,
      removedSegments: result.removedSegments,
      totalSegments: result.totalSegments,
      approvedLocalSegments: result.approvedLocalSegments,
    );
  }
}
