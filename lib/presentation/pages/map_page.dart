import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';
import 'package:toll_cam_finder/presentation/widgets/avg_speed_dial.dart';
import 'package:toll_cam_finder/presentation/widgets/avg_speed_button.dart';
import 'package:toll_cam_finder/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/presentation/widgets/curretn_speed_dial.dart';
import 'package:toll_cam_finder/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

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

  // ------------------ segments index (Step 2) ------------------
  final _segIndex = SegmentIndexService.instance;
  bool _segmentsReady = false;
  List<SegmentGeometry> _debugCandidates = const [];
  List<LatLng> _debugQuerySquare = const [];
  DateTime? _lastSegLog;

  // ------------------ speed state (km/h with UI deadband) ------------------
  double? _speedKmh;
  static const double _uiDeadbandKmh = 1.0;

  final AverageSpeedController _avgCtrl = AverageSpeedController();

  @override
  void initState() {
    super.initState();

    // blue-dot animation
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeInOut)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    // map events (stop following on manual gesture, update visible cameras)
    _mapEvtSub = _mapController.mapEventStream.listen((evt) {
      _currentZoom = evt.camera.zoom;
      if (evt.source != MapEventSource.mapController) {
        if (_followUser) setState(() => _followUser = false);
      }
      _updateVisibleCameras();
      // per request: no candidate refresh on map moves (only GPS-driven)
    });

    _initLocation();
    _loadCameras();

    _unawaited(_initSegmentsIndex());
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapEvtSub?.cancel();
    _anim.dispose();
    _avgCtrl.dispose();
    super.dispose();
  }

  // ------------------ location init and stream ------------------
  Future<void> _initLocation() async {
    final hasPermission = await _permissionService.ensureLocationPermission();
    if (!hasPermission) return;

    final pos = await _locationService.getCurrentPosition();

    final v0 = pos.speed; // m/s
    var kmh0 = (v0.isFinite && v0 >= 0) ? v0 * 3.6 : 0.0;
    if (kmh0 < _uiDeadbandKmh) kmh0 = 0.0;
    _speedKmh = kmh0;

    final firstFix = LatLng(pos.latitude, pos.longitude);
    _userLatLng = firstFix;
    _center = firstFix;
    if (mounted) setState(() {});

    if (_mapReady) {
      _mapController.move(_center, AppConstants.zoomWhenFocused);
    }

    _posSub?.cancel();
    _posSub = _locationService.getPositionStream().listen((p) {
      final sp = p.speed;
      double shownKmh = (sp.isFinite && sp >= 0) ? sp * 3.6 : 0.0;
      if (shownKmh < _uiDeadbandKmh) shownKmh = 0.0;
      if (mounted) setState(() => _speedKmh = shownKmh);

      _avgCtrl.addSample(shownKmh);

      final next = LatLng(p.latitude, p.longitude);
      _animateMarkerTo(next);

      // ---- Step 2: refresh candidates around GPS dot ----
      if (kDebugMode && _segmentsReady) {
        _refreshCandidatesAroundGps(next);
      }

      if (_followUser) {
        final followPoint = _animatedLatLng ?? next;
        _mapController.move(followPoint, _currentZoom);
      }
    });
  }

  // Build candidates around the given GPS position and compute the query square
  void _refreshCandidatesAroundGps(LatLng gps, {String reason = 'gps'}) {
    final sw = Stopwatch()..start();
    final cands = _segIndex.candidatesNearLatLng(
      gps,
      radiusMeters: AppConstants.candidateRadiusMeters,
    );
    sw.stop();

    _debugCandidates = cands;
    _debugQuerySquare = _computeQuerySquare(gps, AppConstants.candidateRadiusMeters);

    // throttle logs to 1/s
    final now = DateTime.now();
    if (_lastSegLog == null || now.difference(_lastSegLog!) > const Duration(seconds: 1)) {
      debugPrint(
        '[SEGIDX/$reason] ${cands.length} candidates in ${sw.elapsedMicroseconds}µs '
        '@ ${gps.latitude.toStringAsFixed(5)},${gps.longitude.toStringAsFixed(5)} '
        '(r=${AppConstants.candidateRadiusMeters.toInt()}m)',
      );
      _lastSegLog = now;
    }

    if (mounted) setState(() {});
  }

  // Compute a square ~radiusMeters around a center in lat/lon degrees
  List<LatLng> _computeQuerySquare(LatLng c, double radiusMeters) {
    const mPerDegLat = 111320.0;
    final mPerDegLon = (mPerDegLat * math.cos(c.latitude * math.pi / 180.0))
        .clamp(1e-9, double.infinity);
    final dLat = radiusMeters / mPerDegLat;
    final dLon = radiusMeters / mPerDegLon;

    final minLat = c.latitude - dLat;
    final maxLat = c.latitude + dLat;
    final minLon = c.longitude - dLon;
    final maxLon = c.longitude + dLon;

    return <LatLng>[
      LatLng(minLat, minLon),
      LatLng(minLat, maxLon),
      LatLng(maxLat, maxLon),
      LatLng(maxLat, minLon),
      LatLng(minLat, minLon),
    ];
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
    if (mounted) setState(() {});
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
    if (mounted) {
      setState(() {
        _cameras.updateVisible(bounds: bounds);
      });
    }
  }

  // ------------------ segments index bootstrap ------------------
  Future<void> _initSegmentsIndex() async {
    await _segIndex.tryLoadFromDefaultAsset(
      assetPath: 'assets/data/toll_segments.geojson',
    );
    if (mounted && _segIndex.isReady) {
      setState(() => _segmentsReady = true);
      if (kDebugMode) debugPrint('[SEGIDX] index ready');
      // If we already have a location, seed once around GPS
      if (_userLatLng != null && kDebugMode) {
        _refreshCandidatesAroundGps(_userLatLng!, reason: 'seed');
      }
    } else {
      if (kDebugMode) {
        debugPrint('[SEGIDX] not ready — missing asset or parse failure.');
      }
    }
  }

  void _unawaited(Future<void> f) {}

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
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _currentZoom,
              onMapReady: () {
                _mapReady = true;
                if (_userLatLng != null) {
                  _mapController.move(
                    _userLatLng!,
                    AppConstants.zoomWhenFocused,
                  );
                  _currentZoom = AppConstants.zoomWhenFocused;
                }
                _updateVisibleCameras();
              },
            ),
            children: [
              // Base map first
              const BaseTileLayer(),

              // Your GPS dot
              BlueDotMarker(point: markerPoint),

              // DEBUG: query square (border-only so it never hides markers)
              if (kDebugMode && _debugQuerySquare.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _debugQuerySquare,
                      color: Colors.transparent, // border only
                      borderColor: Colors.blue,
                      borderStrokeWidth: 1.5,
                      disableHolesBorder: true,
                    ),
                  ],
                ),

              // DEBUG: candidate segment rectangles (blue)
              if (kDebugMode && _debugCandidates.isNotEmpty)
                _buildCandidateBoundsOverlay(),

              // IMPORTANT: cameras last so they render on top
              TollCamerasOverlay(cameras: cameraState),
            ],
          ),

          // Top-left dials, stacked and safe
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CurrentSpeedDial(speedKmh: _speedKmh, unit: 'km/h'),
                  const SizedBox(height: 12),
                  AverageSpeedDial(controller: _avgCtrl, unit: 'km/h'),

                  // tiny debug badge
                  if (kDebugMode)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Segments: ${_debugCandidates.length}  '
                        'r=${AppConstants.candidateRadiusMeters.toInt()}m',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Right-side FABs: Recenter + Start/Reset Avg
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'recenter_btn',
            onPressed: _onResetView,
            icon: Icon(
              _followUser ? Icons.my_location : Icons.my_location_outlined,
            ),
            label: const Text('Recenter'),
          ),
          const SizedBox(height: 12),
          AverageSpeedButton(controller: _avgCtrl),
        ],
      ),
    );
  }

  // ------------------ Candidate bbox overlay (blue) ------------------
  Widget _buildCandidateBoundsOverlay() {
    final polygons = _debugCandidates.map((g) {
      final b = g.bounds;
      final pts = <LatLng>[
        LatLng(b.minLat, b.minLon),
        LatLng(b.minLat, b.maxLon),
        LatLng(b.maxLat, b.maxLon),
        LatLng(b.maxLat, b.minLon),
        LatLng(b.minLat, b.minLon),
      ];
      return Polygon(
        points: pts,
        color: Colors.transparent,
        borderColor: Colors.blueAccent,   // BLUE candidate rectangles
        borderStrokeWidth: 1.8,
        disableHolesBorder: true,
      );
    }).toList();

    return PolygonLayer(polygons: polygons);
  }
}
