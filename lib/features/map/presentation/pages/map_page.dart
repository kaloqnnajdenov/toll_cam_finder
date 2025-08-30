import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  // ------------------ external deps/services ------------------
  final _mapController = MapController();
  final _permissionService = PermissionService();
  final _locationService = LocationService();
  final _mapService = MapControllerFacade();

  // ------------------ map + user state ------------------
  LatLng _center = const LatLng(42.6977, 23.3219);
  LatLng? _userLatLng; // latest GPS fix (target)
  bool _mapReady = false;

  bool _followUser = false;
  double _currentZoom = 13;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<MapEvent>? _mapEvtSub;

  // ------------------ animation for blue dot ------------------
  late final AnimationController _anim;
  late final Animation<double> _curve;
  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  DateTime? _lastFixAt;

  static const int _minMs = 200;
  static const int _maxMs = 1200;
  static const double _fillRatio = 0.85;

  LatLng? get _animatedLatLng {
    if (_latTween == null || _lngTween == null) return _userLatLng;
    final t = _curve.value;
    return LatLng(_latTween!.transform(t), _lngTween!.transform(t));
  }

  // ------------------ toll cameras data ------------------
  static const String _camerasAsset = 'assets/data/toll_cameras_points.geojson';

  // All camera points loaded from GeoJSON
  List<LatLng> _allCameras = [];
  // Cameras currently inside (or near) the viewport
  List<LatLng> _visibleCameras = [];
  bool _camerasLoading = true;
  String? _camerasError;

  // expand bounds slightly so markers at the edge don't pop
  static const double _boundsPaddingDeg = 0.05;

  @override
  void initState() {
    super.initState();

    // blue-dot animation
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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

  bool _isTinyMove(LatLng a, LatLng b) {
    // ~1 meter deadband
    const meterInDegrees = 1 / 111320.0;
    return (a.latitude - b.latitude).abs() < meterInDegrees &&
           (a.longitude - b.longitude).abs() < meterInDegrees;
  }

  void _animateMarkerTo(LatLng next) {
    final from = _animatedLatLng ?? _userLatLng ?? _center;
    if (_isTinyMove(from, next)) {
      _userLatLng = next;
      return;
    }

    _userLatLng = next;

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
    _followUser = true;
    _mapService.move(_mapController, target, _currentZoom < 16 ? 16 : _currentZoom);
  }

  // ------------------ load + filter cameras ------------------
  Future<void> _loadCameras() async {
    try {
      final jsonStr = await rootBundle.loadString(_camerasAsset);
      final obj = json.decode(jsonStr) as Map<String, dynamic>;
      final features = (obj['features'] as List?) ?? const [];

      final pts = <LatLng>[];
      for (final f in features) {
        final feat = (f as Map).cast<String, dynamic>();
        final geom = (feat['geometry'] as Map?)?.cast<String, dynamic>();
        if (geom == null) continue;
        if (geom['type'] != 'Point') continue;

        final coords = (geom['coordinates'] as List?) ?? const [];
        if (coords.length < 2) continue;

        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        pts.add(LatLng(lat, lon));
      }

      setState(() {
        _allCameras = pts;
        _camerasLoading = false;
      });

      _updateVisibleCameras();
    } catch (e) {
      setState(() {
        _camerasLoading = false;
        _camerasError = 'Failed to load cameras: $e';
      });
    }
  }

  void _updateVisibleCameras() {
    if (!_mapReady || _allCameras.isEmpty) {
      setState(() => _visibleCameras = _allCameras);
      return;
    }

    try {
      final cam = _mapController.camera;
      final b = cam.visibleBounds;
      final padded = _padBounds(b, _boundsPaddingDeg);

      final res = <LatLng>[];
      for (final p in _allCameras) {
        if (_boundsContains(padded, p)) res.add(p);
      }
      setState(() => _visibleCameras = res);
    } catch (_) {
      setState(() => _visibleCameras = _allCameras);
    }
  }

  LatLngBounds _padBounds(LatLngBounds b, double delta) {
    return LatLngBounds(
      LatLng(b.south - delta, b.west - delta),
      LatLng(b.north + delta, b.east + delta),
    );
  }

  bool _boundsContains(LatLngBounds b, LatLng p) {
    return p.latitude  >= b.south &&
           p.latitude  <= b.north &&
           p.longitude >= b.west &&
           p.longitude <= b.east;
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
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.yourcompany.yourapp',
          ),

          // ---------- TOLL CAMERAS ----------
          if (_camerasError != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _camerasError!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (!_camerasLoading)
            MarkerLayer(
              markers: _visibleCameras.map((p) {
                return Marker(
                  point: p,
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.videocam, // camera-like icon; swap for custom asset if desired
                    size: 24,
                    color: Colors.deepOrangeAccent,
                  ),
                );
              }).toList(),
            ),

          // ---------- BLUE DOT ----------
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
