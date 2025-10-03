import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/map_icon_button.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/segment_picker_map_full_screen_page.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/segment_picker_map_hint_card.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/segment_point_marker.dart';
import 'package:toll_cam_finder/services/osrm_path_fetcher.dart';

class SegmentPickerMap extends StatefulWidget {
  const SegmentPickerMap({
    super.key,
    required this.startController,
    required this.endController,
    this.isFullScreen = false,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final bool isFullScreen;

  @override
  State<SegmentPickerMap> createState() => _SegmentPickerMapState();
}

enum _SegmentPoint { start, end }

extension on _SegmentPoint {
  String get label => this == _SegmentPoint.start ? 'A' : 'B';
}

class _SegmentPickerMapState extends State<SegmentPickerMap> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;
  static const double _zoomStep = 1.0;
  late final MapController _mapController;
  late final http.Client _httpClient;
  final Distance _distance = const Distance();
  LatLng? _start;
  LatLng? _end;
  List<LatLng>? _routePoints;
  LatLng? _lastRouteStart;
  LatLng? _lastRouteEnd;
  Object? _routeRequestToken;
  bool _mapReady = false;
  bool _updatingControllers = false;
  bool _suspendUpdates = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _httpClient = http.Client();
    _start = _parseLatLng(widget.startController.text);
    _end = _parseLatLng(widget.endController.text);
    widget.startController.addListener(_handleStartTextChanged);
    widget.endController.addListener(_handleEndTextChanged);
    _refreshRoute();
  }

