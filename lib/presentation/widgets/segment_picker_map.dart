import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
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
    final markers = <Marker>[];
    final theme = Theme.of(context);

    if (_start != null) {
      markers.add(
        Marker(
          point: _start!,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: _SegmentMarker(label: 'A', color: theme.colorScheme.primary),
        ),
      );
    }

    if (_end != null) {
      markers.add(
        Marker(
          point: _end!,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: _SegmentMarker(label: 'B', color: theme.colorScheme.primary),
        ),
      );
    }

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
          child: _MapHintCard(
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
              _ZoomButton(
                icon: Icons.add,
                onPressed: () => _zoomBy(_zoomStep),
              ),
              const SizedBox(height: 12),
              _ZoomButton(
                icon: Icons.remove,
                onPressed: () => _zoomBy(-_zoomStep),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _FullScreenButton(
            isFullScreen: widget.isFullScreen,
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

    if (_start == null) {
      _updateStart(latLng);
    } else if (_end == null) {
      _updateEnd(latLng);
    } else {
      final double distToStart = _distance(_start!, latLng);
      final double distToEnd = _distance(_end!, latLng);
      if (distToStart <= distToEnd) {
        _updateStart(latLng);
      } else {
        _updateEnd(latLng);
      }
    }

    _fitCamera();
  }

  void _handleStartTextChanged() {
    if (_updatingControllers || _suspendUpdates) return;
    final parsed = _parseLatLng(widget.startController.text);
    if (_positionsEqual(_start, parsed)) return;
    setState(() {
      _start = parsed;
    });
    _refreshRoute();
    _fitCamera();
  }

  void _handleEndTextChanged() {
    if (_updatingControllers || _suspendUpdates) return;
    final parsed = _parseLatLng(widget.endController.text);
    if (_positionsEqual(_end, parsed)) return;
    setState(() {
      _end = parsed;
    });
    _refreshRoute();
    _fitCamera();
  }

  void _updateStart(LatLng latLng) {
    setState(() {
      _start = latLng;
    });
    _writeToController(widget.startController, latLng);
    _refreshRoute();
  }

  void _updateEnd(LatLng latLng) {
    setState(() {
      _end = latLng;
    });
    _writeToController(widget.endController, latLng);
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
          startController: widget.startController,
          endController: widget.endController,
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
    final parsedStart = _parseLatLng(widget.startController.text);
    final parsedEnd = _parseLatLng(widget.endController.text);
    setState(() {
      _start = parsedStart;
      _end = parsedEnd;
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
}

class _SegmentMarker extends StatelessWidget {
  const _SegmentMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.onSurface),
        onPressed: onPressed,
      ),
    );
  }
}

class _FullScreenButton extends StatelessWidget {
  const _FullScreenButton({
    required this.isFullScreen,
    required this.onPressed,
  });

  final bool isFullScreen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: Icon(
          isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class SegmentPickerMapFullScreenPage extends StatelessWidget {
  const SegmentPickerMapFullScreenPage({
    super.key,
    required this.startController,
    required this.endController,
  });

  final TextEditingController startController;
  final TextEditingController endController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SegmentPickerMap(
          startController: startController,
          endController: endController,
          isFullScreen: true,
        ),
      ),
    );
  }
}

class _MapHintCard extends StatelessWidget {
  const _MapHintCard({required this.hasStart, required this.hasEnd});

  final bool hasStart;
  final bool hasEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    if (!hasStart && !hasEnd) {
      message = 'Tap anywhere on the map to place point A.';
    } else if (hasStart && !hasEnd) {
      message = 'Tap a second location to place point B.';
    } else {
      message = 'Tap near A or B to reposition that point.';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
