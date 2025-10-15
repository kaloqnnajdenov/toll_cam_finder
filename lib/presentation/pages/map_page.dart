import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/speed_smoother.dart';
import 'package:toll_cam_finder/services/segment_guidance_controller.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';
import 'package:toll_cam_finder/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/services/toll_segments_sync_service.dart';
import '../../app/app_routes.dart';
import '../../app/localization/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/language_controller.dart';
import '../../services/location_service.dart';
import '../../services/notification_permission_service.dart';
import '../../services/permission_service.dart';
import '../../services/map/camera_polling_service.dart';
import '../../services/map/foreground_notification_service.dart';
import '../../services/map/map_sync_message_service.dart';
import '../../services/map/segment_ui_service.dart';
import '../../services/map/speed_service.dart';
import '../../services/map/upcoming_segment_cue_service.dart';
import '../../services/map/map_segments_service.dart';
import 'map/blue_dot_animator.dart';
import 'map/toll_camera_controller.dart';
import 'map/widgets/map_controls_panel.dart';
import 'map/widgets/map_fab_column.dart';
import 'map/widgets/segment_overlays.dart';

part 'map/map_options_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _mapFollowEpsilonDeg = 1e-6;
  // External services
  final MapController _mapController = MapController();
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();
  final NotificationPermissionService _notificationPermissionService =
      const NotificationPermissionService();
  final SegmentsMetadataService _metadataService = SegmentsMetadataService();
  final SpeedService _speedService = const SpeedService();
  final SegmentUiService _segmentUiService = SegmentUiService();
  late final ForegroundNotificationService _foregroundNotificationService =
      ForegroundNotificationService(segmentUiService: _segmentUiService);
  final UpcomingSegmentCueService _upcomingSegmentCueService =
      UpcomingSegmentCueService();
  final CameraPollingService _cameraPollingService =
      const CameraPollingService();
  final MapSyncMessageService _syncMessageService =
      const MapSyncMessageService();
  late final MapSegmentsService _segmentsService;
  // User + map state
  LatLng _center = AppConstants.initialCenter;
  LatLng? _userLatLng;
  bool _mapReady = false;
  bool _followUser = false;
  double _currentZoom = AppConstants.initialZoom;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<MapEvent>? _mapEvtSub;

  // Helpers
  late final BlueDotAnimator _blueDotAnimator;
  late final AverageSpeedController _avgCtrl;
  final SpeedSmoother _speedSmoother = SpeedSmoother();
  final Distance _distanceCalculator = const Distance();
  final TollCameraController _cameraController = TollCameraController();
  final SegmentTracker _segmentTracker = SegmentTracker(
    indexService: SegmentIndexService.instance,
  );
  late final SegmentGuidanceController _segmentGuidanceController;
  SegmentsMetadata _segmentsMetadata = const SegmentsMetadata();
  Future<void>? _metadataLoadFuture;

  SegmentTrackerDebugData _segmentDebugData =
      const SegmentTrackerDebugData.empty();

  double? _lastSegmentAvgKmh;
  double? _activeSegmentSpeedLimitKph;
  SegmentTrackerEvent? _lastSegmentEvent;
  LatLng? _avgLastLatLng;
  DateTime? _avgLastSampleAt;

  double? _speedKmh;
  String? _segmentProgressLabel;
  SegmentDebugPath? _activeSegmentDebugPath;
  bool _isSyncing = false;
  final TollSegmentsSyncService _syncService = TollSegmentsSyncService();
  DateTime? _nextCameraCheckAt;

  bool _useForegroundLocationService = false;
  bool _didRequestNotificationPermission = false;
  String? _lastNotificationStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _avgCtrl = context.read<AverageSpeedController>();
    _blueDotAnimator = BlueDotAnimator(vsync: this, onTick: _onBlueDotTick);
    _segmentGuidanceController = SegmentGuidanceController();
    _segmentsService = MapSegmentsService(
      metadataService: _metadataService,
      segmentTracker: _segmentTracker,
      cameraController: _cameraController,
      cameraPollingService: _cameraPollingService,
      syncService: _syncService,
      syncMessageService: _syncMessageService,
    );

    _metadataLoadFuture = _loadSegmentsMetadata();
    unawaited(_metadataLoadFuture!.then((_) => _loadCameras()));

    _mapEvtSub = _mapController.mapEventStream.listen(_onMapEvent);
    unawaited(_initLocation());
    unawaited(_initSegmentsIndex());
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _blueDotAnimator.dispose();
    _segmentTracker.dispose();
    unawaited(_segmentGuidanceController.dispose());
    unawaited(_upcomingSegmentCueService.dispose());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final bool shouldEnableForeground = state != AppLifecycleState.resumed;
    _setForegroundLocationMode(shouldEnableForeground);
    if (state == AppLifecycleState.resumed &&
        _didRequestNotificationPermission) {
      unawaited(_ensureNotificationPermission());
    }
  }

  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.ensureLocationPermission();
    if (!hasPermission) return;
    await _ensureNotificationPermission();
    if (_metadataLoadFuture != null) {
      await _metadataLoadFuture;
    }
    _speedSmoother.reset();
    final pos = await _locationService.getCurrentPosition();

    final firstKmh = _speedService.normalizeSpeed(pos.speed);
    _speedKmh = _speedSmoother.next(firstKmh);
    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
    final segEvent = _segmentTracker.handleLocationUpdate(current: firstFix);
    _applySegmentEvent(segEvent);
    _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
      position: firstFix,
    );

    if (mounted) setState(() {});

    if (_mapReady) {
      _mapController.move(_center, AppConstants.zoomWhenFocused);
      _currentZoom = AppConstants.zoomWhenFocused;
    }

    await _subscribeToPositionStream();
  }

  Future<void> _subscribeToPositionStream() async {
    await _posSub?.cancel();
    _posSub = _locationService
        .getPositionStream(
          useForegroundNotification: _useForegroundLocationService,
        )
        .listen(_handlePositionUpdate);
  }

  void _setForegroundLocationMode(bool enable) {
    if (_useForegroundLocationService == enable) {
      return;
    }

    _useForegroundLocationService = enable;
    _lastNotificationStatus = null;
    if (enable && _lastSegmentEvent != null) {
      unawaited(_updateForegroundNotification(_lastSegmentEvent!));
    }
    if (_posSub != null) {
      unawaited(_subscribeToPositionStream());
    }
  }

  Future<void> _ensureNotificationPermission() async {
    if (_didRequestNotificationPermission) {
      final bool enabled = await _notificationPermissionService
          .areNotificationsEnabled();
      if (enabled || !mounted) {
        return;
      }

      _showNotificationSettingsPrompt();
      return;
    }

    _didRequestNotificationPermission = true;
    final bool granted = await _notificationPermissionService
        .ensurePermissionGranted();
    if (granted || !mounted) {
      return;
    }

    _showNotificationSettingsPrompt();
  }

  void _showNotificationSettingsPrompt() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppMessages.backgroundTrackingNotificationRationale),
        action: SnackBarAction(
          label: AppMessages.openNotificationSettingsAction,
          onPressed: () {
            unawaited(_notificationPermissionService.openSettings());
          },
        ),
      ),
    );
  }

  void _handlePositionUpdate(Position position) {
    final DateTime now = DateTime.now();
    final shownKmh = _speedService.normalizeSpeed(position.speed);
    final smoothedKmh = _speedSmoother.next(shownKmh);
    final next = LatLng(position.latitude, position.longitude);
    if (_avgCtrl.isRunning) {
      _recordAverageProgress(position: next, timestamp: now);
    }
    _moveBlueDot(next);
    if (_segmentsService.shouldProcessSegmentUpdate(
      now: now,
      nextCameraCheckAt: _nextCameraCheckAt,
    )) {
      final segEvent = _segmentTracker.handleLocationUpdate(current: next);
      _applySegmentEvent(segEvent, now: now);
      _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
        position: next,
      );
    }

    if (!mounted) return;

    setState(() {
      _speedKmh = smoothedKmh;
    });
  }

  void _moveBlueDot(LatLng next) {
    final from = _blueDotAnimator.position ?? _userLatLng ?? _center;
    _userLatLng = next;
    _blueDotAnimator.animate(from: from, to: next);
  }

  void _recordAverageProgress({
    required LatLng position,
    required DateTime timestamp,
  }) {
    final LatLng? previousPosition = _avgLastLatLng;

    if (previousPosition == null || _avgLastSampleAt == null) {
      _avgLastLatLng = position;
      _avgLastSampleAt = timestamp;
      return;
    }

    final double distanceMeters = _distanceCalculator.as(
      LengthUnit.Meter,
      previousPosition,
      position,
    );

    final double sanitizedDistance =
        (distanceMeters.isFinite && distanceMeters > 0) ? distanceMeters : 0.0;

    _avgCtrl.recordProgress(
      distanceDeltaMeters: sanitizedDistance,
      timestamp: timestamp,
    );

    _avgLastLatLng = position;
    _avgLastSampleAt = timestamp;
  }

  void _applySegmentEvent(SegmentTrackerEvent segEvent, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    final SegmentDebugPath? activePath = _segmentUiService
        .resolveActiveSegmentPath(segEvent.debugData.candidatePaths, segEvent);

    double? exitAverage;

    if (segEvent.endedSegment || segEvent.completedSegmentLengthMeters != null) {
      final double? segmentLength = segEvent.completedSegmentLengthMeters;
      final Duration? elapsed = _avgCtrl.elapsed;
      final double computedAverage = (segmentLength != null && elapsed != null)
          ? _avgCtrl.avgSpeedDone(
              segmentLengthMeters: segmentLength,
              segmentDuration: elapsed,
            )
          : _avgCtrl.average;

      exitAverage = computedAverage;
      _lastSegmentAvgKmh = computedAverage.isFinite ? computedAverage : null;
      _avgCtrl.reset();
      _avgLastLatLng = null;
      _avgLastSampleAt = null;
    }

    if (segEvent.startedSegment) {
      _lastSegmentAvgKmh = null;
      _avgCtrl.start(startedAt: timestamp);
      _avgLastLatLng = _userLatLng;
      _avgLastSampleAt = timestamp;
    }

    if (segEvent.activeSegmentId == null) {
      _activeSegmentSpeedLimitKph = null;
    } else {
      _activeSegmentSpeedLimitKph = segEvent.activeSegmentSpeedLimitKph;
    }

    _segmentDebugData = segEvent.debugData;
    _activeSegmentDebugPath = activePath;
    _segmentProgressLabel = _segmentUiService.buildSegmentProgressLabel(
      event: segEvent,
      activePath: activePath,
      localizations: AppLocalizations.of(context),
      cueService: _upcomingSegmentCueService,
    );
    _lastSegmentEvent = segEvent;
    unawaited(_updateForegroundNotification(segEvent));

    unawaited(
      _segmentGuidanceController.handleUpdate(
        event: segEvent,
        activePath: activePath,
        averageKph: exitAverage ?? _avgCtrl.average,
        speedLimitKph: segEvent.activeSegmentSpeedLimitKph,
        now: timestamp,
        averageStartedAt: _avgCtrl.startedAt,
      ),
    );
  }

  void _resetSegmentState() {
    _segmentDebugData = const SegmentTrackerDebugData.empty();
    _segmentProgressLabel = null;
    _lastSegmentAvgKmh = null;
    _activeSegmentSpeedLimitKph = null;
    _avgCtrl.reset();
    _avgLastLatLng = null;
    _avgLastSampleAt = null;
    _activeSegmentDebugPath = null;
    _nextCameraCheckAt = null;
    _upcomingSegmentCueService.reset();
    _lastSegmentEvent = null;
    _lastNotificationStatus = null;
    unawaited(_segmentGuidanceController.reset());
  }

  Future<void> _updateForegroundNotification(SegmentTrackerEvent event) async {
    if (!_useForegroundLocationService) {
      return;
    }

    final String status = _foregroundNotificationService.buildStatus(
      event: event,
      avgController: _avgCtrl,
    );
    if (status == _lastNotificationStatus) {
      return;
    }

    _lastNotificationStatus = status;
    await _notificationPermissionService.updateForegroundNotification(
      title: AppConstants.backgroundNotificationTitle,
      text: status,
      iconName: AppConstants.backgroundNotificationIconName,
      iconType: AppConstants.backgroundNotificationIconType,
    );
  }

  void _onMapEvent(MapEvent evt) {
    _currentZoom = evt.camera.zoom;
    final bool external = evt.source != MapEventSource.mapController;

    bool shouldSetState = false;

    if (external && _followUser) {
      _followUser = false;
      shouldSetState = true;
    }

    if (shouldSetState && mounted) {
      setState(() {});
    }

    _updateVisibleCameras();
  }

  // ------------------ reset view button ------------------
  void _onMapReady() {
    _mapReady = true;
    if (_userLatLng != null) {
      _mapController.move(_userLatLng!, AppConstants.zoomWhenFocused);
      _currentZoom = AppConstants.zoomWhenFocused;
    }
    _updateVisibleCameras();
  }

  void _onResetView() {
    final target = _blueDotAnimator.position ?? _userLatLng ?? _center;
    setState(() => _followUser = true);
    final zoom = _currentZoom < AppConstants.zoomWhenFocused
        ? AppConstants.zoomWhenFocused
        : _currentZoom;
    _mapController.move(target, zoom);
  }

  void _onBlueDotTick() {
    if (_followUser && _mapReady) {
      final target = _blueDotAnimator.position;
      if (target != null) {
        _updateFollowCamera(target);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _updateFollowCamera(LatLng target) {
    if (!_mapReady) return;

    late final MapCamera camera;
    try {
      camera = _mapController.camera;
    } catch (_) {
      return;
    }

    final currentCenter = camera.center;
    final latDiff = (currentCenter.latitude - target.latitude).abs();
    final lngDiff = (currentCenter.longitude - target.longitude).abs();
    if (latDiff <= _mapFollowEpsilonDeg && lngDiff <= _mapFollowEpsilonDeg) {
      return;
    }

    _mapController.move(target, camera.zoom);
  }

  Future<void> _loadSegmentsMetadata({bool showErrors = false}) async {
    final result = await _segmentsService.loadSegmentsMetadata(
      showErrors: showErrors,
    );
    _segmentsMetadata = result.metadata;
    if (!mounted) {
      return;
    }
    if (showErrors && result.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
    }
    setState(() {});
  }

  Future<void> _loadCameras() async {
    await _segmentsService.loadCameras(
      excludedSegmentIds: _segmentsMetadata.deactivatedSegmentIds,
    );
    if (!mounted) return;
    _nextCameraCheckAt = null;
    _updateVisibleCameras();
  }

  void _updateVisibleCameras() {
    LatLngBounds? bounds;
    if (_mapReady) {
      try {
        bounds = _mapController.camera.visibleBounds;
      } catch (_) {
        bounds = null;
      }
    }
    if (!mounted) return;

    setState(() {
      _cameraController.updateVisible(bounds: bounds);
    });
  }

  Future<void> _initSegmentsIndex() async {
    await _runStartupSync();
    final ready = await _segmentTracker.initialise(
      assetPath: AppConstants.pathToTollSegments,
    );
    if (!mounted || !ready) return;

    if (_metadataLoadFuture != null) {
      try {
        await _metadataLoadFuture;
      } catch (_) {
        // Metadata failures are reported separately.
      }
    }

    _resetSegmentState();
    if (_userLatLng != null) {
      final seedEvent = _segmentTracker.handleLocationUpdate(
        current: _userLatLng!,
      );
      _applySegmentEvent(seedEvent);
      _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
        position: _userLatLng!,
      );
    }

    setState(() {});
  }

  Future<void> _runStartupSync() async {
    if (_isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    final client = context.read<AuthController>().client;
    try {
      await _segmentsService.runStartupSync(client);
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markerPoint = _blueDotAnimator.position ?? _userLatLng;
    final cameraState = _cameraController.state;

    return Scaffold(
      endDrawer: _buildOptionsDrawer(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _currentZoom,
              onMapReady: _onMapReady,
            ),
            children: [
              const BaseTileLayer(),

              BlueDotMarker(point: markerPoint),

              if (kDebugMode && _segmentDebugData.querySquare.isNotEmpty)
                QuerySquareOverlay(points: _segmentDebugData.querySquare),
              if (kDebugMode && _segmentDebugData.boundingCandidates.isNotEmpty)
                CandidateBoundsOverlay(
                  candidates: _segmentDebugData.boundingCandidates,
                ),
              if (kDebugMode && _segmentDebugData.candidatePaths.isNotEmpty)
                SegmentPolylineOverlay(
                  paths: _segmentDebugData.candidatePaths,
                  startGeofenceRadius: _segmentDebugData.startGeofenceRadius,
                  endGeofenceRadius: _segmentDebugData.endGeofenceRadius,
                ),
              TollCamerasOverlay(cameras: cameraState),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: MapControlsPanel(
                speedKmh: _speedKmh,
                avgController: _avgCtrl,
                hasActiveSegment: _segmentTracker.activeSegmentId != null,
                lastSegmentAvgKmh: _lastSegmentAvgKmh,
                segmentSpeedLimitKph: _activeSegmentSpeedLimitKph,
                segmentProgressLabel: _segmentProgressLabel,
                segmentDebugPath: _activeSegmentDebugPath,
                showDebugBadge: _segmentTracker.isReady,
                segmentCount: _segmentDebugData.candidateCount,
                segmentRadiusMeters: AppConstants.candidateRadiusMeters,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: Builder(
                  builder: (context) {
                    return Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: const Icon(Icons.menu, color: Colors.white),
                        tooltip: AppLocalizations.of(context).openMenu,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: MapFabColumn(
        followUser: _followUser,
        onResetView: _onResetView,
        avgController: _avgCtrl,
      ),
    );
  }
}
