import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_cam_finder/core/app_messages.dart' show AppMessages;

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/segments_only_mode_controller.dart';
import 'package:toll_cam_finder/features/map/services/camera_polling_service.dart';
import 'package:toll_cam_finder/features/map/services/foreground_notification_service.dart';
import 'package:toll_cam_finder/features/map/services/map_segments_service.dart';
import 'package:toll_cam_finder/features/map/services/map_sync_message_service.dart';
import 'package:toll_cam_finder/features/map/services/osm_speed_limit_service.dart';
import 'package:toll_cam_finder/features/map/services/segment_ui_service.dart';
import 'package:toll_cam_finder/features/map/services/speed_service.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/location_permission_flow.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/intro_flow_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/speed_limit_polling_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/segments_only_redirect_coordinator.dart';
import 'package:toll_cam_finder/features/segments/domain/index/segment_index_service.dart';
import 'package:toll_cam_finder/features/segments/domain/controllers/current_segment_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_voice_guidance_service.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/features/segments/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_sync_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station_vote.dart';
import 'package:toll_cam_finder/shared/services/background_location_consent_controller.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'package:toll_cam_finder/shared/services/location_service.dart';
import 'package:toll_cam_finder/shared/services/notification_permission_service.dart';
import 'package:toll_cam_finder/shared/services/permission_service.dart';
import 'package:toll_cam_finder/shared/services/weigh_station_preferences_controller.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_station_alert_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_sync_service.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/weigh_station_feedback_sheet.dart';
import 'map/blue_dot_animator.dart';
import 'map/toll_camera_controller.dart';
import 'map/weigh_station_controller.dart';
import 'map/widgets/map_controls_panel.dart';
import 'map/widgets/map_fab_column.dart';
import 'map/widgets/location_permission_banner.dart';
import 'map/widgets/notification_permission_banner.dart';
import 'map/widgets/map_intro_overlay.dart';
import 'map/widgets/map_welcome_overlays.dart';
import 'map/widgets/background_location_consent_overlay.dart';
import 'package:toll_cam_finder/features/map/presentation/services/position_update_service.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/map_canvas.dart';

