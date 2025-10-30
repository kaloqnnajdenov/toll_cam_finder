import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/segments_only_mode_controller.dart';
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
import 'package:toll_cam_finder/features/segments/domain/controllers/current_segment_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_guidance_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/features/segments/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_sync_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station_vote.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'package:toll_cam_finder/shared/services/location_service.dart';
import 'package:toll_cam_finder/shared/services/notification_permission_service.dart';
import 'package:toll_cam_finder/shared/services/permission_service.dart';
import 'map/blue_dot_animator.dart';
import 'map/toll_camera_controller.dart';
import 'map/weigh_station_controller.dart';
import 'map/widgets/map_controls_panel.dart';
import 'map/widgets/map_fab_column.dart';
import 'map/widgets/segment_handover_banner.dart';
import 'map/widgets/segment_overlays.dart';
import 'map/widgets/speed_limit_sign.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/weigh_stations_overlay.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/weigh_station_feedback_sheet.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_station_alert_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_sync_service.dart';

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
  final WeighStationAlertService _weighStationAlertService =
      WeighStationAlertService();
  final CameraPollingService _cameraPollingService =
      const CameraPollingService();
  final MapSyncMessageService _syncMessageService =
      const MapSyncMessageService();
  final Connectivity _connectivity = Connectivity();
  late final MapSegmentsService _segmentsService;
  late final GuidanceAudioController _audioController;
  late final LanguageController _languageController;
  late final SegmentsOnlyModeController _segmentsOnlyModeController;
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
  double _currentZoom = AppConstants.initialZoom;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<MapEvent>? _mapEvtSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _speedIdleResetTimer;

  // Helpers
  late final BlueDotAnimator _blueDotAnimator;
  late final CurrentSegmentController _currentSegmentController;
  final SpeedSmoother _speedSmoother = SpeedSmoother();
  final Distance _distanceCalculator = const Distance();
  final TollCameraController _cameraController = TollCameraController();
  final WeighStationController _weighStationController =
      WeighStationController();
  final SegmentTracker _segmentTracker = SegmentTracker(
    indexService: SegmentIndexService.instance,
  );
  List<Polyline> _visibleSegmentPolylines = const [];
  Map<String, String> _visibleSegmentSignatures = const {};
  late final SegmentGuidanceController _segmentGuidanceController;
  SegmentsMetadata _segmentsMetadata = const SegmentsMetadata();
  Future<void>? _metadataLoadFuture;

  final OsmSpeedLimitService _osmSpeedLimitService = OsmSpeedLimitService();
  String? _osmSpeedLimitKph;
  LatLng? _lastSpeedLimitQueryLocation;
  Timer? _speedLimitPollTimer;
  bool _isSpeedLimitRequestInFlight = false;
  bool _simpleModePageOpen = false;
  Timer? _offlineRedirectTimer;
  Timer? _osmUnavailableRedirectTimer;
  bool _hasConnectivity = true;
  bool _isOsmServiceAvailable = true;

  double? _speedKmh;
  bool _isSyncing = false;
  final TollSegmentsSyncService _syncService = TollSegmentsSyncService();
  final WeighStationsSyncService _weighStationsSyncService =
      WeighStationsSyncService();
  DateTime? _nextCameraCheckAt;

  double? _userHeading;

  final GlobalKey _controlsPanelKey = GlobalKey();
  double _controlsPanelHeight = 0;

  bool _useForegroundLocationService = false;
  bool _didRequestNotificationPermission = false;
  String? _lastNotificationStatus;

  AverageSpeedController get _avgCtrl =>
      _currentSegmentController.averageController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    _currentSegmentController = context.read<CurrentSegmentController>();
    _blueDotAnimator = BlueDotAnimator(vsync: this, onTick: _onBlueDotTick);
    _segmentGuidanceController = SegmentGuidanceController();
    _audioController = context.read<GuidanceAudioController>();
    _languageController = context.read<LanguageController>();
    _segmentsOnlyModeController = context.read<SegmentsOnlyModeController>();
    unawaited(_initConnectivityMonitoring());
    _audioController.addListener(_updateAudioPolicy);
    _languageController.addListener(_handleLanguageChange);
    _segmentsService = MapSegmentsService(
      metadataService: _metadataService,
      segmentTracker: _segmentTracker,
      cameraController: _cameraController,
      cameraPollingService: _cameraPollingService,
      weighStationController: _weighStationController,
      weighStationsSyncService: _weighStationsSyncService,
      syncService: _syncService,
      syncMessageService: _syncMessageService,
    );

    _metadataLoadFuture = _loadSegmentsMetadata();
    unawaited(
      _metadataLoadFuture!.then((_) async {
        await _loadCameras();
        await _loadWeighStations();
      }),
    );

    _handleLanguageChange();

    _mapEvtSub = _mapController.mapEventStream.listen(_onMapEvent);
    unawaited(_initLocation());
    unawaited(_initSegmentsIndex());
    _updateAudioPolicy();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _connectivitySub?.cancel();
    _speedIdleResetTimer?.cancel();
    _speedLimitPollTimer?.cancel();
    _blueDotAnimator.dispose();
    _segmentTracker.dispose();
    unawaited(_segmentGuidanceController.dispose());
    unawaited(_upcomingSegmentCueService.dispose());
    unawaited(_weighStationAlertService.dispose());
    _osmSpeedLimitService.dispose();
    _audioController.removeListener(_updateAudioPolicy);
    _languageController.removeListener(_handleLanguageChange);
    _offlineRedirectTimer?.cancel();
    _osmUnavailableRedirectTimer?.cancel();
    _segmentsOnlyModeController.exitMode();
    _currentSegmentController.reset();
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
    _scheduleSpeedIdleReset();
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

    _updateSegmentsOnlyMetrics();

    if (_mapReady) {
      _mapController.move(_center, AppConstants.zoomWhenFocused);
      _currentZoom = AppConstants.zoomWhenFocused;
    }
    await _subscribeToPositionStream();
  }

  Future<void> _initConnectivityMonitoring() async {
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    _onConnectivityChanged(results);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final bool isConnected =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    if (isConnected == _hasConnectivity) {
      return;
    }

    _hasConnectivity = isConnected;

    if (!isConnected) {
      _segmentsOnlyModeController.enterMode(SegmentsOnlyModeReason.offline);
      _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason.offline);
    } else {
      _cancelSegmentsOnlyRedirectTimer(SegmentsOnlyModeReason.offline);
      if (_segmentsOnlyModeController.reason ==
          SegmentsOnlyModeReason.offline) {
        _segmentsOnlyModeController.exitMode();
        if (_simpleModePageOpen) {
          unawaited(_closeSimpleModePageIfOpen());
        }
      }
    }
  }

  Future<void> _subscribeToPositionStream() async {
    await _posSub?.cancel();
    _posSub = _locationService
        .getPositionStream(
          useForegroundNotification: _useForegroundLocationService,
        )
        .listen(_handlePositionUpdate);
  }

  void _handleLanguageChange() {
    final String languageCode = _languageController.locale.languageCode;
    _segmentGuidanceController.updateLanguage(languageCode);
    _upcomingSegmentCueService.updateLanguage(languageCode);
    _weighStationAlertService.updateLanguage(languageCode);
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
    _weighStationAlertService.updateAudioPolicy(newPolicy);
  }

  void _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason reason) {
    if (reason == SegmentsOnlyModeReason.manual) {
      return;
    }

    final Timer? existing = _redirectTimerFor(reason);
    if (existing?.isActive ?? false) {
      return;
    }

    final Timer timer = Timer(const Duration(seconds: 3), () {
      _setRedirectTimer(reason, null);
      if (!mounted) {
        return;
      }
      if (_segmentsOnlyModeController.reason != reason) {
        return;
      }
      unawaited(_openSimpleModePage(reason));
    });

    _setRedirectTimer(reason, timer);
  }

  void _cancelSegmentsOnlyRedirectTimer(SegmentsOnlyModeReason reason) {
    final Timer? existing = _redirectTimerFor(reason);
    existing?.cancel();
    _setRedirectTimer(reason, null);
  }

  Timer? _redirectTimerFor(SegmentsOnlyModeReason reason) {
    switch (reason) {
      case SegmentsOnlyModeReason.offline:
        return _offlineRedirectTimer;
      case SegmentsOnlyModeReason.osmUnavailable:
        return _osmUnavailableRedirectTimer;
      case SegmentsOnlyModeReason.manual:
        return null;
    }
  }

  void _setRedirectTimer(SegmentsOnlyModeReason reason, Timer? timer) {
    switch (reason) {
      case SegmentsOnlyModeReason.offline:
        _offlineRedirectTimer = timer;
        break;
      case SegmentsOnlyModeReason.osmUnavailable:
        _osmUnavailableRedirectTimer = timer;
        break;
      case SegmentsOnlyModeReason.manual:
        break;
    }
  }

  void _setForegroundLocationMode(bool enable) {
    if (_useForegroundLocationService == enable) {
      return;
    }

    _useForegroundLocationService = enable;
    _lastNotificationStatus = null;
    final SegmentTrackerEvent? lastEvent = _currentSegmentController.lastEvent;
    if (enable && lastEvent != null) {
      unawaited(_updateForegroundNotification(lastEvent));
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
    _scheduleSpeedIdleReset();
    final shownKmh = _speedService.normalizeSpeed(position.speed);
    final smoothedKmh = _speedSmoother.next(shownKmh);
    final next = LatLng(position.latitude, position.longitude);
    _updateHeading(position.heading);
    _currentSegmentController.recordProgress(position: next, timestamp: now);
    _moveBlueDot(next);
    _maybeFetchSpeedLimit(next);
    final nearestWeigh = _segmentsService.nearestWeighStation(next);
    _weighStationAlertService.updateDistance(
      stationId: nearestWeigh?.marker.id,
      distanceMeters: nearestWeigh?.distanceMeters,
      approachMessage: AppLocalizations.of(context).weighStationApproachAlert,
    );
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

    _updateSegmentsOnlyMetrics();
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

  Duration _currentSpeedLimitPollInterval() {
    return _osmSpeedLimitKph == null
        ? const Duration(seconds: 1)
        : const Duration(seconds: 3);
  }

  void _maybeFetchSpeedLimit(LatLng position) {
    _lastSpeedLimitQueryLocation = position;
    final bool hasActiveTimer = _speedLimitPollTimer?.isActive ?? false;
    if (_isSpeedLimitRequestInFlight || hasActiveTimer) {
      return;
    }
    _speedLimitPollTimer = Timer(Duration.zero, _pollSpeedLimit);
  }

  void _scheduleNextSpeedLimitPoll() {
    if (!mounted) {
      return;
    }
    _speedLimitPollTimer?.cancel();
    _speedLimitPollTimer =
        Timer(_currentSpeedLimitPollInterval(), _pollSpeedLimit);
  }

  Future<void> _pollSpeedLimit() async {
    _speedLimitPollTimer?.cancel();
    _speedLimitPollTimer = null;
    if (_isSpeedLimitRequestInFlight) {
      _scheduleNextSpeedLimitPoll();
      return;
    }

    final LatLng? location = _lastSpeedLimitQueryLocation;
    if (location == null) {
      return;
    }

    _isSpeedLimitRequestInFlight = true;
    try {
      final result = await _osmSpeedLimitService.fetchSpeedLimit(location);
      if (!mounted) return;

      final bool shouldUpdateLimit =
          result != null && result != _osmSpeedLimitKph;
      final bool shouldUpdateAvailability = !_isOsmServiceAvailable;
      if (shouldUpdateLimit || shouldUpdateAvailability) {
        setState(() {
          _isOsmServiceAvailable = true;
          if (shouldUpdateLimit) {
            _osmSpeedLimitKph = result;
          }
        });
      } else {
        _isOsmServiceAvailable = true;
      }
      _cancelSegmentsOnlyRedirectTimer(SegmentsOnlyModeReason.osmUnavailable);
      if (_segmentsOnlyModeController.reason ==
          SegmentsOnlyModeReason.osmUnavailable) {
        _segmentsOnlyModeController.exitMode();
        if (_simpleModePageOpen) {
          unawaited(_closeSimpleModePageIfOpen());
        }
      }
    } catch (_) {
      if (!mounted) return;

      _isOsmServiceAvailable = false;
      _segmentsOnlyModeController.enterMode(
        SegmentsOnlyModeReason.osmUnavailable,
      );
      _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason.osmUnavailable);
    } finally {
      _isSpeedLimitRequestInFlight = false;
      _scheduleNextSpeedLimitPoll();
    }
  }

  void _scheduleSpeedIdleReset() {
    _speedIdleResetTimer?.cancel();
    _speedIdleResetTimer = Timer(
      const Duration(milliseconds: AppConstants.speedIdleResetTimeoutMs),
      _handleSpeedIdleTimeout,
    );
  }

  void _handleSpeedIdleTimeout() {
    _speedIdleResetTimer = null;
    if (!mounted) {
      return;
    }
    _speedSmoother.reset();
    if ((_speedKmh ?? 0) <= 0) {
      return;
    }
    setState(() {
      _speedKmh = 0.0;
    });
    _updateSegmentsOnlyMetrics();
  }

  void _applySegmentEvent(SegmentTrackerEvent segEvent, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    final SegmentDebugPath? activePath = _segmentUiService
        .resolveActiveSegmentPath(segEvent.debugData.candidatePaths, segEvent);

    final double? nearestStart = segEvent.activeSegmentId != null
        ? 0
        : _segmentUiService.nearestUpcomingSegmentDistance(
            segEvent.debugData.candidatePaths,
          );
    final String? progressLabel = _segmentUiService.buildSegmentProgressLabel(
      event: segEvent,
      activePath: activePath,
      localizations: AppLocalizations.of(context),
      cueService: _upcomingSegmentCueService,
    );

    final double? exitAverage = _currentSegmentController.updateWithEvent(
      event: segEvent,
      timestamp: timestamp,
      activePath: activePath,
      distanceToSegmentStartMeters: nearestStart,
      progressLabel: progressLabel,
      userPosition: _userLatLng,
    );
    _updateSegmentsOnlyMetrics();
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
    _currentSegmentController.reset();
    _nextCameraCheckAt = null;
    _upcomingSegmentCueService.reset();
    _weighStationAlertService.reset();
    _lastNotificationStatus = null;
    _updateSegmentsOnlyMetrics();
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

    if (shouldSetState && mounted) {
      setState(() {});
    }

    _updateVisibleCameras();
    _updateVisibleSegments();
    _updateVisibleWeighStations();
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
    _updateVisibleSegments();
    _updateVisibleWeighStations();
  }

  void _onResetView() {
    final target = _blueDotAnimator.position ?? _userLatLng ?? _center;
    setState(() => _followUser = true);
    _moveCameraTo(target);
  }

  void _moveCameraTo(LatLng target) {
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
      setState(() => _followHeading = false);
      if (_mapReady) {
        _mapController.rotate(0);
      }
      return;
    }

    setState(() {
      _followHeading = true;
      _followUser = true;
    });
    final target = _blueDotAnimator.position ?? _userLatLng ?? _center;
    _moveCameraTo(target);
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
    _updateVisibleSegments();
    _updateVisibleWeighStations();
  }

  Future<void> _loadWeighStations() async {
    LatLngBounds? bounds;
    if (_mapReady) {
      try {
        bounds = _mapController.camera.visibleBounds;
      } catch (_) {
        bounds = null;
      }
    }
    final auth = context.read<AuthController>();
    await _segmentsService.loadWeighStations(bounds: bounds);
    await _segmentsService.refreshWeighStationVotes(
      client: auth.client,
      userId: auth.currentUserId,
    );
    if (!mounted) return;
    _weighStationAlertService.reset();
    _updateVisibleWeighStations();
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

  void _updateVisibleWeighStations() {
    LatLngBounds? bounds;
    if (_mapReady) {
      try {
        bounds = _mapController.camera.visibleBounds;
      } catch (_) {
        bounds = null;
      }
    }
    _segmentsService.updateVisibleWeighStations(bounds: bounds);
    if (!mounted) return;
    setState(() {});
  }

  void _onWeighStationLongPress(WeighStationMarker station) {
    if (!mounted) {
      return;
    }

    final WeighStationVotes initialVotes =
        _segmentsService.weighStationsState.votes[station.id] ??
        const WeighStationVotes();
    final bool? userVote =
        _segmentsService.weighStationsState.userVotes[station.id];

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return WeighStationFeedbackSheet(
          stationId: station.id,
          initialVotes: initialVotes,
          onVote: (isUpvote) {
            final auth = sheetContext.read<AuthController>();
            final WeighStationVoteResult updated = _segmentsService
                .registerWeighStationVote(
                  stationId: station.id,
                  isUpvote: isUpvote,
                  client: auth.client,
                  userId: auth.currentUserId,
                );
            if (mounted) {
              setState(() {});
            }
            return updated;
          },
          initialUserVote: userVote,
        );
      },
    );
  }

  void _updateVisibleSegments() {
    LatLngBounds? bounds;
    if (_mapReady) {
      try {
        bounds = _mapController.camera.visibleBounds;
      } catch (_) {
        bounds = null;
      }
    }

    final indexService = SegmentIndexService.instance;
    if (bounds == null || !indexService.isReady) {
      if (!mounted ||
          (_visibleSegmentPolylines.isEmpty &&
              _visibleSegmentSignatures.isEmpty)) {
        return;
      }
      setState(() {
        _visibleSegmentPolylines = const [];
        _visibleSegmentSignatures = const {};
      });
      return;
    }

    final segments = indexService.segmentsWithinBounds(bounds);
    final ignoredSegmentIds = _segmentsMetadata.deactivatedSegmentIds;
    final signatures = <String, String>{};
    final polylines = <Polyline>[];

    for (final segment in segments) {
      if (ignoredSegmentIds.contains(segment.id)) {
        continue;
      }
      final path = segment.path;
      if (path.length < 2) {
        continue;
      }
      signatures[segment.id] = _segmentSignature(path);
      polylines.add(
        Polyline(
          points: path
              .map((point) => LatLng(point.lat, point.lon))
              .toList(growable: false),
          strokeWidth: 4.0,
          color: Colors.blueAccent.withOpacity(0.8),
        ),
      );
    }

    if (mapEquals(_visibleSegmentSignatures, signatures) &&
        polylines.length == _visibleSegmentPolylines.length) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _visibleSegmentSignatures = signatures;
      _visibleSegmentPolylines = polylines;
    });
  }

  String _segmentSignature(List<GeoPoint> path) {
    final buffer = StringBuffer();
    buffer.write(path.length);
    for (final point in path) {
      buffer
        ..write(';')
        ..write(point.lat.toStringAsFixed(6))
        ..write(',')
        ..write(point.lon.toStringAsFixed(6));
    }
    return buffer.toString();
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
    _updateVisibleSegments();
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

  void _updateSegmentsOnlyMetrics() {
    _segmentsOnlyModeController.updateMetrics(
      currentSpeedKmh: _speedKmh,
      hasActiveSegment: _currentSegmentController.hasActiveSegment,
      segmentSpeedLimitKph:
          _currentSegmentController.activeSegmentSpeedLimitKph,
      segmentDebugPath: _currentSegmentController.activePath,
      distanceToSegmentStartMeters:
          _currentSegmentController.distanceToSegmentStartMeters,
    );
  }

  Future<void> _openSimpleModePage(SegmentsOnlyModeReason reason) async {
    _segmentsOnlyModeController.enterMode(reason);
    if (_simpleModePageOpen || !mounted) {
      return;
    }

    _simpleModePageOpen = true;
    try {
      await Navigator.of(context).pushNamed(AppRoutes.simpleMode);
    } finally {
      _simpleModePageOpen = false;
      if (_shouldExitSegmentsOnlyModeAfterNav(reason)) {
        _segmentsOnlyModeController.exitMode();
      }
    }
  }

  Future<void> _closeSimpleModePageIfOpen() async {
    if (!_simpleModePageOpen || !mounted) {
      return;
    }

    await Navigator.of(context).maybePop();
  }

  bool _shouldExitSegmentsOnlyModeAfterNav(SegmentsOnlyModeReason reason) {
    final SegmentsOnlyModeReason? currentReason =
        _segmentsOnlyModeController.reason;

    if (!_segmentsOnlyModeController.isActive || currentReason == null) {
      return true;
    }

    if (currentReason != reason) {
      return true;
    }

    switch (reason) {
      case SegmentsOnlyModeReason.manual:
        return true;
      case SegmentsOnlyModeReason.offline:
        return _hasConnectivity;
      case SegmentsOnlyModeReason.osmUnavailable:
        return _isOsmServiceAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSegment = context.watch<CurrentSegmentController>();
    final markerPoint = _blueDotAnimator.position ?? _userLatLng;
    final cameraState = _cameraController.state;
    final weighStationsState = _segmentsService.weighStationsState;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    final Widget mapContent = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _currentZoom,
            cameraConstraint: CameraConstraint.contain(
              bounds: AppConstants.europeBounds,
            ),
            onMapReady: _onMapReady,
          ),
          children: [
            const BaseTileLayer(),

            BlueDotMarker(point: markerPoint),

            if (_visibleSegmentPolylines.isNotEmpty)
              PolylineLayer(polylines: _visibleSegmentPolylines),

            if (kDebugMode && currentSegment.debugData.querySquare.isNotEmpty)
              QuerySquareOverlay(points: currentSegment.debugData.querySquare),
            if (kDebugMode &&
                currentSegment.debugData.boundingCandidates.isNotEmpty)
              CandidateBoundsOverlay(
                candidates: currentSegment.debugData.boundingCandidates,
              ),
            if (kDebugMode &&
                currentSegment.debugData.candidatePaths.isNotEmpty)
              SegmentPolylineOverlay(
                paths: currentSegment.debugData.candidatePaths,
                startGeofenceRadius:
                    currentSegment.debugData.startGeofenceRadius,
                endGeofenceRadius: currentSegment.debugData.endGeofenceRadius,
              ),
            WeighStationsOverlay(
              visibleStations: weighStationsState.visibleStations,
              onMarkerLongPress: _onWeighStationLongPress,
            ),
            TollCamerasOverlay(cameras: cameraState),
          ],
        ),
        if (currentSegment.handoverStatus != null)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SegmentHandoverBanner(
                status: currentSegment.handoverStatus!,
                margin: const EdgeInsets.only(top: 16),
              ),
            ),
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
                  final ScaffoldState? scaffoldState = Scaffold.maybeOf(
                    context,
                  );
                  final bool isDrawerOpen =
                      scaffoldState?.isEndDrawerOpen ?? false;
                  final theme = Theme.of(context);
                  final palette = AppColors.of(context);
                  final bool isDark = theme.brightness == Brightness.dark;
                  final Color backgroundColor = isDrawerOpen
                      ? palette.primary
                      : palette.surface.withOpacity(isDark ? 0.7 : 0.92);
                  final Color iconColor = isDrawerOpen
                      ? Colors.white
                      : palette.onSurface;
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
      hasActiveSegment: currentSegment.hasActiveSegment,
      segmentSpeedLimitKph: currentSegment.activeSegmentSpeedLimitKph,
      segmentDebugPath: currentSegment.activePath,
      distanceToSegmentStartMeters: currentSegment.distanceToSegmentStartMeters,
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
