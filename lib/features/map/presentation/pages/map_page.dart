import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/permission_service.dart';
import '../../services/location_service.dart';
import '../../services/map_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _permissionService = PermissionService();
  final _locationService = LocationService();
  final _mapService = MapControllerFacade();

  LatLng _center = const LatLng(42.6977, 23.3219);
  LatLng? _userLatLng; // latest GPS fix (target)
  bool _mapReady = false;

  // --- follow mode ---
  bool _followUser = false;
  double _currentZoom = 13;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<MapEvent>? _mapEvtSub;

  // --- animation state ---
  late final AnimationController _anim;
  late final Animation<double> _curve;
  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  DateTime? _lastFixAt;

  // clamps + ratio for adaptive duration
  static const int _minMs = 200;
  static const int _maxMs = 1200;
  static const double _fillRatio = 0.85;

  // current animated position (falls back to latest fix)
  LatLng? get _animatedLatLng {
    if (_latTween == null || _lngTween == null) return _userLatLng;
    final t = _curve.value;
    return LatLng(_latTween!.transform(t), _lngTween!.transform(t));
  }

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _curve.addListener(() {
      if (mounted) setState(() {}); // repaint marker along tween
    });

    // Listen for user gestures on the map; any manual movement disables follow.
    _mapEvtSub = _mapController.mapEventStream.listen((evt) {
      // Keep track of zoom so we preserve it when following.
      _currentZoom = evt.camera.zoom;

      // If the source is NOT the MapController (i.e., user gesture/animation), stop following.
      if (evt.source != MapEventSource.mapController) {
        if (_followUser) {
          setState(() => _followUser = false);
        }
      }
    });

    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _anim.dispose();
    super.dispose();
  }

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

      // If follow mode is enabled, keep camera centered on the (animated) position.
      if (_followUser) {
        final followPoint = _animatedLatLng ?? next;
        _mapService.move(_mapController, followPoint, _currentZoom);
      }
    });
  }

  bool _isTinyMove(LatLng a, LatLng b) {
    // ~1 meter deadband (approx; fine for jitter suppression)
    const meterInDegrees = 1 / 111320.0;
    return (a.latitude - b.latitude).abs() < meterInDegrees &&
           (a.longitude - b.longitude).abs() < meterInDegrees;
  }

  void _animateMarkerTo(LatLng next) {
    final from = _animatedLatLng ?? _userLatLng ?? _center;
    if (_isTinyMove(from, next)) {
      _userLatLng = next; // keep target fresh even if we skip anim
      return;
    }

    _userLatLng = next;

    // adaptive duration based on time since last fix
    final now = DateTime.now();
    int ms = 500;
    if (_lastFixAt != null) {
      final intervalMs = now.difference(_lastFixAt!).inMilliseconds;
      ms = (intervalMs * _fillRatio).toInt();
      if (ms < _minMs) ms = _minMs;
      if (ms > _maxMs) ms = _maxMs;
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

    // Enable follow mode and recenter once.
    _followUser = true;

    // If we already have a fix, center immediately; otherwise it will happen on first fix.
    _mapService.move(_mapController, target, _currentZoom < 16 ? 16 : _currentZoom);
  }

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
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.yourcompany.yourapp',
          ),
          if (markerPoint != null)
            MarkerLayer(markers: [
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
            ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onResetView,
        icon: Icon(_followUser ? Icons.my_location : Icons.my_location_outlined),
        label: Text(_followUser ? 'Following' : 'Reset view'),
      ),
    );
  }
}