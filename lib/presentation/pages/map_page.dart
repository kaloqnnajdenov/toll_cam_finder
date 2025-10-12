import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
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
import 'map/blue_dot_animator.dart';
import 'map/toll_camera_controller.dart';
import 'map/widgets/map_controls_panel.dart';
import 'map/widgets/map_fab_column.dart';
import 'map/widgets/segment_overlays.dart';

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
  // User + map state
  LatLng _center = AppConstants.initialCenter;
  LatLng? _userLatLng;
  bool _mapReady = false;
  bool _followUser = false;
  double _currentZoom = AppConstants.initialZoom;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<MapEvent>? _mapEvtSub;
  StreamSubscription<CompassEvent>? _compassSub;

  // Helpers
  late final BlueDotAnimator _blueDotAnimator;
  late final AverageSpeedController _avgCtrl;
  final SpeedSmoother _speedSmoother = SpeedSmoother();
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

  double? _speedKmh;
  double? _compassHeading;
  String? _segmentProgressLabel;
  SegmentGuidanceUiModel? _segmentGuidanceUi;
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

    _metadataLoadFuture = _loadSegmentsMetadata();
    unawaited(_metadataLoadFuture!.then((_) => _loadCameras()));

    _mapEvtSub = _mapController.mapEventStream.listen(_onMapEvent);
    final compassStream = FlutterCompass.events;
    if (compassStream != null) {
      _compassSub = compassStream.listen(_handleCompassEvent);
    }
    unawaited(_initLocation());
    unawaited(_initSegmentsIndex());
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _compassSub?.cancel();
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

  void _handleCompassEvent(CompassEvent event) {
    if (!mounted) return;

    final double? heading = event.heading;
    if (heading == null || !heading.isFinite) {
      _compassHeading = null;
      return;
    }

    double normalized = heading % 360;
    if (normalized < 0) {
      normalized += 360;
    }

    _compassHeading = normalized;
  }

  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.ensureLocationPermission();
    if (!hasPermission) return;
    await _ensureNotificationPermission();
    if (_metadataLoadFuture != null) {
      try {
        await _metadataLoadFuture;
      } catch (_) {
        // Metadata failures are reported separately.
      }
    }
    _speedSmoother.reset();
    final pos = await _locationService.getCurrentPosition();

    final firstKmh = _speedService.normalizeSpeed(pos.speed);
    _speedKmh = _speedSmoother.next(firstKmh);
    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
    final segEvent = _segmentTracker.handleLocationUpdate(
      current: firstFix,
      previous: null,
      rawHeading: pos.heading,
      speedKmh: _speedKmh,
      compassHeading: _compassHeading,
    );
    _applySegmentEvent(segEvent);
    _updateCameraPollingSchedule(firstFix);

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
      final bool enabled =
          await _notificationPermissionService.areNotificationsEnabled();
      if (enabled || !mounted) {
        return;
      }

      _showNotificationSettingsPrompt();
      return;
    }

    _didRequestNotificationPermission = true;
    final bool granted =
        await _notificationPermissionService.ensurePermissionGranted();
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
    final shownKmh = _speedService.normalizeSpeed(position.speed);
    final smoothedKmh = _speedSmoother.next(shownKmh);
    final next = LatLng(position.latitude, position.longitude);
    _avgCtrl.addSample(shownKmh);
    final previous = _userLatLng;
    _moveBlueDot(next);
    final now = DateTime.now();
    if (_shouldProcessSegmentUpdate(now)) {
      final segEvent = _segmentTracker.handleLocationUpdate(
        current: next,
        previous: previous,
        rawHeading: position.heading,
        speedKmh: smoothedKmh,
        compassHeading: _compassHeading,
      );
      _applySegmentEvent(segEvent, now: now);
      _updateCameraPollingSchedule(next);
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

  void _applySegmentEvent(SegmentTrackerEvent segEvent, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    final SegmentDebugPath? activePath = _segmentUiService.resolveActiveSegmentPath(
      segEvent.debugData.candidatePaths,
      segEvent,
    );
    if (segEvent.startedSegment) {
      _lastSegmentAvgKmh = null;
      _avgCtrl.start();
    } else if (segEvent.endedSegment) {
      final double avgForSegment = _avgCtrl.average;
      _lastSegmentAvgKmh = avgForSegment.isFinite ? avgForSegment : null;
      _avgCtrl.reset();
    }

    if (segEvent.activeSegmentId == null) {
      _activeSegmentSpeedLimitKph = null;
    } else {
      _activeSegmentSpeedLimitKph = segEvent.activeSegmentSpeedLimitKph;
    }

    _segmentDebugData = segEvent.debugData;
    _segmentProgressLabel = _segmentUiService.buildSegmentProgressLabel(
      event: segEvent,
      activePath: activePath,
      localizations: AppLocalizations.of(context),
      cueService: _upcomingSegmentCueService,
    );
    _lastSegmentEvent = segEvent;
    unawaited(_updateForegroundNotification(segEvent));

    final guidanceFuture = _segmentGuidanceController.handleUpdate(
      event: segEvent,
      activePath: activePath,
      averageKph: _avgCtrl.average,
      speedLimitKph: segEvent.activeSegmentSpeedLimitKph,
      now: timestamp,
      averageStartedAt: _avgCtrl.startedAt,
    );

    unawaited(guidanceFuture.then((result) {
      if (!mounted || result == null) {
        return;
      }
      if (result.shouldClear) {
        setState(() {
          _segmentGuidanceUi = null;
        });
        return;
      }
      if (result.ui != null) {
        setState(() {
          _segmentGuidanceUi = result.ui;
        });
      }
    }));
  }

  void _resetSegmentState() {
    _segmentDebugData = const SegmentTrackerDebugData.empty();
    _segmentProgressLabel = null;
    _lastSegmentAvgKmh = null;
    _activeSegmentSpeedLimitKph = null;
    _avgCtrl.reset();
    _segmentGuidanceUi = null;
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

  bool _shouldProcessSegmentUpdate(DateTime now) {
    if (_segmentTracker.activeSegmentId != null) {
      return true;
    }
    final DateTime? nextCheck = _nextCameraCheckAt;
    if (nextCheck == null) {
      return true;
    }
    return !now.isBefore(nextCheck);
  }

  void _updateCameraPollingSchedule(LatLng position) {
    if (_segmentTracker.activeSegmentId != null) {
      _nextCameraCheckAt = null;
      return;
    }

    final double? distance =
        _cameraController.nearestCameraDistanceMeters(position);
    final Duration delay =
        _cameraPollingService.delayForDistance(distance);
    if (delay <= Duration.zero) {
      _nextCameraCheckAt = null;
    } else {
      _nextCameraCheckAt = DateTime.now().add(delay);
    }
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
    try {
      final metadata = await _metadataService.load();
      _segmentsMetadata = metadata;
      _segmentTracker.updateIgnoredSegments(metadata.deactivatedSegmentIds);
    } on SegmentsMetadataException catch (error) {
      _segmentsMetadata = const SegmentsMetadata();
      _segmentTracker.updateIgnoredSegments(const <String>{});
      if (showErrors && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppMessages.failedToLoadSegmentPreferences(error.message),
            ),
          ),
        );
      } else {
        debugPrint(
          'MapPage: failed to load segments metadata (${error.message}).',
        );
      }
    }
  }

  Future<void> _loadCameras() async {
    await _cameraController.loadFromAsset(
      AppConstants.camerasAsset,
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
        previous: null,
        rawHeading: null,
        speedKmh: _speedKmh,
        compassHeading: _compassHeading,
      );
      _applySegmentEvent(seedEvent);
      _updateCameraPollingSchedule(_userLatLng!);
    }

    setState(() {});
  }

  Future<void> _runStartupSync() async {
    if (_isSyncing) {
      return;
    }

    final auth = context.read<AuthController>();
    final client = auth.client;
    if (client == null) {
      debugPrint('MapPage: skipping startup sync (no Supabase client).');
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.sync(client: client);
    } on TollSegmentsSyncException catch (error) {
      debugPrint('MapPage: startup sync failed (${error.message}).');
    } catch (error, stackTrace) {
      debugPrint('MapPage: unexpected startup sync error: $error\n$stackTrace');
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
                segmentGuidance: _segmentGuidanceUi,
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

  Drawer _buildOptionsDrawer() {
    final localizations = AppLocalizations.of(context);
    final languageController = context.watch<LanguageController>();
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(localizations.sync),
              enabled: !_isSyncing,
              trailing: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isSyncing ? null : _onSyncSelected,
            ),
            ListTile(
              leading: const Icon(Icons.segment),
              title: Text(localizations.segments),
              onTap: _onSegmentsSelected,
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.languageButton),
              subtitle: Text(languageController.currentOption.label),
              onTap: _onLanguageSelected,
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(localizations.profile),
              onTap: () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _onProfileSelected();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onLanguageSelected() {
    final localizations = AppLocalizations.of(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return SafeArea(
            child: Consumer<LanguageController>(
              builder: (context, controller, _) {
                final options = controller.languageOptions;
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text(localizations.selectLanguage),
                    ),
                    for (final option in options)
                      ListTile(
                        title: Text(option.label),
                        trailing: option.locale == controller.locale
                            ? const Icon(Icons.check)
                            : null,
                        enabled: option.available,
                        subtitle: option.available
                            ? null
                            : Text(localizations.comingSoon),
                        onTap: option.available
                            ? () {
                                controller.setLocale(option.locale);
                                Navigator.of(sheetContext).pop();
                              }
                            : null,
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
    });
  }

  void _onProfileSelected() {
    final localizations = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    if (auth.isLoggedIn) {
      Navigator.of(context).pushNamed(AppRoutes.profile);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.login),
                title: Text(localizations.logIn),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(AppRoutes.login);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: Text(localizations.createAccountCta),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(AppRoutes.signUp);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSyncSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_performSync());
    });
  }

  void _onSegmentsSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openSegmentsPage());
    });
  }

  Future<void> _openSegmentsPage() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.segments);
    if (!mounted || result != true) {
      return;
    }

    await _refreshSegmentsData();
  }

  Future<void> _refreshSegmentsData() async {
    _metadataLoadFuture = _loadSegmentsMetadata(showErrors: true);
    if (_metadataLoadFuture != null) {
      try {
        await _metadataLoadFuture;
      } catch (_) {
        // Errors are surfaced inside _loadSegmentsMetadata.
      }
    }
    final reloaded = await _segmentTracker.reload(
      assetPath: AppConstants.pathToTollSegments,
    );

    _segmentTracker.updateIgnoredSegments(
      _segmentsMetadata.deactivatedSegmentIds,
    );

    await _loadCameras();
    if (!mounted) return;

    _resetSegmentState();
    if (reloaded && _userLatLng != null) {
      final segEvent = _segmentTracker.handleLocationUpdate(
        current: _userLatLng!,
        previous: null,
        rawHeading: null,
        speedKmh: _speedKmh,
        compassHeading: _compassHeading,
      );
      _applySegmentEvent(segEvent);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    final auth = context.read<AuthController>();
    final client = auth.client;
    final messenger = ScaffoldMessenger.of(context);

    if (client == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppMessages.supabaseNotConfiguredForSync),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _syncService.sync(client: client);
      final reloaded = await _segmentTracker.reload(
        assetPath: AppConstants.pathToTollSegments,
      );
      await _loadCameras();
      if (!mounted) {
        return;
      }
      _resetSegmentState();
      if (reloaded && _userLatLng != null) {
        final segEvent = _segmentTracker.handleLocationUpdate(
          current: _userLatLng!,
          previous: null,
          rawHeading: null,
          speedKmh: _speedKmh,
          compassHeading: _compassHeading,
        );
        _applySegmentEvent(segEvent);
      }
      final message = _syncMessageService.buildSuccessMessage(result);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on TollSegmentsSyncException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error, stackTrace) {
      debugPrint('Failed to sync toll segments: $error\n$stackTrace');
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppMessages.unexpectedSyncError),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncing = false;
      });
    }
  }

}
