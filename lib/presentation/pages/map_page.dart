import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/speed_smoother.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

import '../../services/location_service.dart';
import '../../services/permission_service.dart';
import 'map/blue_dot_animator.dart';
import 'map/map_heading_controller.dart';
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
  StreamSubscription<CompassEvent>? _compassSub;

  // Helpers
  late final BlueDotAnimator _blueDotAnimator;
  late final MapHeadingController _headingController;
  final AverageSpeedController _avgCtrl = AverageSpeedController();
  final SpeedSmoother _speedSmoother = SpeedSmoother();
  final TollCameraController _cameraController = TollCameraController();
  final SegmentTracker _segmentTracker = SegmentTracker(
    indexService: SegmentIndexService.instance,
  );

  SegmentTrackerDebugData _segmentDebugData =
      const SegmentTrackerDebugData.empty();

  double? _lastSegmentAvgKmh;

  double? _speedKmh;
  double? _compassHeading;

  @override
  void initState() {
    super.initState();

    _headingController = MapHeadingController(mapController: _mapController)
      ..addListener(_onHeadingChanged);

    _blueDotAnimator = BlueDotAnimator(vsync: this, onTick: _onBlueDotTick);

    _mapEvtSub = _mapController.mapEventStream.listen(_onMapEvent);
    final compassStream = FlutterCompass.events;
    if (compassStream != null) {
      _compassSub = compassStream.listen(_handleCompassEvent);
    }
    _initLocation();
    _loadCameras();
    unawaited(_initSegmentsIndex());
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _compassSub?.cancel();
    _headingController.removeListener(_onHeadingChanged);
    _headingController.dispose();
    _blueDotAnimator.dispose();
    _avgCtrl.dispose();
    _segmentTracker.dispose();
    super.dispose();
  }

  void _onHeadingChanged() {
    if (!mounted) return;
    setState(() {});
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
    _headingController.updateCompassHeading(normalized);
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
    _headingController.updateHeading(
      previous: null,
      next: firstFix,
      rawHeading: pos.heading,
      speedKmh: _speedKmh ?? 0.0,
      headingAccuracyDeg: pos.headingAccuracy,
      compassHeading: _compassHeading,
    );
    final segEvent = _segmentTracker.handleLocationUpdate(
      current: firstFix,
      previous: null,
      rawHeading: pos.heading,
      speedKmh: _speedKmh,
      compassHeading: _compassHeading,
    );
    if (segEvent.startedSegment) {
      _lastSegmentAvgKmh = null;
      _avgCtrl.start();
    } else if (segEvent.endedSegment) {
      final double avgForSegment = _avgCtrl.average;
      _lastSegmentAvgKmh = avgForSegment.isFinite ? avgForSegment : null;
      _avgCtrl.reset();
    }
    _segmentDebugData = segEvent.debugData;
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
      headingAccuracyDeg: position.headingAccuracy,
      compassHeading: _compassHeading,
    );

    final segEvent = _segmentTracker.handleLocationUpdate(
      current: next,
      previous: previous,
      rawHeading: position.heading,
      speedKmh: smoothedKmh,
      compassHeading: _compassHeading,
    );
    if (segEvent.startedSegment) {
      _lastSegmentAvgKmh = null;
      _avgCtrl.start();
    } else if (segEvent.endedSegment) {
      final double avgForSegment = _avgCtrl.average;
      _lastSegmentAvgKmh = avgForSegment.isFinite ? avgForSegment : null;
      _avgCtrl.reset();
    }

    if (!mounted) return;

    setState(() {
      _speedKmh = smoothedKmh;
      _segmentDebugData = segEvent.debugData;
    });
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

    final LatLng desiredCenter = _headingController.followHeading
        ? _headingController.lookAheadTarget(userPosition: target)
        : target;

    _mapController.move(desiredCenter, camera.zoom);
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
    final ready = await _segmentTracker.initialise(
      assetPath: AppConstants.pathToTollSegments,
    );
    if (!mounted || !ready) return;

    if (_userLatLng != null) {
      final seedEvent = _segmentTracker.handleLocationUpdate(
        current: _userLatLng!,
        previous: null,
        rawHeading: null,
        speedKmh: _speedKmh,
        compassHeading: _compassHeading,
      );
      if (seedEvent.startedSegment) {
        _lastSegmentAvgKmh = null;
        _avgCtrl.start();
      } else if (seedEvent.endedSegment) {
        final double avgForSegment = _avgCtrl.average;
        _lastSegmentAvgKmh = avgForSegment.isFinite ? avgForSegment : null;
        _avgCtrl.reset();
      }
      _segmentDebugData = seedEvent.debugData;
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

              if (kDebugMode && _segmentDebugData.querySquare.isNotEmpty)
                QuerySquareOverlay(points: _segmentDebugData.querySquare),
              if (kDebugMode &&
                  _segmentDebugData.boundingCandidates.isNotEmpty)
                CandidateBoundsOverlay(
                  candidates: _segmentDebugData.boundingCandidates,
                ),
              if (kDebugMode &&
                  _segmentDebugData.candidatePaths.isNotEmpty)
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
                showDebugBadge: _segmentTracker.isReady,
                segmentCount: _segmentDebugData.candidateCount,
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
