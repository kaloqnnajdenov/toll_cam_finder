import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/core/app_colors.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/map/domain/utils/speed_smoother.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/features/map/services/camera_polling_service.dart';
import 'package:toll_cam_finder/features/map/services/foreground_notification_service.dart';
import 'package:toll_cam_finder/features/map/services/map_segments_service.dart';
import 'package:toll_cam_finder/features/map/services/map_sync_message_service.dart';
import 'package:toll_cam_finder/features/map/services/osm_speed_limit_service.dart';
import 'package:toll_cam_finder/features/map/services/segment_ui_service.dart';
import 'package:toll_cam_finder/features/map/services/speed_service.dart';
import 'package:toll_cam_finder/features/map/services/upcoming_segment_cue_service.dart';
import 'package:toll_cam_finder/features/segments/domain/index/segment_index_service.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_guidance_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/features/segments/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_sync_service.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'package:toll_cam_finder/shared/services/location_service.dart';
import 'package:toll_cam_finder/shared/services/notification_permission_service.dart';
import 'package:toll_cam_finder/shared/services/permission_service.dart';
import 'map/blue_dot_animator.dart';
import 'map/toll_camera_controller.dart';
import 'map/widgets/map_controls_panel.dart';
import 'map/widgets/map_fab_column.dart';
import 'map/widgets/segment_overlays.dart';
import 'map/widgets/speed_limit_sign.dart';

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
  late final GuidanceAudioController _audioController;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  GuidanceAudioPolicy _audioPolicy = const GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );
  // User + map state
  LatLng _center = AppConstants.initialCenter;
  LatLng? _userLatLng;
  bool _mapReady = false;
  bool _followUser = false;
  bool _followHeading = false;
  bool _showHeadingFab = true;
  bool _showRecenterFab = true;
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

  final OsmSpeedLimitService _osmSpeedLimitService = OsmSpeedLimitService();
  LatLng? _lastSpeedLimitQueryLocation;
  DateTime? _lastSpeedLimitQueryAt;
  String? _osmSpeedLimitKph;

  SegmentTrackerDebugData _segmentDebugData =
      const SegmentTrackerDebugData.empty();

  double? _lastSegmentAvgKmh;
  double? _activeSegmentSpeedLimitKph;
  double? _nearestSegmentStartMeters;
  SegmentTrackerEvent? _lastSegmentEvent;
  LatLng? _avgLastLatLng;
  DateTime? _avgLastSampleAt;

  double? _speedKmh;
  String? _segmentProgressLabel;
  SegmentDebugPath? _activeSegmentDebugPath;
  bool _isSyncing = false;
  final TollSegmentsSyncService _syncService = TollSegmentsSyncService();
  DateTime? _nextCameraCheckAt;

  double? _userHeading;

  final GlobalKey _controlsPanelKey = GlobalKey();
  double _controlsPanelHeight = 0;

  bool _useForegroundLocationService = false;
  bool _didRequestNotificationPermission = false;
  String? _lastNotificationStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    _avgCtrl = context.read<AverageSpeedController>();
    _blueDotAnimator = BlueDotAnimator(vsync: this, onTick: _onBlueDotTick);
    _segmentGuidanceController = SegmentGuidanceController();
    _audioController = context.read<GuidanceAudioController>();
    _audioController.addListener(_updateAudioPolicy);
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
    _updateAudioPolicy();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _blueDotAnimator.dispose();
    _segmentTracker.dispose();
    unawaited(_segmentGuidanceController.dispose());
    unawaited(_upcomingSegmentCueService.dispose());
    _osmSpeedLimitService.dispose();
    _audioController.removeListener(_updateAudioPolicy);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleState = state;
    final bool shouldEnableForeground = state != AppLifecycleState.resumed;
    _setForegroundLocationMode(shouldEnableForeground);
    if (state == AppLifecycleState.resumed &&
        _didRequestNotificationPermission) {
      unawaited(_ensureNotificationPermission());
    }
    _updateAudioPolicy();
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
    _updateHeading(pos.heading);
    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
    final segEvent = _segmentTracker.handleLocationUpdate(current: firstFix);
    _applySegmentEvent(segEvent);
    _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
      position: firstFix,
    );

    _maybeFetchSpeedLimit(firstFix);

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

  void _updateAudioPolicy() {
    final GuidanceAudioPolicy newPolicy = _audioController.policyFor(
      _appLifecycleState,
    );
    if (newPolicy == _audioPolicy) {
      return;
    }
    _audioPolicy = newPolicy;
    _segmentGuidanceController.updateAudioPolicy(newPolicy);
    _upcomingSegmentCueService.updateAudioPolicy(newPolicy);
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
    _updateHeading(position.heading);
    if (_avgCtrl.isRunning) {
      _recordAverageProgress(position: next, timestamp: now);
    }
    _moveBlueDot(next);
    _maybeFetchSpeedLimit(next);
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

  void _updateHeading(double heading) {
    if (!heading.isFinite || heading < 0) {
      return;
    }

    _userHeading = heading % 360;
    if (_followHeading) {
      _applyHeadingRotation();
    }
  }

  void _moveBlueDot(LatLng next) {
    final from = _blueDotAnimator.position ?? _userLatLng ?? _center;
    _userLatLng = next;
    _blueDotAnimator.animate(from: from, to: next);
  }

  void _maybeFetchSpeedLimit(LatLng position) {
    final now = DateTime.now();
    final lastLocation = _lastSpeedLimitQueryLocation;
    final lastQueryAt = _lastSpeedLimitQueryAt;

    if (lastLocation != null) {
      final distanceMoved = _distanceCalculator.as(
        LengthUnit.Meter,
        lastLocation,
        position,
      );
      const double minDistanceMeters = 30;
      const Duration minInterval = Duration(seconds: 20);
      if (distanceMoved < minDistanceMeters &&
          lastQueryAt != null &&
          now.difference(lastQueryAt) < minInterval) {
        return;
      }
    }

    _lastSpeedLimitQueryLocation = position;
    _lastSpeedLimitQueryAt = now;
    unawaited(_loadSpeedLimit(position));
  }

  Future<void> _loadSpeedLimit(LatLng position) async {
    try {
      final result = await _osmSpeedLimitService.fetchSpeedLimit(position);
      if (!mounted) return;

      setState(() {
        _osmSpeedLimitKph = result;
      });
    } catch (_) {
      // Ignore network errors and keep the previous reading.
    }
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

    if (segEvent.endedSegment ||
        segEvent.completedSegmentLengthMeters != null) {
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
    _nearestSegmentStartMeters = segEvent.activeSegmentId != null
        ? 0
        : _segmentUiService.nearestUpcomingSegmentDistance(
            segEvent.debugData.candidatePaths,
          );
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
    _nearestSegmentStartMeters = null;
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

    if (external && _followHeading) {
      _followHeading = false;
      shouldSetState = true;
    }

    if (external && (!_showHeadingFab || !_showRecenterFab)) {
      _showHeadingFab = true;
      _showRecenterFab = true;
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
    if (_followHeading) {
      _applyHeadingRotation();
    }
    _updateVisibleCameras();
  }

  void _onResetView() {
    final target = _blueDotAnimator.position ?? _userLatLng ?? _center;
    setState(() {
      _followUser = true;
      _showRecenterFab = false;
    });
    final zoom = _currentZoom < AppConstants.zoomWhenFocused
        ? AppConstants.zoomWhenFocused
        : _currentZoom;
    _mapController.move(target, zoom);
    if (_followHeading) {
      _applyHeadingRotation();
    }
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

  void _applyHeadingRotation() {
    if (!_mapReady) {
      return;
    }

    final heading = _userHeading;
    if (heading == null) {
      return;
    }

    final double normalizedHeading = heading % 360;
    _mapController.rotate(-normalizedHeading);
  }

  void _toggleFollowHeading() {
    if (_followHeading) {
      setState(() {
        _followHeading = false;
        _showHeadingFab = false;
      });
      if (_mapReady) {
        _mapController.rotate(0);
      }
      return;
    }

    setState(() {
      _followHeading = true;
      _followUser = true;
      _showHeadingFab = false;
    });
    if (_userHeading != null) {
      _applyHeadingRotation();
    }
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

  void _updateControlsPanelHeight() {
    final BuildContext? context = _controlsPanelKey.currentContext;
    final double newHeight = context?.size?.height ?? 0;

    if (!mounted) {
      return;
    }

    if ((newHeight - _controlsPanelHeight).abs() > 0.5) {
      setState(() {
        _controlsPanelHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final markerPoint = _blueDotAnimator.position ?? _userLatLng;
    final cameraState = _cameraController.state;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    final Widget mapContent = Stack(
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
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: SpeedLimitSign(
                speedLimit: _osmSpeedLimitKph,
                currentSpeedKmh: _speedKmh,
              ),
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
                  final ScaffoldState? scaffoldState = Scaffold.maybeOf(context);
                  final bool isDrawerOpen = scaffoldState?.isEndDrawerOpen ?? false;
                  final theme = Theme.of(context);
                  final palette = AppColors.of(context);
                  final bool isDark = theme.brightness == Brightness.dark;
                  final Color backgroundColor = isDrawerOpen
                      ? palette.primary
                      : palette.surface.withOpacity(isDark ? 0.7 : 0.92);
                  final Color iconColor = isDrawerOpen ? Colors.white : palette.onSurface;
                  final BorderSide borderSide = BorderSide(
                    color: isDrawerOpen
                        ? Colors.transparent
                        : palette.divider.withOpacity(isDark ? 1 : 0.7),
                    width: 1,
                  );

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: backgroundColor,
                      shape: CircleBorder(side: borderSide),
                      child: IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: Icon(Icons.menu, color: iconColor),
                        tooltip: AppLocalizations.of(context).openMenu,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );

    final Widget mapFab = SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(
            right: 16,
            bottom: isLandscape ? 0 : _controlsPanelHeight,
          ),
          child: MapFabColumn(
            followUser: _followUser,
            followHeading: _followHeading,
            headingDegrees: _userHeading,
            onToggleHeading: _toggleFollowHeading,
            onResetView: _onResetView,
            avgController: _avgCtrl,
            showHeadingButton: _showHeadingFab,
            showRecenterButton: _showRecenterFab,
          ),
        ),
      ),
    );

    final Widget controlsPanel = MapControlsPanel(
      key: _controlsPanelKey,
      placement: isLandscape
          ? MapControlsPlacement.left
          : MapControlsPlacement.bottom,
      speedKmh: _speedKmh,
      avgController: _avgCtrl,
      hasActiveSegment: _segmentTracker.activeSegmentId != null,
      segmentSpeedLimitKph: _activeSegmentSpeedLimitKph,
      segmentDebugPath: _activeSegmentDebugPath,
      distanceToSegmentStartMeters: _nearestSegmentStartMeters,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControlsPanelHeight();
    });

    final List<Widget> stackChildren = [
      Positioned.fill(child: mapContent),
      if (isLandscape)
        Align(alignment: Alignment.centerLeft, child: controlsPanel)
      else
        Positioned(left: 0, right: 0, bottom: 0, child: controlsPanel),
      mapFab,
    ];

    return Scaffold(
      endDrawer: _buildOptionsDrawer(),
      body: Stack(fit: StackFit.expand, children: stackChildren),
    );
  }
}
