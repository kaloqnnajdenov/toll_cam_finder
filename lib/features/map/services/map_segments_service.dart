import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/toll_camera_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/weigh_station_controller.dart';
import 'package:toll_cam_finder/features/map/services/camera_polling_service.dart';
import 'package:toll_cam_finder/features/map/services/map_sync_message_service.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/features/segments/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_sync_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station_vote.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/remote_weigh_station_votes_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_sync_service.dart';

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
    required WeighStationController weighStationController,
    required WeighStationsSyncService weighStationsSyncService,
    RemoteWeighStationVotesService? weighStationVotesService,
    required TollSegmentsSyncService syncService,
    required MapSyncMessageService syncMessageService,
  })  : _metadataService = metadataService,
        _segmentTracker = segmentTracker,
        _cameraController = cameraController,
        _weighStationController = weighStationController,
        _cameraPollingService = cameraPollingService,
        _syncService = syncService,
        _weighStationsSyncService = weighStationsSyncService,
        _weighStationVotesService =
            weighStationVotesService ?? RemoteWeighStationVotesService(),
        _syncMessageService = syncMessageService;

  final SegmentsMetadataService _metadataService;
  final SegmentTracker _segmentTracker;
  final TollCameraController _cameraController;
  final WeighStationController _weighStationController;
  final CameraPollingService _cameraPollingService;
  final TollSegmentsSyncService _syncService;
  final WeighStationsSyncService _weighStationsSyncService;
  final RemoteWeighStationVotesService _weighStationVotesService;
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

  Future<void> loadWeighStations({LatLngBounds? bounds}) async {
    await _weighStationController.loadFromAsset(
      AppConstants.pathToWeighStations,
      bounds: bounds,
    );
  }

  void updateVisibleWeighStations({LatLngBounds? bounds}) {
    _weighStationController.updateVisible(bounds: bounds);
  }

  WeighStationsState get weighStationsState => _weighStationController.state;

  WeighStationVoteResult registerWeighStationVote({
    required String stationId,
    required bool isUpvote,
    SupabaseClient? client,
    String? userId,
  }) {
    final result = _weighStationController.registerVote(
      stationId: stationId,
      isUpvote: isUpvote,
    );
    if (client != null && userId != null && userId.trim().isNotEmpty) {
      unawaited(_submitWeighStationVote(
        client: client,
        stationId: stationId,
        votes: result.votes,
      ));
    }
    return result;
  }

  NearestWeighStation? nearestWeighStation(LatLng point) =>
      _weighStationController.nearestStation(point);

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
    SupabaseClient? client,
    String? currentUserId,
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
    await loadWeighStations();
    await refreshWeighStationVotes(
      client: client,
      userId: currentUserId,
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
    String? currentUserId,
  }) async {
    if (client == null) {
      return SegmentsSyncResult(
        status: SyncResultStatus.missingClient,
        message: AppMessages.supabaseNotConfiguredForSync,
        seedEvent: null,
        reloaded: false,
      );
    }

    SegmentTrackerEvent? seedEvent;
    bool reloaded = false;

    try {
      final syncResult = await _syncService.sync(client: client);
      reloaded = await _segmentTracker.reload(
        assetPath: AppConstants.pathToTollSegments,
      );
      _segmentTracker.updateIgnoredSegments(ignoredSegmentIds);
      await loadCameras(excludedSegmentIds: ignoredSegmentIds);
      await loadWeighStations();

      if (reloaded && userLatLng != null) {
        seedEvent = _segmentTracker.handleLocationUpdate(
          current: userLatLng,
        );
      }

      await _weighStationsSyncService.sync(client: client);
      await loadWeighStations();
      await refreshWeighStationVotes(
        client: client,
        userId: currentUserId,
      );

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
    } on WeighStationsSyncException catch (error) {
      return SegmentsSyncResult(
        status: SyncResultStatus.failure,
        message: error.message,
        seedEvent: null,
        reloaded: reloaded,
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

  Future<void> refreshWeighStationVotes({
    required SupabaseClient? client,
    required String? userId,
  }) async {
    if (client == null) {
      return;
    }

    try {
      final snapshot = await _weighStationVotesService.fetchVotes(
        client: client,
        currentUserId: userId,
      );
      _weighStationController.applyRemoteVotes(
        votes: snapshot.votes,
        userVotes: snapshot.userVotes,
      );
    } on RemoteWeighStationVotesException catch (error) {
      debugPrint(
        'MapSegmentsService: failed to download weigh station votes '
        '(${error.message}).',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'MapSegmentsService: unexpected error downloading weigh station votes: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _submitWeighStationVote({
    required SupabaseClient client,
    required String stationId,
    required WeighStationVotes votes,
  }) async {
    try {
      await _weighStationVotesService.applyVote(
        client: client,
        stationId: stationId,
        votes: votes,
      );
    } on RemoteWeighStationVotesException catch (error) {
      debugPrint(
        'MapSegmentsService: failed to submit weigh station vote '
        '(${error.message}).',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'MapSegmentsService: unexpected error submitting weigh station vote: '
        '$error\n$stackTrace',
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
