import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_compass/flutter_compass.dart';
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
import 'package:toll_cam_finder/services/segment_tracker.dart';
import 'package:toll_cam_finder/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/services/toll_segments_sync_service.dart';

import '../../app/app_routes.dart';
import '../../services/auth_controller.dart';
import '../../services/location_service.dart';
import '../../services/permission_service.dart';
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

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  static const double _mapFollowEpsilonDeg = 1e-6;
  static const double _speedDeadbandKmh = 1.0;
  // External services
  final MapController _mapController = MapController();
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();
  final SegmentsMetadataService _metadataService = SegmentsMetadataService();

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
  final AverageSpeedController _avgCtrl = AverageSpeedController();
  final SpeedSmoother _speedSmoother = SpeedSmoother();
  final TollCameraController _cameraController = TollCameraController();
  final SegmentTracker _segmentTracker = SegmentTracker(
    indexService: SegmentIndexService.instance,
  );
  SegmentsMetadata _segmentsMetadata = const SegmentsMetadata();
  Future<void>? _metadataLoadFuture;

  SegmentTrackerDebugData _segmentDebugData =
      const SegmentTrackerDebugData.empty();

  double? _lastSegmentAvgKmh;
  double? _activeSegmentSpeedLimitKph;

  double? _speedKmh;
  double? _compassHeading;
  String? _segmentProgressLabel;
  bool _isSyncing = false;
  final TollSegmentsSyncService _syncService = TollSegmentsSyncService();

  @override
  void initState() {
    super.initState();

    _blueDotAnimator = BlueDotAnimator(vsync: this, onTick: _onBlueDotTick);

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
    _avgCtrl.dispose();
    _segmentTracker.dispose();
    super.dispose();
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
    if (_metadataLoadFuture != null) {
      try {
        await _metadataLoadFuture;
      } catch (_) {
        // Metadata failures are reported separately.
      }
    }
    _speedSmoother.reset();
    final pos = await _locationService.getCurrentPosition();

    final firstKmh = _normalizeSpeed(pos.speed);
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

    if (mounted) setState(() {});

    if (_mapReady) {
      _mapController.move(_center, AppConstants.zoomWhenFocused);
      _currentZoom = AppConstants.zoomWhenFocused;
    }

    _posSub?.cancel();
    _posSub = _locationService.getPositionStream().listen(
      _handlePositionUpdate,
    );
  }

  void _handlePositionUpdate(Position position) {
    final shownKmh = _normalizeSpeed(position.speed);
    final smoothedKmh = _speedSmoother.next(shownKmh);
    final next = LatLng(position.latitude, position.longitude);
    _avgCtrl.addSample(shownKmh);
    final previous = _userLatLng;
    _moveBlueDot(next);
    final segEvent = _segmentTracker.handleLocationUpdate(
      current: next,
      previous: previous,
      rawHeading: position.heading,
      speedKmh: smoothedKmh,
      compassHeading: _compassHeading,
    );
    _applySegmentEvent(segEvent);

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

  void _applySegmentEvent(SegmentTrackerEvent segEvent) {
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
    _segmentProgressLabel = _buildSegmentProgressLabel(segEvent);
  }

  void _resetSegmentState() {
    _segmentDebugData = const SegmentTrackerDebugData.empty();
    _segmentProgressLabel = null;
    _lastSegmentAvgKmh = null;
    _activeSegmentSpeedLimitKph = null;
    _avgCtrl.reset();
  }

  double _normalizeSpeed(double metersPerSecond) {
    if (!metersPerSecond.isFinite || metersPerSecond < 0) return 0.0;
    final kmh = metersPerSecond * 3.6;
    return kmh < _speedDeadbandKmh ? 0.0 : kmh;
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

  String? _buildSegmentProgressLabel(SegmentTrackerEvent event) {
    final paths = event.debugData.candidatePaths;
    if (paths.isEmpty) {
      return null;
    }

    final String? activeId = event.activeSegmentId;
    if (activeId != null) {
      final activePath =
          _firstPathMatching(paths, (p) => p.id == activeId && p.isActive) ??
          _firstPathMatching(paths, (p) => p.id == activeId) ??
          _firstPathMatching(paths, (p) => p.isActive);

      if (activePath != null &&
          activePath.remainingDistanceMeters.isFinite &&
          activePath.remainingDistanceMeters >= 0) {
        final remaining = activePath.remainingDistanceMeters;
        if (remaining >= 1000) {
          return '${(remaining / 1000).toStringAsFixed(2)} km to segment end';
        }
        if (remaining >= 1) {
          return '${remaining.toStringAsFixed(0)} m to segment end';
        }
        return 'Segment end nearby';
      }
      return null;
    }

    SegmentDebugPath? upcoming;
    for (final path in paths) {
      final startDist = path.startDistanceMeters;
      if (!startDist.isFinite) continue;
      if (startDist <= 500) {
        if (upcoming == null || startDist < upcoming!.startDistanceMeters) {
          upcoming = path;
        }
      }
    }

    if (upcoming == null) {
      return null;
    }

    final double distance = upcoming.startDistanceMeters;
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km to segment start';
    }
    if (distance >= 1) {
      return '${distance.toStringAsFixed(0)} m to segment start';
    }
    return 'Segment start nearby';
  }

  SegmentDebugPath? _firstPathMatching(
    Iterable<SegmentDebugPath> paths,
    bool Function(SegmentDebugPath) predicate,
  ) {
    for (final path in paths) {
      if (predicate(path)) {
        return path;
      }
    }
    return null;
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
    }

    setState(() {});
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
                        tooltip: 'Open menu',
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
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync'),
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
              title: const Text('Segments'),
              onTap: _onSegmentsSelected,
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
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

  void _onProfileSelected() {
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
                title: const Text('Log in'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(AppRoutes.login);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Create an account'),
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
        const SnackBar(
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
      final message = _buildSyncSuccessMessage(result);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on TollSegmentsSyncException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error, stackTrace) {
      debugPrint('Failed to sync toll segments: $error\n$stackTrace');
      messenger.showSnackBar(
        const SnackBar(
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

  String _buildSyncSuccessMessage(TollSegmentsSyncResult result) {
    return AppMessages.syncCompleteSummary(
      addedSegments: result.addedSegments,
      removedSegments: result.removedSegments,
      totalSegments: result.totalSegments,
      approvedLocalSegments: result.approvedLocalSegments,
    );
  }
}
