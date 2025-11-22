import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'map/widgets/location_permission_banner.dart';
import 'map/widgets/notification_permission_banner.dart';
import 'map/widgets/map_intro_overlay.dart';
import 'map/widgets/map_welcome_overlays.dart';
import 'map/widgets/background_location_consent_overlay.dart';

part 'map/map_options_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _introCompletedPreferenceKey = 'map_intro_completed';
  static const String _termsAcceptedPreferenceKey = 'terms_and_conditions_accepted';
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
  bool _locationPermissionGranted = false;

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
  late final SegmentVoiceGuidanceService _segmentGuidanceController;
  SegmentsMetadata _segmentsMetadata = const SegmentsMetadata();
  Future<void>? _metadataLoadFuture;

  final OsmSpeedLimitService _osmSpeedLimitService = OsmSpeedLimitService();
  String? _osmSpeedLimitKph;
  LatLng? _lastSpeedLimitQueryLocation;
  Timer? _speedLimitPollTimer;
  bool _isSpeedLimitRequestInFlight = false;
  bool _simpleModePageOpen = false;
  bool get _isMapInForeground =>
      mounted &&
      _appLifecycleState == AppLifecycleState.resumed &&
      !_simpleModePageOpen;
  Timer? _initialLocationInitTimer;
  bool _initialLocationInitScheduled = false;
  Timer? _offlineRedirectTimer;
  Timer? _osmUnavailableRedirectTimer;
  bool _hasConnectivity = true;
  bool _isOsmServiceAvailable = true;
  DateTime? _osmUnavailableSince;

  double? _speedKmh;
  bool _isSyncing = false;
  final TollSegmentsSyncService _syncService = TollSegmentsSyncService();
  final WeighStationsSyncService _weighStationsSyncService =
      WeighStationsSyncService();
  DateTime? _nextCameraCheckAt;

  double? _userHeading;
  LatLng? _lastPositionSample;
  DateTime? _lastPositionTimestamp;
  DateTime? _lastUpcomingSegmentScanAt;
  double? _upcomingSegmentDistanceMeters;
  bool _upcomingSegmentDistanceIsCapped = false;

  final GlobalKey _controlsPanelKey = GlobalKey();
  double _controlsPanelHeight = 0;

  bool _useForegroundLocationService = false;
  bool _didRequestNotificationPermission = false;
  String? _lastNotificationStatus;
  bool _showIntro = false;
  bool _showWelcomeOverlay = false;
  bool _showWeighStationsPrompt = false;
  bool _showBackgroundConsent = false;
  bool _showLocationPermissionInfo = false;
  bool _showNotificationPermissionInfo = false;
  bool _locationPermissionTemporarilyDenied = false;
  bool _notificationPermissionTemporarilyDenied = false;
  bool _isRequestingForegroundPermission = false;
  bool _isRequestingNotificationPermission = false;
  bool? _backgroundLocationAllowed;
  bool _notificationsEnabled = true;
  bool _hasSystemBackgroundPermission = false;
  bool _isRequestingBackgroundPermission = false;
  BackgroundLocationConsentOption? _pendingBackgroundConsent;
  bool? _introCompleted;
  bool _introFlowPresented = true;
  bool _termsAccepted = false;

  static const Duration _upcomingSegmentScanInterval = Duration(seconds: 5);
  static const double _upcomingSegmentScanRangeMeters = 5000;
  static const double _upcomingSegmentScanFieldOfView = 120;

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
    _segmentGuidanceController = SegmentVoiceGuidanceService();
    _audioController = context.read<GuidanceAudioController>();
    _languageController = context.read<LanguageController>();
    _weighStationPreferencesController =
        context.read<WeighStationPreferencesController>();
    _segmentsOnlyModeController = context.read<SegmentsOnlyModeController>();
    _backgroundConsentController =
        context.read<BackgroundLocationConsentController>();
    _backgroundLocationAllowed = _backgroundConsentController.allowed;
    _enforceAudioModeBackgroundSafety();
    _backgroundConsentController.addListener(_handleBackgroundConsentChange);
    unawaited(_backgroundConsentController.ensureLoaded());
    unawaited(_loadIntroCompletionStatus());
    unawaited(_initConnectivityMonitoring());
    unawaited(_ensureNotificationPermission());
    _audioController.addListener(_updateAudioPolicy);
    _languageController.addListener(_handleLanguageChange);
    _weighStationPreferencesController
        .addListener(_handleWeighStationPreferenceChange);
    _handleWeighStationPreferenceChange();
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
    _speedLimitPollTimer?.cancel();
    _initialLocationInitTimer?.cancel();
    _blueDotAnimator.dispose();
    _segmentTracker.dispose();
    unawaited(_segmentGuidanceController.dispose());
    unawaited(_weighStationAlertService.dispose());
    _osmSpeedLimitService.dispose();
    _audioController.removeListener(_updateAudioPolicy);
    _languageController.removeListener(_handleLanguageChange);
    _weighStationPreferencesController
        .removeListener(_handleWeighStationPreferenceChange);
    _backgroundConsentController
        .removeListener(_handleBackgroundConsentChange);
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
    _applyBackgroundLocationPreference();
    if (state == AppLifecycleState.resumed) {
      unawaited(showLocationDisclosureIfNeeded());
      unawaited(_ensureNotificationPermission());
      _didRequestNotificationPermission = false;
    }
    _updateAudioPolicy();
    _updateSpeedLimitPollingForVisibility();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.hasLocationPermission();
    if (!hasPermission) {
      _locationPermissionGranted = false;
      if (mounted) {
        setState(() {
          _setLocationPermissionBannerVisible(true);
        });
      } else {
        _setLocationPermissionBannerVisible(true);
      }
      return;
    }
    _locationPermissionGranted = true;
    await _ensureNotificationPermission();
    if (_metadataLoadFuture != null) {
      await _metadataLoadFuture;
    }
    _speedSmoother.reset();
    final pos = await _locationService.getCurrentPosition();
    final DateTime firstTimestamp = pos.timestamp ?? DateTime.now();

    final firstKmh = _speedService.normalizeSpeed(pos.speed);
    _speedKmh = _speedSmoother.next(firstKmh);
    _scheduleSpeedIdleReset();
    _updateHeading(pos.heading);
    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _lastPositionSample = firstFix;
    _lastPositionTimestamp = firstTimestamp;
    _center = firstFix;
    final segEvent = _segmentTracker.handleLocationUpdate(
      current: firstFix,
      headingDegrees: _userHeading,
    );
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

  void _setBackgroundPermissionRequestInFlight(bool inFlight) {
    if (_isRequestingBackgroundPermission == inFlight) {
      return;
    }
    if (mounted) {
      setState(() {
        _isRequestingBackgroundPermission = inFlight;
      });
    } else {
      _isRequestingBackgroundPermission = inFlight;
    }
  }

  void _setSystemBackgroundPermission(bool granted) {
    if (_hasSystemBackgroundPermission == granted) {
      return;
    }
    if (mounted) {
      setState(() {
        _hasSystemBackgroundPermission = granted;
      });
    } else {
      _hasSystemBackgroundPermission = granted;
    }
  }

  Future<bool> _requestSystemBackgroundPermission({
    bool showDeniedMessage = true,
  }) async {
    if (_isRequestingBackgroundPermission) {
      return false;
    }

    final bool alreadyGranted =
        await _permissionService.hasBackgroundPermission();
    if (alreadyGranted) {
      _setSystemBackgroundPermission(true);
      return true;
    }

    _setBackgroundPermissionRequestInFlight(true);
    bool granted = false;
    try {
      granted = await _permissionService.ensureBackgroundPermission();
    } finally {
      _setBackgroundPermissionRequestInFlight(false);
    }
    _setSystemBackgroundPermission(granted);
    if (!granted && showDeniedMessage && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final localizations = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.backgroundPermissionDeniedMessage),
        ),
      );
    }
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
    final bool enabled =
        await _notificationPermissionService.areNotificationsEnabled();
    if (!mounted) {
      _notificationsEnabled = enabled;
      _setNotificationPermissionBannerVisible(
        _backgroundLocationAllowed == true && !enabled,
      );
      return;
    }
    setState(() {
      _notificationsEnabled = enabled;
      _setNotificationPermissionBannerVisible(
        _backgroundLocationAllowed == true && !enabled,
      );
    });
    _enforceAudioModeBackgroundSafety();
  }

  Future<void> _requestNotificationPermission() async {
    if (_isRequestingNotificationPermission) {
      return;
    }
    if (mounted) {
      setState(() {
        _isRequestingNotificationPermission = true;
      });
    } else {
      _isRequestingNotificationPermission = true;
    }
    final bool granted =
        await _notificationPermissionService.ensurePermissionGranted();
    _didRequestNotificationPermission = true;
    if (!mounted) {
      _isRequestingNotificationPermission = false;
      _notificationsEnabled = granted;
      return;
    }
    setState(() {
      _isRequestingNotificationPermission = false;
      _notificationsEnabled = granted;
      _setNotificationPermissionBannerVisible(
        _backgroundLocationAllowed == true && !granted,
      );
    });
    _enforceAudioModeBackgroundSafety();
  }

  void _setLocationPermissionBannerVisible(
    bool visible, {
    bool resetTemporaryDismissal = true,
  }) {
    if (visible) {
      if (_locationPermissionTemporarilyDenied) {
        return;
      }
      _showLocationPermissionInfo = true;
      return;
    }
    if (resetTemporaryDismissal) {
      _locationPermissionTemporarilyDenied = false;
    }
    _showLocationPermissionInfo = false;
  }

  void _setNotificationPermissionBannerVisible(
    bool visible, {
    bool resetTemporaryDismissal = true,
  }) {
    if (visible) {
      if (_notificationPermissionTemporarilyDenied) {
        return;
      }
      _showNotificationPermissionInfo = true;
      return;
    }
    if (resetTemporaryDismissal) {
      _notificationPermissionTemporarilyDenied = false;
    }
    _showNotificationPermissionInfo = false;
  }

  void _temporarilyDismissLocationPermissionPrompt() {
    if (!mounted) {
      _locationPermissionTemporarilyDenied = true;
      _setLocationPermissionBannerVisible(
        false,
        resetTemporaryDismissal: false,
      );
      return;
    }
    setState(() {
      _locationPermissionTemporarilyDenied = true;
      _setLocationPermissionBannerVisible(
        false,
        resetTemporaryDismissal: false,
      );
    });
  }

  void _temporarilyDismissNotificationPermissionPrompt() {
    if (!mounted) {
      _notificationPermissionTemporarilyDenied = true;
      _setNotificationPermissionBannerVisible(
        false,
        resetTemporaryDismissal: false,
      );
      return;
    }
    setState(() {
      _notificationPermissionTemporarilyDenied = true;
      _setNotificationPermissionBannerVisible(
        false,
        resetTemporaryDismissal: false,
      );
    });
  }

  void _handlePositionUpdate(Position position) {
    final DateTime now = DateTime.now();
    final DateTime sampleTime = position.timestamp ?? now;
    final LatLng next = LatLng(position.latitude, position.longitude);
    final LatLng? previous = _lastPositionSample ?? _userLatLng;

    _scheduleSpeedIdleReset();

    final double speedMps = _resolveSpeedMps(
      position: position,
      previous: previous,
      next: next,
      sampleTime: sampleTime,
    );
    final double shownKmh = _speedService.normalizeSpeed(speedMps);
    final double smoothedKmh = _speedSmoother.next(shownKmh);

    final double? heading = _resolveHeadingDegrees(
      deviceHeading: position.heading,
      previous: previous,
      next: next,
    );
    _updateHeading(heading);

    _currentSegmentController.recordProgress(
      position: next,
      timestamp: sampleTime,
    );
    _moveBlueDot(next);
    _maybeFetchSpeedLimit(next);
    final bool showWeighStations =
        _weighStationPreferencesController.shouldShowWeighStations;
    final nearestWeigh =
        showWeighStations ? _segmentsService.nearestWeighStation(next) : null;
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
        current: next,
        headingDegrees: _userHeading,
      );
      _applySegmentEvent(segEvent, now: now);
      _nextCameraCheckAt = _segmentsService.calculateNextCameraCheck(
        position: next,
      );
    }

    _lastPositionSample = next;
    _lastPositionTimestamp = sampleTime;

    if (!mounted) return;

    setState(() {
      _speedKmh = smoothedKmh;
    });

    _updateSegmentsOnlyMetrics();
  }

  double _resolveSpeedMps({
    required Position position,
    required LatLng? previous,
    required LatLng next,
    required DateTime sampleTime,
  }) {
    final double rawSpeed = position.speed;
    final double? deviceSpeed =
        rawSpeed.isFinite && rawSpeed >= 0 ? rawSpeed : null;

    double? derivedSpeed;
    if (previous != null && _lastPositionTimestamp != null) {
      final double dtSeconds =
          sampleTime.difference(_lastPositionTimestamp!).inMilliseconds /
              1000.0;
      if (dtSeconds > 0) {
        final double distanceMeters =
            _distanceCalculator.as(LengthUnit.Meter, previous, next);
        if (distanceMeters.isFinite && distanceMeters >= 0) {
          derivedSpeed = distanceMeters / dtSeconds;
        }
      }
    }

    if (deviceSpeed != null && deviceSpeed > 0) {
      return deviceSpeed;
    }
    if (derivedSpeed != null && derivedSpeed.isFinite) {
      return derivedSpeed;
    }
    return 0.0;
  }

  double? _resolveHeadingDegrees({
    required double? deviceHeading,
    required LatLng? previous,
    required LatLng next,
  }) {
    if (deviceHeading != null &&
        deviceHeading.isFinite &&
        deviceHeading >= 0) {
      return deviceHeading % 360;
    }

    if (previous == null) {
      return null;
    }

    final double travelDistance =
        _distanceCalculator.as(LengthUnit.Meter, previous, next);
    if (!travelDistance.isFinite || travelDistance < 0.5) {
      return null;
    }

    final double bearing = _distanceCalculator.bearing(previous, next);
    if (!bearing.isFinite) {
      return null;
    }

    final double normalized = bearing % 360;
    return normalized.isNegative ? normalized + 360 : normalized;
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

  Duration _currentSpeedLimitPollInterval() {
    return _osmSpeedLimitKph == null
        ? const Duration(seconds: 1)
        : const Duration(seconds: 3);
  }

  void _cancelSpeedLimitPolling() {
    _speedLimitPollTimer?.cancel();
    _speedLimitPollTimer = null;
  }

  void _updateSpeedLimitPollingForVisibility() {
    if (!_isMapInForeground) {
      _cancelSpeedLimitPolling();
      return;
    }

    final LatLng? lastLocation = _lastSpeedLimitQueryLocation;
    if (lastLocation != null) {
      _maybeFetchSpeedLimit(lastLocation);
    }
  }

  void _maybeFetchSpeedLimit(LatLng position) {
    _lastSpeedLimitQueryLocation = position;
    if (!_isMapInForeground) {
      _cancelSpeedLimitPolling();
      return;
    }

    final bool hasActiveTimer = _speedLimitPollTimer?.isActive ?? false;
    if (_isSpeedLimitRequestInFlight || hasActiveTimer) {
      return;
    }
    _speedLimitPollTimer = Timer(Duration.zero, _pollSpeedLimit);
  }

  void _scheduleNextSpeedLimitPoll() {
    if (!mounted || !_isMapInForeground) {
      _cancelSpeedLimitPolling();
      return;
    }
    _speedLimitPollTimer?.cancel();
    _speedLimitPollTimer =
        Timer(_currentSpeedLimitPollInterval(), _pollSpeedLimit);
  }

  Future<void> _pollSpeedLimit() async {
    _cancelSpeedLimitPolling();
    if (_isSpeedLimitRequestInFlight) {
      _scheduleNextSpeedLimitPoll();
      return;
    }

    if (!_isMapInForeground) {
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

      _osmUnavailableSince = null;
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

      final DateTime now = DateTime.now();
      _isOsmServiceAvailable = false;
      _osmUnavailableSince ??= now;

      if (now.difference(_osmUnavailableSince!) >=
          _osmUnavailableGracePeriod) {
        if (_segmentsOnlyModeController.reason !=
            SegmentsOnlyModeReason.osmUnavailable) {
          _segmentsOnlyModeController.enterMode(
            SegmentsOnlyModeReason.osmUnavailable,
          );
        }
        _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason.osmUnavailable);
      }
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
      distanceToSegmentStartIsCapped:
          _currentSegmentController.distanceToSegmentStartIsCapped,
    );
  }

  Future<void> _openSimpleModePage(SegmentsOnlyModeReason reason) async {
    _segmentsOnlyModeController.enterMode(reason);
    if (_simpleModePageOpen || !mounted) {
      return;
    }

    _simpleModePageOpen = true;
    _updateSpeedLimitPollingForVisibility();
    try {
      await Navigator.of(context).pushNamed(AppRoutes.simpleMode);
    } finally {
      _simpleModePageOpen = false;
      _updateSpeedLimitPollingForVisibility();
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

  void _revealIntro() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showIntro = true;
    });
  }

  void _dismissIntro() {
    if (!mounted) {
      return;
    }
    if (!_termsAccepted) {
      return;
    }
    final bool alreadyCompleted = _introCompleted == true;
    setState(() {
      _showIntro = false;
      _introCompleted = true;
      _introFlowPresented = true;
    });
    if (!alreadyCompleted) {
      unawaited(_persistIntroCompletion());
    }
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
    setState(() {
      _termsAccepted = accepted;
      if (accepted && !_locationPermissionGranted) {
        _setLocationPermissionBannerVisible(true);
      }
    });
    unawaited(_persistTermsAcceptance(accepted));
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
    if (!mounted) {
      _locationPermissionGranted = hasForeground;
      _setLocationPermissionBannerVisible(!hasForeground);
      if (hasForeground) {
        _scheduleInitialLocationInit();
      }
      return;
    }

    if (!hasForeground) {
      setState(() {
        _locationPermissionGranted = false;
        _setLocationPermissionBannerVisible(true);
      });
      return;
    }

    final bool wasGranted = _locationPermissionGranted;
    _locationPermissionGranted = true;

    if (!wasGranted || _showLocationPermissionInfo) {
      setState(() {
        _setLocationPermissionBannerVisible(false);
      });
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
    if (mounted) {
      setState(() {
        _backgroundLocationAllowed = consent;
        _hasSystemBackgroundPermission = hasSystemPermission;
      });
    } else {
      _backgroundLocationAllowed = consent;
      _hasSystemBackgroundPermission = hasSystemPermission;
    }
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
    if (mounted) {
      setState(() {
        _setLocationPermissionBannerVisible(false);
      });
    } else {
      _setLocationPermissionBannerVisible(false);
    }
    _applyBackgroundLocationPreference();
  }

  Future<void> _requestForegroundPermission() async {
    if (_isRequestingForegroundPermission) {
      return;
    }
    if (mounted) {
      setState(() {
        _isRequestingForegroundPermission = true;
      });
    } else {
      _isRequestingForegroundPermission = true;
    }
    final bool granted =
        await _permissionService.ensureForegroundPermission();
    if (mounted) {
      setState(() {
        _isRequestingForegroundPermission = false;
      });
    } else {
      _isRequestingForegroundPermission = false;
    }
    if (!mounted) {
      _locationPermissionGranted = granted;
      if (!granted) {
        _setLocationPermissionBannerVisible(true);
      }
      return;
    }
    if (granted) {
      _locationPermissionGranted = true;
      setState(() {
        _setLocationPermissionBannerVisible(false);
      });
      _scheduleInitialLocationInit();
      await _maybeShowBackgroundLocationDisclosure();
      return;
    }
    _handleForegroundPermissionDeclined();
  }

  void _handleForegroundPermissionDeclined() {
    _locationPermissionGranted = false;
    if (!mounted) {
      _setLocationPermissionBannerVisible(true);
      return;
    }
    setState(() {
      _setLocationPermissionBannerVisible(true);
    });
  }

  void _handleBackgroundPermissionDeclined() {
    _backgroundLocationAllowed = false;
    _hasSystemBackgroundPermission = false;
    _applyBackgroundLocationPreference();
    _enforceAudioModeBackgroundSafety();
    if (mounted) {
      setState(() {
        _setLocationPermissionBannerVisible(false);
        _setNotificationPermissionBannerVisible(false);
      });
      final messenger = ScaffoldMessenger.of(context);
      final localizations = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.backgroundConsentMenuHint),
        ),
      );
    } else {
      _setLocationPermissionBannerVisible(false);
      _setNotificationPermissionBannerVisible(false);
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
    setState(() {
      _backgroundLocationAllowed = allowed;
      if (allowed == true) {
        _setLocationPermissionBannerVisible(false);
      } else {
        _setNotificationPermissionBannerVisible(false);
      }
    });
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
    if (!_weighStationPreferencesController.isLoaded) {
      return;
    }

    final bool hasPreference =
        _weighStationPreferencesController.hasPreference;
    final bool shouldShowWeighStations =
        _weighStationPreferencesController.shouldShowWeighStations;

    bool showWelcome = _showWelcomeOverlay;
    bool showPrompt = _showWeighStationsPrompt;
    bool showIntro = _showIntro;

    if (!hasPreference) {
      if (!showPrompt) {
        showWelcome = true;
      }
      showIntro = false;
    } else {
      if (!shouldShowWeighStations) {
        _weighStationAlertService.reset();
      }
      showWelcome = false;
      showPrompt = false;
      if (!_introFlowPresented) {
        showIntro = true;
        _introFlowPresented = true;
      }
    }

    setState(() {
      _showWelcomeOverlay = showWelcome;
      _showWeighStationsPrompt = showPrompt;
      _showIntro = showIntro;
    });
  }

  Future<void> _loadIntroCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_introCompletedPreferenceKey) ?? false;
    final termsAccepted =
        prefs.getBool(_termsAcceptedPreferenceKey) ?? false;
    final bool introReady = completed && termsAccepted;
    if (!mounted) {
      return;
    }
    setState(() {
      _introCompleted = completed;
      _introFlowPresented = introReady;
      _termsAccepted = termsAccepted;
    });
    if (introReady) {
      unawaited(showLocationDisclosureIfNeeded());
    }
    _evaluateIntroFlow();
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

  Future<void> _persistIntroCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introCompletedPreferenceKey, true);
  }

  Future<void> _persistTermsAcceptance(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedPreferenceKey, accepted);
  }

  void _dismissWelcomeOverlay() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showWelcomeOverlay = false;
      _showWeighStationsPrompt = true;
    });
  }

  void _onBackgroundLocationConsentSelection(
    BackgroundLocationConsentOption option,
  ) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingBackgroundConsent = option;
    });
  }

  Future<void> _handleLocationDisclosureNotNow() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingBackgroundConsent = BackgroundLocationConsentOption.deny;
    });
    await _confirmBackgroundLocationConsent();
  }

  void _presentBackgroundConsentOverlay({required bool prefillSelection}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _showBackgroundConsent = true;
      if (prefillSelection) {
        final bool? allowed = _backgroundLocationAllowed;
        _pendingBackgroundConsent = allowed == null
            ? null
            : (allowed
                ? BackgroundLocationConsentOption.allow
                : BackgroundLocationConsentOption.deny);
      } else {
        _pendingBackgroundConsent = null;
      }
    });
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
    if (mounted) {
      setState(() {
        _showBackgroundConsent = false;
        _pendingBackgroundConsent = null;
      });
    } else {
      _showBackgroundConsent = false;
      _pendingBackgroundConsent = null;
    }
    if (allow) {
      await _backgroundConsentController.setAllowed(true);
      _backgroundLocationAllowed = true;
      _enforceAudioModeBackgroundSafety();
      if (mounted) {
        setState(() {
          _setLocationPermissionBannerVisible(false);
        });
      } else {
        _setLocationPermissionBannerVisible(false);
      }
      _applyBackgroundLocationPreference();
      await _ensureNotificationPermission();
      return;
    }
    await _backgroundConsentController.setAllowed(false);
    _backgroundLocationAllowed = false;
    _handleBackgroundPermissionDeclined();
  }

  void _completeWeighStationsPrompt(bool enabled) {
    if (!mounted) {
      return;
    }
    setState(() {
      _showWeighStationsPrompt = false;
    });
    unawaited(
      _weighStationPreferencesController.setShowWeighStations(enabled),
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
            if (_weighStationPreferencesController.shouldShowWeighStations)
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
            _didRequestNotificationPermission = true;
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
