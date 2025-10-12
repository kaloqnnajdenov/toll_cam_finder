import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/services/map/camera_polling_service.dart';
import 'package:toll_cam_finder/services/map/map_sync_message_service.dart';
import 'package:toll_cam_finder/services/map/toll_camera_controller.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';
import 'package:toll_cam_finder/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/services/toll_segments_sync_service.dart';

class SegmentsMetadataLoadResult {
  const SegmentsMetadataLoadResult({
    required this.metadata,
    this.errorMessage,
  });

  final SegmentsMetadata metadata;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

class SegmentsRefreshResult {
  const SegmentsRefreshResult({
    required this.metadata,
    required this.metadataError,
    required this.reloaded,
    required this.seedEvent,
  });

  final SegmentsMetadata metadata;
  final String? metadataError;
  final bool reloaded;
  final SegmentTrackerEvent? seedEvent;
}

enum SyncResultStatus { success, missingClient, failure }

class SegmentsSyncResult {
  const SegmentsSyncResult({
    required this.status,
    this.message,
    this.seedEvent,
    required this.reloaded,
  });

  final SyncResultStatus status;
  final String? message;
  final SegmentTrackerEvent? seedEvent;
  final bool reloaded;

  bool get isSuccess => status == SyncResultStatus.success;
}

class MapSegmentsService {
  MapSegmentsService({
    required SegmentsMetadataService metadataService,
    required SegmentTracker segmentTracker,
    required TollCameraController cameraController,
    required CameraPollingService cameraPollingService,
    required TollSegmentsSyncService syncService,
    required MapSyncMessageService syncMessageService,
  })  : _metadataService = metadataService,
        _segmentTracker = segmentTracker,
        _cameraController = cameraController,
        _cameraPollingService = cameraPollingService,
        _syncService = syncService,
        _syncMessageService = syncMessageService;

  final SegmentsMetadataService _metadataService;
  final SegmentTracker _segmentTracker;
  final TollCameraController _cameraController;
  final CameraPollingService _cameraPollingService;
  final TollSegmentsSyncService _syncService;
  final MapSyncMessageService _syncMessageService;

  Future<SegmentsMetadataLoadResult> loadSegmentsMetadata({
    bool showErrors = false,
  }) async {
    try {
      final metadata = await _metadataService.load();
      _segmentTracker.updateIgnoredSegments(metadata.deactivatedSegmentIds);
      return SegmentsMetadataLoadResult(metadata: metadata);
    } on SegmentsMetadataException catch (error) {
      _segmentTracker.updateIgnoredSegments(const <String>{});
      if (!showErrors) {
        debugPrint(
          'MapSegmentsService: failed to load segments metadata (${error.message}).',
        );
      }
      return SegmentsMetadataLoadResult(
        metadata: const SegmentsMetadata(),
        errorMessage: AppMessages.failedToLoadSegmentPreferences(error.message),
      );
    }
  }

  Future<void> loadCameras({required Set<String> excludedSegmentIds}) async {
    await _cameraController.loadFromAsset(
      AppConstants.camerasAsset,
      excludedSegmentIds: excludedSegmentIds,
    );
  }

  DateTime? calculateNextCameraCheck({required LatLng position}) {
    if (_segmentTracker.activeSegmentId != null) {
      return null;
    }

    final double? distance =
        _cameraController.nearestCameraDistanceMeters(position);
    final Duration delay = _cameraPollingService.delayForDistance(distance);
    if (delay <= Duration.zero) {
      return null;
    }
    return DateTime.now().add(delay);
  }

  bool shouldProcessSegmentUpdate({
    required DateTime now,
    required DateTime? nextCameraCheckAt,
  }) {
    if (_segmentTracker.activeSegmentId != null) {
      return true;
    }
    final DateTime? nextCheck = nextCameraCheckAt;
    if (nextCheck == null) {
      return true;
    }
    return !now.isBefore(nextCheck);
  }

  Future<SegmentsRefreshResult> refreshSegmentsData({
    required bool showMetadataErrors,
    required LatLng? userLatLng,
  }) async {
    final metadataResult =
        await loadSegmentsMetadata(showErrors: showMetadataErrors);
    final bool reloaded = await _segmentTracker.reload(
      assetPath: AppConstants.pathToTollSegments,
    );

    _segmentTracker.updateIgnoredSegments(
      metadataResult.metadata.deactivatedSegmentIds,
    );

    await loadCameras(
      excludedSegmentIds: metadataResult.metadata.deactivatedSegmentIds,
    );

    SegmentTrackerEvent? seedEvent;
    if (reloaded && userLatLng != null) {
      seedEvent = _segmentTracker.handleLocationUpdate(
        current: userLatLng,
      );
    }

    return SegmentsRefreshResult(
      metadata: metadataResult.metadata,
      metadataError: metadataResult.errorMessage,
      reloaded: reloaded,
      seedEvent: seedEvent,
    );
  }

  Future<SegmentsSyncResult> performSync({
    required SupabaseClient? client,
    required Set<String> ignoredSegmentIds,
    required LatLng? userLatLng,
  }) async {
    if (client == null) {
      return SegmentsSyncResult(
        status: SyncResultStatus.missingClient,
        message: AppMessages.supabaseNotConfiguredForSync,
        seedEvent: null,
        reloaded: false,
      );
    }

    try {
      final syncResult = await _syncService.sync(client: client);
      final bool reloaded = await _segmentTracker.reload(
        assetPath: AppConstants.pathToTollSegments,
      );
      _segmentTracker.updateIgnoredSegments(ignoredSegmentIds);
      await loadCameras(excludedSegmentIds: ignoredSegmentIds);

      SegmentTrackerEvent? seedEvent;
      if (reloaded && userLatLng != null) {
        seedEvent = _segmentTracker.handleLocationUpdate(
          current: userLatLng,
        );
      }

      final message = _syncMessageService.buildSuccessMessage(syncResult);
      return SegmentsSyncResult(
        status: SyncResultStatus.success,
        message: message,
        seedEvent: seedEvent,
        reloaded: reloaded,
      );
    } on TollSegmentsSyncException catch (error) {
      return SegmentsSyncResult(
        status: SyncResultStatus.failure,
        message: error.message,
        seedEvent: null,
        reloaded: false,
      );
    } catch (error, stackTrace) {
      debugPrint('MapSegmentsService: unexpected sync error: $error\n$stackTrace');
      return SegmentsSyncResult(
        status: SyncResultStatus.failure,
        message: AppMessages.unexpectedSyncError,
        seedEvent: null,
        reloaded: false,
      );
    }
  }

  Future<void> runStartupSync(SupabaseClient? client) async {
    if (client == null) {
      debugPrint(
        'MapSegmentsService: skipping startup sync (no Supabase client).',
      );
      return;
    }

    try {
      await _syncService.sync(client: client);
    } on TollSegmentsSyncException catch (error) {
      debugPrint('MapSegmentsService: startup sync failed (${error.message}).');
    } catch (error, stackTrace) {
      debugPrint('MapSegmentsService: unexpected startup sync error: '
          '$error\n$stackTrace');
    }
  }
}
