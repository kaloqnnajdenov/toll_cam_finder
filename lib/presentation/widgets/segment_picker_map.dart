import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/presentation/widgets/base_tile_layer.dart';

class SegmentPickerMap extends StatefulWidget {
  const SegmentPickerMap({
    super.key,
    required this.startController,
    required this.endController,
  });

  final TextEditingController startController;
  final TextEditingController endController;

  @override
  State<SegmentPickerMap> createState() => _SegmentPickerMapState();
}

class _SegmentPickerMapState extends State<SegmentPickerMap> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;
  static const double _zoomStep = 1.0;
  late final MapController _mapController;
  final Distance _distance = const Distance();
  LatLng? _start;
  LatLng? _end;
  bool _mapReady = false;
  bool _updatingControllers = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _start = _parseLatLng(widget.startController.text);
    _end = _parseLatLng(widget.endController.text);
    widget.startController.addListener(_handleStartTextChanged);
    widget.endController.addListener(_handleEndTextChanged);
  }

  @override
  void dispose() {
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
          width: 60,
          height: 60,
          alignment: Alignment.topCenter,
          child: _SegmentMarker(label: 'A', color: theme.colorScheme.primary),
        ),
      );
    }

    if (_end != null) {
      markers.add(
        Marker(
          point: _end!,
          width: 60,
          height: 60,
          alignment: Alignment.topCenter,
          child: _SegmentMarker(label: 'B', color: theme.colorScheme.primary),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
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
                if (_start != null && _end != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_start!, _end!],
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
              right: 16,
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
          ],
        ),
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
    if (_updatingControllers) return;
    final parsed = _parseLatLng(widget.startController.text);
    if (parsed != _start) {
      setState(() {
        _start = parsed;
      });
      _fitCamera();
    }
  }

  void _handleEndTextChanged() {
    if (_updatingControllers) return;
    final parsed = _parseLatLng(widget.endController.text);
    if (parsed != _end) {
      setState(() {
        _end = parsed;
      });
      _fitCamera();
    }
  }

  void _updateStart(LatLng latLng) {
    setState(() {
      _start = latLng;
    });
    _writeToController(widget.startController, latLng);
  }

  void _updateEnd(LatLng latLng) {
    setState(() {
      _end = latLng;
    });
    _writeToController(widget.endController, latLng);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 2, height: 12, color: Colors.white),
      ],
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
