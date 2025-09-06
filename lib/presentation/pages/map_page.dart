import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/presentation/widgets/toll_cameras_overlay.dart';
// NOTE: removed direct SpeedEstimator import here
// import 'package:toll_cam_finder/features/map/services/speed_estimator.dart';

import '../../services/permission_service.dart';
import '../../services/location_service.dart';
import '../../services/camera_utils.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  // ------------------ external deps/services ------------------
  final _mapController = MapController();
  final _permissionService = PermissionService();
  final _locationService = LocationService();

  // ------------------ map + user state ------------------
  LatLng _center = AppConstants.initialCenter;
  LatLng? _userLatLng;
  bool _mapReady = false;

  bool _followUser = false;
  double _currentZoom = AppConstants.initialZoom;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<MapEvent>? _mapEvtSub;

  // ------------------ animation for blue dot ------------------
  late final AnimationController _anim;
  late final Animation<double> _curve;
  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  DateTime? _lastFixAt;

  LatLng? get _animatedLatLng {
    if (_latTween == null || _lngTween == null) return _userLatLng;
    final t = _curve.value;
    return LatLng(_latTween!.transform(t), _lngTween!.transform(t));
  }

  // ------------------ toll cameras ------------------
  final CameraUtils _cameras = CameraUtils(boundsPaddingDeg: 0.05);

  // ------------------ speed state (km/h with UI deadband) ------------------
  double? _speedKmh;
  static const double _uiDeadbandKmh = 1.0; // show 0 below this

  @override
  void initState() {
    super.initState();

    // blue-dot animation
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _curve.addListener(() {
      if (mounted) setState(() {});
    });

    // map events (stop following on manual gesture, update visible cameras)
    _mapEvtSub = _mapController.mapEventStream.listen((evt) {
      _currentZoom = evt.camera.zoom;

      if (evt.source != MapEventSource.mapController) {
        if (_followUser) setState(() => _followUser = false);
      }
      _updateVisibleCameras();
    });

    _initLocation();
    _loadCameras();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  // ------------------ location init and stream ------------------
  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.ensureLocationPermission();
    if (!hasPermission) return;

    // Position is already fused/smoothed by LocationService (including speed)
    final pos = await _locationService.getCurrentPosition();

    final v0 = pos.speed; // m/s
    var kmh0 = (v0.isFinite && v0 >= 0) ? v0 * 3.6 : 0.0;
    if (kmh0 < _uiDeadbandKmh) kmh0 = 0.0;
    _speedKmh = kmh0;

    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
    setState(() {});

    if (_mapReady) _mapController.move(_center, AppConstants.zoomWhenFocused);

    _posSub?.cancel();
    _posSub = _locationService.getPositionStream().listen((p) {
      // p is already fused (speed in m/s)
      final sp = p.speed;
      double shownKmh = (sp.isFinite && sp >= 0) ? sp * 3.6 : 0.0;
      if (shownKmh < _uiDeadbandKmh) shownKmh = 0.0;
      if (mounted) setState(() => _speedKmh = shownKmh);

      final next = LatLng(p.latitude, p.longitude);
      _animateMarkerTo(next);

      if (_followUser) {
        final followPoint = _animatedLatLng ?? next;
        _mapController.move(followPoint, _currentZoom);
      }
    });
  }

  void _animateMarkerTo(LatLng next) {
    final from = _animatedLatLng ?? _userLatLng ?? _center;

    _userLatLng = next;

    final now = DateTime.now();
    int ms = 500;
    if (_lastFixAt != null) {
      final intervalMs = now.difference(_lastFixAt!).inMilliseconds;
      ms = (intervalMs * AppConstants.fillRatio).toInt();
      if (ms < AppConstants.minMs) ms = AppConstants.minMs;
      if (ms > AppConstants.maxMs) ms = AppConstants.maxMs;
    }
    _lastFixAt = now;

    _latTween = Tween<double>(begin: from.latitude, end: next.latitude);
    _lngTween = Tween<double>(begin: from.longitude, end: next.longitude);

    _anim
      ..duration = Duration(milliseconds: ms)
      ..stop()
      ..reset()
      ..forward();
  }

  // ------------------ reset view button ------------------
  void _onResetView() {
    LatLng target;
    if (_animatedLatLng != null) {
      target = _animatedLatLng!;
    } else if (_userLatLng != null) {
      target = _userLatLng!;
    } else {
      target = _center;
    }

    _followUser = true;

    double zoom = _currentZoom;
    if (_currentZoom < AppConstants.zoomWhenFocused) {
      zoom = AppConstants.zoomWhenFocused;
    }

    _mapController.move(target, zoom);
  }

  // ------------------ load + filter cameras via CameraUtils ------------------
  Future<void> _loadCameras() async {
    await _cameras.loadFromAsset(AppConstants.camerasAsset);
    setState(() {}); // reflect loading/error/all-cameras state
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
    setState(() {
      _cameras.updateVisible(bounds: bounds);
    });
  }

  // ------------------ build ------------------
  @override
  Widget build(BuildContext context) {
    final markerPoint = _animatedLatLng ?? _userLatLng;
    final cameraState = TollCamerasState(
      error: _cameras.error,
      isLoading: _cameras.isLoading,
      visibleCameras: _cameras.visibleCameras,
    );

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: _currentZoom,
          onMapReady: () {
            _mapReady = true;
            if (_userLatLng != null) {
              _mapController.move(_userLatLng!, AppConstants.zoomWhenFocused);
              _currentZoom = AppConstants.zoomWhenFocused;
            }
            _updateVisibleCameras();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.mapURL,
            userAgentPackageName: AppConstants.userAgentPackageName,
          ),
          TollCamerasOverlay(cameras: cameraState),
          BlueDotMarker(point: markerPoint),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onResetView,
        icon: Icon(
          _followUser ? Icons.my_location : Icons.my_location_outlined,
        ),
        label: Text(
          _speedKmh == null
              ? "Recenter"
              : (_speedKmh == 0.0
                  ? "Recenter • 0 km/h"
                  : "Recenter • ${_speedKmh!.toStringAsFixed(1)} km/h"),
        ),
      ),
    );
  }
}
