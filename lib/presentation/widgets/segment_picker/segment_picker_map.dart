import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/draggable_map_marker.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/map_action_button.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/map_hint_card.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/segment_marker.dart';
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

enum SegmentEndpoint {
  start,
  end,
}

class _SegmentPickerMapState extends State<SegmentPickerMap> {
  late final MapController _mapController;
  final GlobalKey _mapKey = GlobalKey();
  late final http.Client _httpClient;
  late final VoidCallback _startTextListener;
  late final VoidCallback _endTextListener;
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
    _startTextListener = () => _handleTextChanged(SegmentEndpoint.start);
    _endTextListener = () => _handleTextChanged(SegmentEndpoint.end);
    widget.startController.addListener(_startTextListener);
    widget.endController.addListener(_endTextListener);
    _refreshRoute();
  }

  @override
  void dispose() {
    _routeRequestToken = null;
    _httpClient.close();
    widget.startController.removeListener(_startTextListener);
    widget.endController.removeListener(_endTextListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markers = SegmentEndpoint.values
        .map(
          (endpoint) => _buildEndpointMarker(
            endpoint,
            theme.colorScheme.primary,
          ),
        )
        .whereType<Marker>()
        .toList(growable: false);

    final routePoints = _routePoints ?? _defaultRoutePoints;

    final map = Stack(
      children: [
        FlutterMap(
          key: _mapKey,
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: AppConstants.initialZoom,
            minZoom: AppConstants.segmentPickerMinZoom,
            maxZoom: AppConstants.segmentPickerMaxZoom,
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
                    strokeWidth: AppConstants.segmentPickerPolylineWidth,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ],
              ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: AppConstants.segmentPickerOverlayInset,
          right: AppConstants.segmentPickerHintRightInset,
          top: AppConstants.segmentPickerOverlayInset,
          child: MapHintCard(
            hasStart: _start != null,
            hasEnd: _end != null,
          ),
        ),
        Positioned(
          right: AppConstants.segmentPickerOverlayInset,
          bottom: AppConstants.segmentPickerOverlayInset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapActionButton(
                icon: Icons.add,
                onPressed: () => _zoomBy(AppConstants.segmentPickerZoomStep),
              ),
              const SizedBox(height: AppConstants.segmentPickerZoomButtonSpacing),
              MapActionButton(
                icon: Icons.remove,
                onPressed: () => _zoomBy(-AppConstants.segmentPickerZoomStep),
              ),
              const SizedBox(height: AppConstants.segmentPickerZoomButtonSpacing),
              MapActionButton(
                icon: Icons.clear,
                onPressed: _clearEndpoints,
              ),
            ],
          ),
        ),
        Positioned(
          top: AppConstants.segmentPickerOverlayInset,
          right: AppConstants.segmentPickerOverlayInset,
          child: MapActionButton(
            icon:
                widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
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
      aspectRatio: AppConstants.segmentPickerInlineAspectRatio,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(AppConstants.segmentPickerClipRadius),
        child: map,
      ),
    );
  }

  Marker? _buildEndpointMarker(SegmentEndpoint endpoint, Color color) {
    final position = _getEndpoint(endpoint);
    if (position == null) {
      return null;
    }

    return Marker(
      point: position,
      width: AppConstants.segmentPickerMarkerOuterDiameter,
      height: AppConstants.segmentPickerMarkerOuterDiameter,
      alignment: Alignment.center,
      child: DraggableMapMarker(
        mapKey: _mapKey,
        mapController: _mapController,
        onDragStart: (latLng) =>
            _updateEndpoint(endpoint, latLng, refreshRoute: false),
        onDragUpdate: (latLng) =>
            _updateEndpoint(endpoint, latLng, refreshRoute: false),
        onDragEnd: (latLng) => _updateEndpoint(endpoint, latLng),
        child: SegmentMarker(
          label: endpoint == SegmentEndpoint.start
              ? AppMessages.segmentPickerStartMarkerLabel
              : AppMessages.segmentPickerEndMarkerLabel,
          color: color,
        ),
      ),
    );
  }

  LatLng get _initialCenter {
    return _end ?? _start ?? AppConstants.initialCenter;
  }

  List<LatLng>? get _defaultRoutePoints {
    if (_start == null || _end == null) {
      return null;
    }
    return <LatLng>[_start!, _end!];
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
      _updateEndpoint(SegmentEndpoint.start, latLng);
    } else if (_end == null) {
      _updateEndpoint(SegmentEndpoint.end, latLng);
    } else {
      final double distToStart = _distance(_start!, latLng);
      final double distToEnd = _distance(_end!, latLng);
      final endpoint =
          distToStart <= distToEnd ? SegmentEndpoint.start : SegmentEndpoint.end;
      _updateEndpoint(endpoint, latLng);
    }

    _fitCamera();
  }

  void _handleTextChanged(SegmentEndpoint endpoint) {
    if (_updatingControllers || _suspendUpdates) return;
    final controller = _controllerFor(endpoint);
    final parsed = _parseLatLng(controller.text);
    if (_positionsEqual(_getEndpoint(endpoint), parsed)) return;
    setState(() {
      _setEndpoint(endpoint, parsed);
    });
    _refreshRoute();
    _fitCamera();
  }

  void _updateEndpoint(
    SegmentEndpoint endpoint,
    LatLng latLng, {
    bool refreshRoute = true,
  }) {
    setState(() {
      _setEndpoint(endpoint, latLng);
      if (!refreshRoute) {
        final other = _getEndpoint(_oppositeEndpoint(endpoint));
        _routePoints = other != null ? <LatLng>[latLng, other] : null;
      }
    });
    _writeToController(_controllerFor(endpoint), latLng);
    if (refreshRoute) {
      _refreshRoute();
    }
  }

  void _clearEndpoints() {
    if (_start == null && _end == null) {
      return;
    }
    setState(() {
      _start = null;
      _end = null;
      _routePoints = null;
      _lastRouteStart = null;
      _lastRouteEnd = null;
      _routeRequestToken = null;
    });
    _clearController(widget.startController);
    _clearController(widget.endController);
    _mapController.move(AppConstants.initialCenter, AppConstants.initialZoom);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final targetZoom = (camera.zoom + delta)
        .clamp(AppConstants.segmentPickerMinZoom, AppConstants.segmentPickerMaxZoom);
    _mapController.move(camera.center, targetZoom);
  }

  void _writeToController(TextEditingController controller, LatLng latLng) {
    _setControllerText(controller, _formatLatLng(latLng));
  }

  void _clearController(TextEditingController controller) {
    _setControllerText(controller, '');
  }

  void _setControllerText(TextEditingController controller, String value) {
    _updatingControllers = true;
    controller.text = value;
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
    return _distance(a, b) < AppConstants.segmentPickerEqualityThresholdMeters;
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
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(AppConstants.segmentPickerCameraPadding),
      ),
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
    return '${value.latitude.toStringAsFixed(6)}, '
        '${value.longitude.toStringAsFixed(6)}';
  }

  LatLng? _getEndpoint(SegmentEndpoint endpoint) {
    return endpoint == SegmentEndpoint.start ? _start : _end;
  }

  void _setEndpoint(SegmentEndpoint endpoint, LatLng? value) {
    if (endpoint == SegmentEndpoint.start) {
      _start = value;
    } else {
      _end = value;
    }
  }

  SegmentEndpoint _oppositeEndpoint(SegmentEndpoint endpoint) {
    return endpoint == SegmentEndpoint.start
        ? SegmentEndpoint.end
        : SegmentEndpoint.start;
  }

  TextEditingController _controllerFor(SegmentEndpoint endpoint) {
    return endpoint == SegmentEndpoint.start
        ? widget.startController
        : widget.endController;
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
