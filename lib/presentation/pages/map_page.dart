import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/speed_smoother.dart';

import '../../services/location_service.dart';
import '../../services/permission_service.dart';
import 'map/blue_dot_animator.dart';
import 'map/map_heading_controller.dart';
import 'map/segment_debugger.dart';
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
  // External services
  final MapController _mapController = MapController();
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();

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
  late final MapHeadingController _headingController;
  final AverageSpeedController _avgCtrl = AverageSpeedController();
  final SpeedSmoother _speedSmoother = SpeedSmoother();
  final TollCameraController _cameraController = TollCameraController();
  final SegmentDebugger _segmentDebugger = SegmentDebugger(
    SegmentIndexService.instance,
  );

  double? _speedKmh;

  @override
  void initState() {
    super.initState();

    _headingController = MapHeadingController(mapController: _mapController)
      ..addListener(_onHeadingChanged);

    _blueDotAnimator = BlueDotAnimator(
      vsync: this,
      onTick: () {
        if (mounted) setState(() {});
      },
    );

    _mapEvtSub = _mapController.mapEventStream.listen(_onMapEvent);
    _initLocation();
    _loadCameras();
    unawaited(_initSegmentsIndex());
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _headingController.removeListener(_onHeadingChanged);
    _headingController.dispose();
    _blueDotAnimator.dispose();
    _avgCtrl.dispose();
    super.dispose();
  }

  void _onHeadingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.ensureLocationPermission();
    if (!hasPermission) return;
    _speedSmoother.reset();
    final pos = await _locationService.getCurrentPosition();

    final firstKmh = _normalizeSpeed(pos.speed);
    _speedKmh = _speedSmoother.next(firstKmh);
    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
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
    _headingController.updateHeading(
      previous: previous,
      next: next,
      rawHeading: position.heading,
      speedKmh: smoothedKmh,
    );

    if (kDebugMode && _segmentDebugger.isReady) {
      _segmentDebugger.refresh(next);
    }

    if (!mounted) return;

    setState(() {
      _speedKmh = smoothedKmh;
    });

    if (_followUser) {
      final followPoint = _blueDotAnimator.position ?? next;
      _mapController.move(followPoint, _currentZoom);
    }
  }

  void _moveBlueDot(LatLng next) {
    final from = _blueDotAnimator.position ?? _userLatLng ?? _center;
    _userLatLng = next;
    _blueDotAnimator.animate(from: from, to: next);
  }

  double _normalizeSpeed(double metersPerSecond) {
    if (!metersPerSecond.isFinite || metersPerSecond < 0) return 0.0;
    final kmh = metersPerSecond * 3.6;
    return kmh < MapHeadingController.speedDeadbandKmh ? 0.0 : kmh;
  }

  void _onMapEvent(MapEvent evt) {
    _currentZoom = evt.camera.zoom;
    final bool external = evt.source != MapEventSource.mapController;
    final double rotation = evt.camera.rotation;

    _headingController.updateRotationFromMap(rotation);

    bool shouldSetState = false;

    if (external && _followUser) {
      _followUser = false;
      shouldSetState = true;
    }

    if (external && _headingController.followHeading) {
      _headingController.disableFollowHeading();
    }

    if (shouldSetState && mounted) {
      setState(() {});
    }

    _updateVisibleCameras();
  }

  // ------------------ reset view button ------------------
  void _onMapReady() {
    _mapReady = true;
    _headingController.onMapReady();
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

  void _toggleFollowHeading() {
    final bool enable = !_headingController.followHeading;
    if (enable) {
      if (mounted) {
        setState(() {
          _followUser = true;
        });
      } else {
        _followUser = true;
      }
    }

    if (enable) {
      _headingController.enableFollowHeading();
      if (_mapReady) {
        _onResetView();
      }
      _headingController.forceRotateToLastHeading();
    } else {
      _headingController.disableFollowHeading(resetRotation: true);
    }
  }

  Future<void> _loadCameras() async {
    await _cameraController.loadFromAsset(AppConstants.camerasAsset);
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
    final ready = await _segmentDebugger.initialise(
      assetPath: 'assets/data/toll_segments.geojson', //TODO: set in constants
    );
    if (!mounted || !ready) return;

    if (kDebugMode && _userLatLng != null) {
      _segmentDebugger.refresh(_userLatLng!, reason: 'seed');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final markerPoint = _blueDotAnimator.position ?? _userLatLng;
    final cameraState = _cameraController.state;

    return Scaffold(
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

              if (kDebugMode && _segmentDebugger.querySquare.isNotEmpty)
                QuerySquareOverlay(points: _segmentDebugger.querySquare),
              if (kDebugMode && _segmentDebugger.candidates.isNotEmpty)
                CandidateBoundsOverlay(candidates: _segmentDebugger.candidates),
              TollCamerasOverlay(cameras: cameraState),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: MapControlsPanel(
                speedKmh: _speedKmh,
                avgController: _avgCtrl,
                showDebugBadge: _segmentDebugger.isReady,
                segmentCount: _segmentDebugger.candidates.length,
                segmentRadiusMeters: AppConstants.candidateRadiusMeters,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: MapFabColumn(
        followUser: _followUser,
        onResetView: _onResetView,
        avgController: _avgCtrl,
        followHeading: _headingController.followHeading,
        onToggleHeading: _toggleFollowHeading,
        mapRotationDeg: _headingController.mapRotationDeg,
      ),
    );
  }
}
