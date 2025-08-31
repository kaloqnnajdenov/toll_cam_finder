import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// NOTE: rootBundle import no longer needed here after refactor
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toll_cam_finder/core/constants.dart';

import '../../services/permission_service.dart';
import '../../services/location_service.dart';
import '../../services/map_controller.dart';
import '../../services/camera_utils.dart'; // <-- NEW

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
  final _mapService = MapControllerFacade();

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

  // ------------------ toll cameras (moved to utils) ------------------
  final CameraUtils _cameras = CameraUtils(boundsPaddingDeg: 0.05);

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

    final pos = await _locationService.getCurrentPosition();
    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
    setState(() {});

    if (_mapReady) _mapService.move(_mapController, _center, 16);

    _posSub?.cancel();
    _posSub = _locationService.getPositionStream().listen((p) {
      final next = LatLng(p.latitude, p.longitude);
      _animateMarkerTo(next);

      if (_followUser) {
        final followPoint = _animatedLatLng ?? next;
        _mapService.move(_mapController, followPoint, _currentZoom);
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

  void _onResetView() {
    final target = _animatedLatLng ?? _userLatLng ?? _center;
    _followUser = true;

    double zoom = _currentZoom;
    if (_currentZoom < AppConstants.zoomWhenFocused) {
      zoom = AppConstants.zoomWhenFocused;
    }

    _mapService.move(_mapController, target, zoom);
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

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: _currentZoom,
          onMapReady: () {
            _mapReady = true;
            if (_userLatLng != null) {
              _mapService.move(_mapController, _userLatLng!, 16);
              _currentZoom = 16;
            }
            _updateVisibleCameras();
          },
        ),
        children: [
          // Replace with your offline tiles when ready
          TileLayer(
            urlTemplate: AppConstants.mapURL,
            userAgentPackageName: 'com.yourcompany.yourapp',
          ),

          // ---------- TOLL CAMERAS ----------
          if (_cameras.error != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _cameras.error!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (!_cameras.isLoading)
            MarkerLayer(
              markers: _cameras.visibleCameras.map((p) {
                return Marker(
                  point: p,
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.videocam, // camera-like icon; swap for custom asset if desired
                    size: 24,
                    color: Colors.deepOrangeAccent,
                  ),
                );
              }).toList(),
            ),

          // ---------- BLUE DOT ----------
          if (markerPoint != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: markerPoint,
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.25),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onResetView,
        icon: Icon(
          _followUser ? Icons.my_location : Icons.my_location_outlined,
        ),
        label: Text(_followUser ? 'Following' : 'Reset view'),
      ),
    );
  }
}