part 'map/map_options_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _mapFollowEpsilonDeg = 1e-6;
  static const Duration _osmUnavailableGracePeriod = Duration(seconds: 3);

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
  late final WeighStationPreferencesController
      _weighStationPreferencesController;
  late final SegmentsOnlyModeController _segmentsOnlyModeController;
  late final BackgroundLocationConsentController
      _backgroundConsentController;
  late final SegmentsOnlyRedirectCoordinator _segmentsOnlyRedirectCoordinator;
  late final IntroFlowController _introFlowController;
  late final LocationPermissionFlow _permissionFlow;
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
  final Distance _distanceCalculator = const Distance();
  late final PositionUpdateService _positionUpdateService;
  final TollCameraController _cameraController = TollCameraController();
  final WeighStationController _weighStationController =
      WeighStationController();
  final SegmentTracker _segmentTracker = SegmentTracker(
    indexService: SegmentIndexService.instance,
  );
  List<Polyline> _visibleSegmentPolylines = const [];
  Map<String, String> _visibleSegmentSignatures = const {};
  late final SegmentVoiceGuidanceService _segmentGuidanceController;
  SegmentsMetadata _segmentsMetadata = const SegmentsMetadata();
  Future<void>? _metadataLoadFuture;
  late final SpeedLimitPollingController _speedLimitPollingController;

  final OsmSpeedLimitService _osmSpeedLimitService = OsmSpeedLimitService();
  String? _osmSpeedLimitKph;
  bool get _isMapInForeground =>
      mounted &&
      _appLifecycleState == AppLifecycleState.resumed &&
      !_segmentsOnlyRedirectCoordinator.isSimpleModePageOpen;
  Timer? _initialLocationInitTimer;
  bool _initialLocationInitScheduled = false;
  bool _hasConnectivity = true;
  bool _isOsmServiceAvailable = true;

  double? _speedKmh;
  bool _isSyncing = false;
  final TollSegmentsSyncService _syncService = TollSegmentsSyncService();
  final WeighStationsSyncService _weighStationsSyncService =
      WeighStationsSyncService();
  DateTime? _nextCameraCheckAt;

  double? _userHeading;
  DateTime? _lastUpcomingSegmentScanAt;
  double? _upcomingSegmentDistanceMeters;
  bool _upcomingSegmentDistanceIsCapped = false;

  final GlobalKey _controlsPanelKey = GlobalKey();
  double _controlsPanelHeight = 0;

  bool _useForegroundLocationService = false;
  String? _lastNotificationStatus;

  static const Duration _upcomingSegmentScanInterval = Duration(seconds: 5);
  static const double _upcomingSegmentScanRangeMeters = 5000;
  static const double _upcomingSegmentScanFieldOfView = 120;

  AverageSpeedController get _avgCtrl =>
      _currentSegmentController.averageController;
  LocationPermissionFlowState get _permissionState => _permissionFlow.state;
  bool? get _backgroundLocationAllowed =>
      _permissionState.backgroundLocationAllowed;
  bool get _notificationsEnabled => _permissionState.notificationsEnabled;
  bool get _hasSystemBackgroundPermission =>
      _permissionState.hasSystemBackgroundPermission;
  bool get _showBackgroundConsent => _permissionState.showBackgroundConsent;
  BackgroundLocationConsentOption? get _pendingBackgroundConsent =>
      _permissionState.pendingBackgroundConsent;
  bool get _showLocationPermissionInfo =>
      _permissionState.showLocationPermissionInfo;
  bool get _showNotificationPermissionInfo =>
      _permissionState.showNotificationPermissionInfo;
  bool get _locationPermissionTemporarilyDenied =>
      _permissionState.locationPermissionTemporarilyDenied;
  bool get _notificationPermissionTemporarilyDenied =>
      _permissionState.notificationPermissionTemporarilyDenied;
  bool get _isRequestingForegroundPermission =>
      _permissionState.isRequestingForegroundPermission;
  bool get _isRequestingNotificationPermission =>
      _permissionState.isRequestingNotificationPermission;
  bool get _isRequestingBackgroundPermission =>
      _permissionState.isRequestingBackgroundPermission;
  bool get _locationPermissionGranted =>
      _permissionState.locationPermissionGranted;
  IntroFlowState get _introState => _introFlowController.state;
  bool get _showIntro => _introState.showIntro;
  bool get _showWelcomeOverlay => _introState.showWelcomeOverlay;
  bool get _showWeighStationsPrompt => _introState.showWeighStationsPrompt;
  bool get _termsAccepted => _introState.termsAccepted;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    _currentSegmentController = context.read<CurrentSegmentController>();
    _blueDotAnimator = BlueDotAnimator(vsync: this, onTick: _onBlueDotTick);
    _segmentGuidanceController = SegmentVoiceGuidanceService();
    _audioController = context.read<GuidanceAudioController>();
    _languageController = context.read<LanguageController>();
    _weighStationPreferencesController =
        context.read<WeighStationPreferencesController>();
    _segmentsOnlyModeController = context.read<SegmentsOnlyModeController>();
    _segmentsOnlyRedirectCoordinator = SegmentsOnlyRedirectCoordinator(
      controller: _segmentsOnlyModeController,
      onOpenSimpleModePage: _openSimpleModePage,
      onCloseSimpleModePageIfOpen: _closeSimpleModePageIfOpen,
      hasConnectivity: () => _hasConnectivity,
      isOsmServiceAvailable: () => _isOsmServiceAvailable,
    );
    _backgroundConsentController =
        context.read<BackgroundLocationConsentController>();
    _introFlowController = IntroFlowController(
      prefsFuture: SharedPreferences.getInstance(),
      weighStationPreferencesController: _weighStationPreferencesController,
    );
    _introFlowController.addListener(_onIntroFlowChanged);
    _permissionFlow = LocationPermissionFlow(
      permissionService: _permissionService,
      notificationPermissionService: _notificationPermissionService,
      backgroundConsentController: _backgroundConsentController,
      initialBackgroundConsentAllowed: _backgroundConsentController.allowed,
    );
    _permissionFlow.addListener(_onPermissionFlowChanged);
    _positionUpdateService = PositionUpdateService(
      distanceCalculator: _distanceCalculator,
      speedService: _speedService,
    );
    _enforceAudioModeBackgroundSafety();
    _backgroundConsentController.addListener(_handleBackgroundConsentChange);
    unawaited(_backgroundConsentController.ensureLoaded());
    unawaited(_initConnectivityMonitoring());
    unawaited(_ensureNotificationPermission());
    _audioController.addListener(_updateAudioPolicy);
    _languageController.addListener(_handleLanguageChange);
    _weighStationPreferencesController
        .addListener(_handleWeighStationPreferenceChange);
    _handleWeighStationPreferenceChange();
    unawaited(
      _introFlowController.load().then((_) {
        if (!mounted) {
          return;
        }
        if (_introFlowController.introReady) {
          unawaited(showLocationDisclosureIfNeeded());
        }
        _introFlowController.evaluateFlow(
          onWeighStationsDisabled: _weighStationAlertService.reset,
        );
      }),
    );
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
    _speedLimitPollingController = SpeedLimitPollingController(
      osmSpeedLimitService: _osmSpeedLimitService,
      onSpeedLimitChanged: _handleSpeedLimitChanged,
      onAvailabilityChanged: _handleOsmAvailabilityChanged,
      onUnavailableBeyondGrace: _handleOsmUnavailableBeyondGrace,
      unavailableGracePeriod: _osmUnavailableGracePeriod,
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
    unawaited(_initSegmentsIndex());
    _updateAudioPolicy();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _evaluateIntroFlow();
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _connectivitySub?.cancel();
    _speedIdleResetTimer?.cancel();
    _initialLocationInitTimer?.cancel();
    _blueDotAnimator.dispose();
    _segmentTracker.dispose();
    _speedLimitPollingController.dispose();
    _segmentsOnlyRedirectCoordinator.dispose();
    _introFlowController.removeListener(_onIntroFlowChanged);
    _introFlowController.dispose();
    _permissionFlow.removeListener(_onPermissionFlowChanged);
    _permissionFlow.dispose();
    unawaited(_segmentGuidanceController.dispose());
    unawaited(_weighStationAlertService.dispose());
    _osmSpeedLimitService.dispose();
    _audioController.removeListener(_updateAudioPolicy);
    _languageController.removeListener(_handleLanguageChange);
    _weighStationPreferencesController
        .removeListener(_handleWeighStationPreferenceChange);
    _backgroundConsentController
        .removeListener(_handleBackgroundConsentChange);
    _segmentsOnlyModeController.exitMode();
    _currentSegmentController.reset();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleState = state;
    _applyBackgroundLocationPreference();
    if (state == AppLifecycleState.resumed) {
      unawaited(showLocationDisclosureIfNeeded());
      unawaited(_ensureNotificationPermission());
    }
    _updateAudioPolicy();
    _updateSpeedLimitPollingForVisibility();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.hasLocationPermission();
    if (!hasPermission) {
      _permissionFlow.setLocationPermissionGranted(false);
      _setLocationPermissionBannerVisible(true);
      return;
    }
    _permissionFlow.setLocationPermissionGranted(true);
    await _ensureNotificationPermission();
    if (_metadataLoadFuture != null) {
      await _metadataLoadFuture;
    }
    _positionUpdateService.reset();
    final pos = await _locationService.getCurrentPosition();
    final PositionUpdateResult initialUpdate =
        _positionUpdateService.handleInitialPosition(pos);
    final DateTime firstTimestamp = initialUpdate.timestamp;

    _speedKmh = initialUpdate.speedKmh;
    _scheduleSpeedIdleReset();
    _updateHeading(initialUpdate.headingDegrees);
    final LatLng firstFix = initialUpdate.position;
    _userLatLng = firstFix;
    _center = firstFix;
    final segEvent = _segmentTracker.handleLocationUpdate(
      current: firstFix,
      headingDegrees: _userHeading,
    );
    _applySegmentEvent(segEvent);
    _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
      position: firstFix,
    );

    _speedLimitPollingController.updatePosition(firstFix);

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
    _segmentsOnlyRedirectCoordinator.handleConnectivityChanged(isConnected);
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
    _weighStationAlertService.updateAudioPolicy(newPolicy);
  }

  void _onPermissionFlowChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onIntroFlowChanged() {
    if (mounted) {
      setState(() {});
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

  void _applyBackgroundLocationPreference() {
    final bool allowBackground =
        (_backgroundLocationAllowed ?? false) &&
        _notificationsEnabled &&
        _hasSystemBackgroundPermission;
    final bool isForeground = _appLifecycleState == AppLifecycleState.resumed;
    final bool shouldEnableForeground =
        !isForeground && allowBackground;
    _setForegroundLocationMode(shouldEnableForeground);

    if (!allowBackground && !isForeground) {
      unawaited(_suspendLocationUpdates());
      return;
    }

    if (!_locationPermissionGranted) {
      return;
    }

    if (_posSub == null) {
      unawaited(_subscribeToPositionStream());
    }
  }

  void _enforceAudioModeBackgroundSafety() {
    final bool backgroundAllowed =
        _backgroundLocationAllowed != false && _hasSystemBackgroundPermission;
    final bool notificationsAllowed = _notificationsEnabled;
    if (backgroundAllowed && notificationsAllowed) {
      return;
    }
    final GuidanceAudioMode mode = _audioController.mode;
    final bool requiresBackground =
        mode == GuidanceAudioMode.fullGuidance ||
        mode == GuidanceAudioMode.muteForeground;
    if (requiresBackground) {
      _audioController.setMode(GuidanceAudioMode.muteBackground);
    }
  }

  Future<bool> _requestSystemBackgroundPermission({
    bool showDeniedMessage = true,
  }) async {
    final localizations = AppLocalizations.of(context);
    final bool granted = await _permissionFlow.requestSystemBackgroundPermission(
      showDeniedMessage: showDeniedMessage,
      deniedMessage: localizations.backgroundPermissionDeniedMessage,
      showDeniedMessageCallback: (message) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
    return granted;
  }

  Future<void> _suspendLocationUpdates() async {
    if (_posSub == null) {
      return;
    }
    await _posSub?.cancel();
    _posSub = null;
  }

  Future<void> _ensureNotificationPermission() async {
    await _permissionFlow.ensureNotificationPermission(
      backgroundAllowed: _backgroundLocationAllowed == true,
    );
    _enforceAudioModeBackgroundSafety();
  }

  Future<void> _requestNotificationPermission() async {
    await _permissionFlow.requestNotificationPermission(
      backgroundAllowed: _backgroundLocationAllowed == true,
    );
    _enforceAudioModeBackgroundSafety();
  }

  void _setLocationPermissionBannerVisible(
    bool visible, {
    bool resetTemporaryDismissal = true,
  }) {
    _permissionFlow.setLocationPermissionBannerVisible(
      visible,
      resetTemporaryDismissal: resetTemporaryDismissal,
    );
  }

  void _setNotificationPermissionBannerVisible(
    bool visible, {
    bool resetTemporaryDismissal = true,
  }) {
    _permissionFlow.setNotificationPermissionBannerVisible(
      visible,
      resetTemporaryDismissal: resetTemporaryDismissal,
    );
  }

  void _temporarilyDismissLocationPermissionPrompt() {
    _permissionFlow.temporarilyDismissLocationPermissionPrompt();
  }

  void _temporarilyDismissNotificationPermissionPrompt() {
    _permissionFlow.temporarilyDismissNotificationPermissionPrompt();
  }

  void _handlePositionUpdate(Position position) {
    final DateTime now = DateTime.now();
    final PositionUpdateResult update =
        _positionUpdateService.handlePosition(position);

    _scheduleSpeedIdleReset();

    _updateHeading(update.headingDegrees);

    _currentSegmentController.recordProgress(
      position: update.position,
      timestamp: update.timestamp,
    );
    _moveBlueDot(update.position);
    _speedLimitPollingController.updatePosition(update.position);
    final bool showWeighStations =
        _weighStationPreferencesController.shouldShowWeighStations;
    final nearestWeigh =
        showWeighStations
            ? _segmentsService.nearestWeighStation(update.position)
            : null;
    final localizations = AppLocalizations.of(context);
    _weighStationAlertService.updateDistance(
      stationId: nearestWeigh?.marker.id,
      distanceMeters: nearestWeigh?.distanceMeters,
      approachMessage: localizations.weighStationApproachAlert,
    );
    if (_segmentsService.shouldProcessSegmentUpdate(
      now: now,
      nextCameraCheckAt: _nextCameraCheckAt,
    )) {
      final segEvent = _segmentTracker.handleLocationUpdate(
        current: update.position,
        headingDegrees: _userHeading,
      );
      _applySegmentEvent(segEvent, now: now);
      _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
        position: update.position,
      );
    }

    if (!mounted) return;

    setState(() {
      _speedKmh = update.speedKmh;
    });

    _updateSegmentsOnlyMetrics();
  }

  void _updateHeading(double? heading) {
    if (heading == null || !heading.isFinite || heading < 0) {
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

  void _updateSpeedLimitPollingForVisibility() {
    _speedLimitPollingController.updateVisibility(
      isForeground: _isMapInForeground,
    );
  }

  void _handleSpeedLimitChanged(String? speedLimitKph) {
    if (!mounted) {
      _osmSpeedLimitKph = speedLimitKph;
      return;
    }
    setState(() {
      _osmSpeedLimitKph = speedLimitKph;
    });
  }

  void _handleOsmAvailabilityChanged(bool isAvailable) {
    _isOsmServiceAvailable = isAvailable;
    if (isAvailable) {
      _segmentsOnlyRedirectCoordinator.handleOsmServiceRecovered();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleOsmUnavailableBeyondGrace() {
    _segmentsOnlyRedirectCoordinator.handleOsmUnavailableBeyondGrace();
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
    _positionUpdateService.resetSmoothing();
    if ((_speedKmh ?? 0) <= 0) {
      return;
    }
    setState(() {
      _speedKmh = 0.0;
    });
    _updateSegmentsOnlyMetrics();
  }

  void _resetUpcomingSegmentScan() {
    _lastUpcomingSegmentScanAt = null;
    _upcomingSegmentDistanceMeters = null;
    _upcomingSegmentDistanceIsCapped = false;
  }

  void _performUpcomingSegmentScan(DateTime now) {
    final LatLng? position = _userLatLng;
    if (position == null) {
      _upcomingSegmentDistanceMeters = null;
      _upcomingSegmentDistanceIsCapped = false;
      return;
    }

    final double? heading = _userHeading;
    double? distance;
    if (heading != null) {
      distance = _segmentTracker.findUpcomingSegmentDistance(
        current: position,
        headingDegrees: heading,
        fieldOfViewDegrees: _upcomingSegmentScanFieldOfView,
        maxDistanceMeters: _upcomingSegmentScanRangeMeters,
      );
    } else {
      distance = null;
    }

    if (distance != null) {
      _upcomingSegmentDistanceMeters = distance;
      _upcomingSegmentDistanceIsCapped = false;
    } else {
      _upcomingSegmentDistanceMeters = _upcomingSegmentScanRangeMeters;
      _upcomingSegmentDistanceIsCapped = true;
    }
    _lastUpcomingSegmentScanAt = now;
  }

  void _applySegmentEvent(SegmentTrackerEvent segEvent, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    final SegmentDebugPath? activePath = _segmentUiService
        .resolveActiveSegmentPath(segEvent.debugData.candidatePaths, segEvent);

    double? nearestStart;
    bool startDistanceIsCapped = false;
    if (segEvent.activeSegmentId != null) {
      nearestStart = 0;
      startDistanceIsCapped = false;
      _resetUpcomingSegmentScan();
    } else {
      final DateTime? lastScan = _lastUpcomingSegmentScanAt;
      final bool requiresContinuousUpdates = _upcomingSegmentDistanceMeters != null &&
          !_upcomingSegmentDistanceIsCapped;
      final bool scanIsStale = lastScan == null ||
          timestamp.difference(lastScan) >= _upcomingSegmentScanInterval;
      if (requiresContinuousUpdates || scanIsStale) {
        _performUpcomingSegmentScan(timestamp);
      }
      nearestStart = _upcomingSegmentDistanceMeters;
      startDistanceIsCapped = _upcomingSegmentDistanceIsCapped;
    }
    final String? progressLabel = _segmentUiService.buildSegmentProgressLabel(
      event: segEvent,
      activePath: activePath,
      localizations: AppLocalizations.of(context),
    );

    final double? exitAverage = _currentSegmentController.updateWithEvent(
      event: segEvent,
      timestamp: timestamp,
      activePath: activePath,
      distanceToSegmentStartMeters: nearestStart,
      distanceToSegmentStartIsCapped: startDistanceIsCapped,
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
        headingDegrees: _userHeading,
      ),
    );
  }

  void _resetSegmentState() {
    _currentSegmentController.reset();
    _nextCameraCheckAt = null;
    // Upcoming segment cues are handled through voice guidance; nothing to reset here.
    _weighStationAlertService.reset();
    _lastNotificationStatus = null;
    _updateSegmentsOnlyMetrics();
    unawaited(_segmentGuidanceController.reset());
    _resetUpcomingSegmentScan();
  }

  Future<void> _updateForegroundNotification(SegmentTrackerEvent event) async {
    if (!_useForegroundLocationService) {
      return;
    }

    final String status = _foregroundNotificationService.buildStatus(
      event: event,
      avgController: _avgCtrl,
      upcomingSegmentDistanceMeters:
          _currentSegmentController.distanceToSegmentStartMeters,
      upcomingDistanceIsCapped:
          _currentSegmentController.distanceToSegmentStartIsCapped,
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
    final LatLngBounds? bounds = _currentVisibleBounds();
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
    final LatLngBounds? bounds = _currentVisibleBounds();
    if (!mounted) return;

    setState(() {
      _cameraController.updateVisible(bounds: bounds);
    });
  }

  void _updateVisibleWeighStations() {
    final LatLngBounds? bounds = _currentVisibleBounds();
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
    final LatLngBounds? bounds = _currentVisibleBounds();

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

  LatLngBounds? _currentVisibleBounds() {
    if (!_mapReady) {
      return null;
    }
    try {
      return _mapController.camera.visibleBounds;
    } catch (_) {
      return null;
    }
  }

  LatLngBounds? get currentVisibleBounds => _currentVisibleBounds();

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
      distanceToSegmentStartIsCapped:
          _currentSegmentController.distanceToSegmentStartIsCapped,
    );
  }

  Future<void> _openSimpleModePage(SegmentsOnlyModeReason reason) async {
    if (!mounted) {
      return;
    }

    _updateSpeedLimitPollingForVisibility();
    try {
      await Navigator.of(context).pushNamed(AppRoutes.simpleMode);
    } finally {
      _updateSpeedLimitPollingForVisibility();
    }
  }

  Future<void> _closeSimpleModePageIfOpen() async {
    if (!_segmentsOnlyRedirectCoordinator.isSimpleModePageOpen || !mounted) {
      return;
    }

    await Navigator.of(context).maybePop();
  }

  void _revealIntro() {
    _introFlowController.revealIntro();
  }

  void _dismissIntro() async {
    if (!mounted) {
      return;
    }
    if (!_termsAccepted) {
      return;
    }
    await _introFlowController.dismissIntro();
    unawaited(showLocationDisclosureIfNeeded());
  }

  void _openBackgroundConsentSettings() {
    if (!_backgroundConsentController.isLoaded) {
      return;
    }
    _presentBackgroundConsentOverlay(prefillSelection: true);
  }

  void _onTermsConsentChanged(bool accepted) {
    if (!mounted) {
      return;
    }
    unawaited(_introFlowController.setTermsAccepted(accepted));
    if (accepted && !_locationPermissionGranted) {
      _setLocationPermissionBannerVisible(true);
    }
    if (!accepted) {
      return;
    }
    if (!_showIntro) {
      unawaited(showLocationDisclosureIfNeeded());
    }
  }

  void _openTermsAndConditions() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.termsAndConditions);
  }

  Future<void> showLocationDisclosureIfNeeded() async {
    if (!_termsAccepted || _showIntro) {
      return;
    }
    final bool hasForeground =
        await _permissionService.hasLocationPermission();
    final bool wasGranted = _locationPermissionGranted;
    _permissionFlow.setLocationPermissionGranted(hasForeground);
    _setLocationPermissionBannerVisible(!hasForeground);
    if (!hasForeground) {
      return;
    }

    if (!wasGranted || _showLocationPermissionInfo) {
      _setLocationPermissionBannerVisible(false);
    }
    _scheduleInitialLocationInit();
    await _maybeShowBackgroundLocationDisclosure();
    await _ensureNotificationPermission();
  }

  Future<void> _maybeShowBackgroundLocationDisclosure() async {
    if (!_termsAccepted ||
        _showIntro ||
        !_locationPermissionGranted ||
        _showBackgroundConsent) {
      return;
    }
    if (!_backgroundConsentController.isLoaded) {
      await _backgroundConsentController.ensureLoaded();
      if (!mounted) {
        return;
      }
    }
    final bool? consent = _backgroundConsentController.allowed;
    final bool hasSystemPermission =
        await _permissionService.hasBackgroundPermission();
    _permissionFlow.setBackgroundConsentAllowed(consent);
    _permissionFlow.setHasSystemBackgroundPermission(hasSystemPermission);
    _enforceAudioModeBackgroundSafety();

    if (consent == null) {
      _presentBackgroundConsentOverlay(prefillSelection: false);
      return;
    }
    if (!consent) {
      _handleBackgroundPermissionDeclined();
      return;
    }
    if (!hasSystemPermission) {
      _presentBackgroundConsentOverlay(prefillSelection: true);
      return;
    }
    _setLocationPermissionBannerVisible(false);
    _applyBackgroundLocationPreference();
  }

  Future<void> _requestForegroundPermission() async {
    final bool granted = await _permissionFlow.requestForegroundPermission();
    if (!granted) {
      return;
    }
    _scheduleInitialLocationInit();
    await _maybeShowBackgroundLocationDisclosure();
  }

  void _handleBackgroundPermissionDeclined() {
    _permissionFlow.setBackgroundConsentAllowed(false);
    _permissionFlow.setHasSystemBackgroundPermission(false);
    _setLocationPermissionBannerVisible(false);
    _setNotificationPermissionBannerVisible(false);
    _applyBackgroundLocationPreference();
    _enforceAudioModeBackgroundSafety();
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final localizations = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.backgroundConsentMenuHint),
        ),
      );
    }
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }


  void _handleWeighStationPreferenceChange() {
    if (!mounted) {
      return;
    }
    _evaluateIntroFlow();
  }

  void _handleBackgroundConsentChange() {
    if (!mounted) {
      return;
    }
    final bool? allowed = _backgroundConsentController.allowed;
    _permissionFlow.setBackgroundConsentAllowed(allowed);
    _enforceAudioModeBackgroundSafety();
    _applyBackgroundLocationPreference();
    if (allowed == true) {
      if (_termsAccepted && _locationPermissionGranted) {
        unawaited(_maybeShowBackgroundLocationDisclosure());
      }
      unawaited(_ensureNotificationPermission());
      return;
    }
    if (allowed == false) {
      _handleBackgroundPermissionDeclined();
    }
  }

  void _evaluateIntroFlow() {
    _introFlowController.evaluateFlow(
      onWeighStationsDisabled: _weighStationAlertService.reset,
    );
  }

  void _scheduleInitialLocationInit({Duration delay = Duration.zero}) {
    if (_initialLocationInitScheduled) {
      return;
    }
    _initialLocationInitScheduled = true;
    _initialLocationInitTimer?.cancel();
    if (delay == Duration.zero) {
      unawaited(_initLocation());
      return;
    }
    _initialLocationInitTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      unawaited(_initLocation());
    });
  }

  void _dismissWelcomeOverlay() {
    _introFlowController.dismissWelcomeOverlay();
  }

  void _onBackgroundLocationConsentSelection(
    BackgroundLocationConsentOption option,
  ) {
    _permissionFlow.selectBackgroundConsent(option);
  }

  Future<void> _handleLocationDisclosureNotNow() async {
    _permissionFlow.selectBackgroundConsent(
      BackgroundLocationConsentOption.deny,
    );
    await _confirmBackgroundLocationConsent();
  }

  void _presentBackgroundConsentOverlay({required bool prefillSelection}) {
    _permissionFlow.presentBackgroundConsentOverlay(
      prefillSelection: prefillSelection,
    );
  }

  Future<void> _confirmBackgroundLocationConsent() async {
    final choice = _pendingBackgroundConsent;
    if (choice == null) {
      return;
    }
    final bool allow =
        choice == BackgroundLocationConsentOption.allow;
    if (allow) {
      final bool granted =
          await _requestSystemBackgroundPermission();
      if (!granted) {
        return;
      }
    }
    if (allow) {
      await _permissionFlow.persistBackgroundConsent(true);
      _enforceAudioModeBackgroundSafety();
      _setLocationPermissionBannerVisible(false);
      _applyBackgroundLocationPreference();
      await _ensureNotificationPermission();
      return;
    }
    await _permissionFlow.persistBackgroundConsent(false);
    _handleBackgroundPermissionDeclined();
  }

  void _completeWeighStationsPrompt(bool enabled) {
    unawaited(
      _introFlowController.completeWeighStationsPrompt(
        enabled,
        onWeighStationsDisabled: _weighStationAlertService.reset,
      ),
    );
  }

  void _onLanguageSelected(String code) {
    for (final option in _languageController.languageOptions) {
      if (option.available && option.languageCode == code) {
        _languageController.setLocale(option.locale);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSegment = context.watch<CurrentSegmentController>();
    final localizations = AppLocalizations.of(context);
    final markerPoint = _blueDotAnimator.position ?? _userLatLng;
    final cameraState = _cameraController.state;
    final weighStationsState = _segmentsService.weighStationsState;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    final Widget mapContent = MapCanvas(
      mapController: _mapController,
      initialCenter: _center,
      initialZoom: _currentZoom,
      onMapReady: _onMapReady,
      markerPoint: markerPoint,
      visibleSegmentPolylines: _visibleSegmentPolylines,
      currentSegment: currentSegment,
      showWeighStations: _weighStationPreferencesController.shouldShowWeighStations,
      weighStationsState: weighStationsState,
      onWeighStationLongPress: _onWeighStationLongPress,
      cameraState: cameraState,
      osmSpeedLimitKph: _osmSpeedLimitKph,
      speedKmh: _speedKmh,
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
      distanceToSegmentStartIsCapped:
          currentSegment.distanceToSegmentStartIsCapped,
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
      if (_showLocationPermissionInfo && !_locationPermissionTemporarilyDenied)
        LocationPermissionBanner(
          userOptedOut: _backgroundLocationAllowed == false,
          isRequestingPermission: _isRequestingForegroundPermission,
          onRequestPermission: () => unawaited(
            _requestForegroundPermission(),
          ),
          onOpenSettings: () => unawaited(_openAppSettings()),
          onReviewDisclosure: _openBackgroundConsentSettings,
          onNotNow: _temporarilyDismissLocationPermissionPrompt,
        ),
      if (_showNotificationPermissionInfo &&
          !_notificationPermissionTemporarilyDenied)
        NotificationPermissionBanner(
          isRequesting: _isRequestingNotificationPermission,
          onRequestPermission: () => unawaited(
            _requestNotificationPermission(),
          ),
          onOpenSettings: () {
            unawaited(_notificationPermissionService.openSettings());
          },
          onNotNow: _temporarilyDismissNotificationPermissionPrompt,
        ),
      MapWelcomeOverlay(
        visible: _showWelcomeOverlay,
        languageOptions: _languageController.languageOptions,
        selectedLanguageCode: _languageController.locale.languageCode,
        onLanguageSelected: _onLanguageSelected,
        onContinue: _dismissWelcomeOverlay,
      ),
      MapWeighStationPreferenceOverlay(
        visible: _showWeighStationsPrompt,
        onEnable: () => _completeWeighStationsPrompt(true),
        onSkip: () => _completeWeighStationsPrompt(false),
      ),
      MapIntroOverlay(
        visible: _showIntro,
        onDismiss: _dismissIntro,
        termsAccepted: _termsAccepted,
        onTermsConsentChanged: _onTermsConsentChanged,
        onViewTerms: _openTermsAndConditions,
      ),
      BackgroundLocationConsentOverlay(
        visible: _showBackgroundConsent,
        selection: _pendingBackgroundConsent,
        onSelectionChanged: _onBackgroundLocationConsentSelection,
        isProcessing: _isRequestingBackgroundPermission,
        onAgree: () => unawaited(
          _confirmBackgroundLocationConsent(),
        ),
        onNotNow: () => unawaited(
          _handleLocationDisclosureNotNow(),
        ),
      ),
    ];

      return Scaffold(
        endDrawer: _buildOptionsDrawer(),
        body: Stack(fit: StackFit.expand, children: stackChildren),
      );
    }
  }