  @override
  void dispose() {
    _routeRequestToken = null;
    _httpClient.close();
    widget.startController.removeListener(_handleStartTextChanged);
    widget.endController.removeListener(_handleEndTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markers = _buildMarkers(theme);

    final routePoints = _routePoints ??
        (_start != null && _end != null ? <LatLng>[_start!, _end!] : null);

    final map = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: AppConstants.initialZoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            onTap: _handleMapTap,
            onMapReady: _handleMapReady,
          ),
          children: [
            const BaseTileLayer(),
            if (routePoints != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ],
              ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: 16,
          right: 72,
          top: 16,
          child: SegmentPickerMapHintCard(
            hasStart: _start != null,
            hasEnd: _end != null,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapIconButton(
                icon: Icons.add,
                onPressed: () => _zoomBy(_zoomStep),
              ),
              const SizedBox(height: 12),
              MapIconButton(
                icon: Icons.remove,
                onPressed: () => _zoomBy(-_zoomStep),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: MapIconButton(
            icon: widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: widget.isFullScreen ? _exitFullScreen : _openFullScreen,
          ),
        ),
      ],
    );

    if (widget.isFullScreen) {
      return SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: map,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: map,
      ),
    );
  }

  LatLng get _initialCenter {
    return _end ?? _start ?? AppConstants.initialCenter;
  }

  void _handleMapReady() {
    setState(() {
      _mapReady = true;
    });
    _fitCamera();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    if (!_mapReady) return;

    final start = _start;
    final end = _end;

    if (start == null) {
      _updatePoint(_SegmentPoint.start, latLng);
    } else if (end == null) {
      _updatePoint(_SegmentPoint.end, latLng);
    } else {
      final double distToStart = _distance(start, latLng);
      final double distToEnd = _distance(end, latLng);
      final target =
          distToStart <= distToEnd ? _SegmentPoint.start : _SegmentPoint.end;
      _updatePoint(target, latLng);
    }

    _fitCamera();
  }

  void _handleStartTextChanged() {
    _handleControllerChanged(_SegmentPoint.start);
  }

  void _handleEndTextChanged() {
    _handleControllerChanged(_SegmentPoint.end);
  }

  void _handleControllerChanged(_SegmentPoint point) {
    if (_updatingControllers || _suspendUpdates) return;
    final controller = _controllerFor(point);
    final parsed = _parseLatLng(controller.text);
    final current = _positionFor(point);
    if (_positionsEqual(current, parsed)) return;
    setState(() {
      _setPosition(point, parsed);
    });
    _refreshRoute();
    _fitCamera();
  }

  void _updatePoint(_SegmentPoint point, LatLng latLng) {
    setState(() {
      _setPosition(point, latLng);
    });
    _writeToController(_controllerFor(point), latLng);
    _refreshRoute();
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final targetZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, targetZoom);
  }

  void _writeToController(TextEditingController controller, LatLng latLng) {
    _updatingControllers = true;
    controller.text = _formatLatLng(latLng);
    _updatingControllers = false;
  }

  Future<void> _openFullScreen() async {
    if (widget.isFullScreen) return;
    _suspendUpdates = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SegmentPickerMapFullScreenPage(
          mapBuilder: (context) => SegmentPickerMap(
            startController: widget.startController,
            endController: widget.endController,
            isFullScreen: true,
          ),
        ),
      ),
    );
    if (!mounted) return;
    _suspendUpdates = false;
    _syncFromControllers();
  }

  void _exitFullScreen() {
    if (!widget.isFullScreen) return;
    Navigator.of(context).maybePop();
  }

  void _syncFromControllers() {
    setState(() {
      _setPosition(
        _SegmentPoint.start,
        _parseLatLng(widget.startController.text),
      );
      _setPosition(
        _SegmentPoint.end,
        _parseLatLng(widget.endController.text),
      );
    });
    _refreshRoute();
    _fitCamera();
  }

  Future<void> _refreshRoute() async {
    final start = _start;
    final end = _end;

    if (start == null || end == null) {
      setState(() {
        _routePoints = null;
        _lastRouteStart = null;
        _lastRouteEnd = null;
      });
      _routeRequestToken = null;
      return;
    }

    if (_routePoints != null &&
        _lastRouteStart != null &&
        _lastRouteEnd != null &&
        _positionsEqual(_lastRouteStart, start) &&
        _positionsEqual(_lastRouteEnd, end)) {
      return;
    }

    final fallback = <LatLng>[start, end];
    setState(() {
      _routePoints = fallback;
    });

    final token = Object();
    _routeRequestToken = token;

    final path = await fetchOsrmRoute(
      client: _httpClient,
      start: GeoPoint(start.latitude, start.longitude),
      end: GeoPoint(end.latitude, end.longitude),
    );

    if (!mounted || _routeRequestToken != token) {
      return;
    }

    setState(() {
      _lastRouteStart = start;
      _lastRouteEnd = end;
      if (path != null && path.length >= 2) {
        _routePoints =
            path.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);
      } else {
        _routePoints = fallback;
      }
    });
  }

  bool _positionsEqual(LatLng? a, LatLng? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    return _distance(a, b) < 0.5;
  }

  void _fitCamera() {
    if (!_mapReady) return;
    final points = [if (_start != null) _start!, if (_end != null) _end!];
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, _mapController.camera.zoom);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  LatLng? _parseLatLng(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    return LatLng(lat, lng);
  }

  String _formatLatLng(LatLng value) {
    return '${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}';
  }

  TextEditingController _controllerFor(_SegmentPoint point) {
    return point == _SegmentPoint.start
        ? widget.startController
        : widget.endController;
  }

  LatLng? _positionFor(_SegmentPoint point) {
    return point == _SegmentPoint.start ? _start : _end;
  }

  void _setPosition(_SegmentPoint point, LatLng? value) {
    if (point == _SegmentPoint.start) {
      _start = value;
    } else {
      _end = value;
    }
  }

  List<Marker> _buildMarkers(ThemeData theme) {
    final color = theme.colorScheme.primary;
    return _SegmentPoint.values
        .map((point) {
          final position = _positionFor(point);
          if (position == null) return null;
          return Marker(
            point: position,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: SegmentPointMarker(
              label: point.label,
              color: color,
            ),
          );
        })
        .whereType<Marker>()
        .toList(growable: false);
  }
}
