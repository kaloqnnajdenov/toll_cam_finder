import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/features/segments/presentation/widgets/segment_picker/draggable_map_marker.dart';
import 'package:toll_cam_finder/features/segments/presentation/widgets/segment_picker/map_action_button.dart';

class WeighStationPickerMap extends StatefulWidget {
  const WeighStationPickerMap({
    super.key,
    required this.coordinatesController,
  });

  final TextEditingController coordinatesController;

  @override
  State<WeighStationPickerMap> createState() => _WeighStationPickerMapState();
}

class _WeighStationPickerMapState extends State<WeighStationPickerMap> {
  late final MapController _mapController;
  final GlobalKey _mapKey = GlobalKey();
  LatLng? _point;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _point = _parseLatLng(widget.coordinatesController.text);
    widget.coordinatesController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.coordinatesController.removeListener(_handleTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marker = _buildMarker(theme.colorScheme.primary);

    final map = Stack(
      children: [
        FlutterMap(
          key: _mapKey,
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _point ?? AppConstants.initialCenter,
            initialZoom: AppConstants.initialZoom,
            minZoom: AppConstants.segmentPickerMinZoom,
            maxZoom: AppConstants.segmentPickerMaxZoom,
            onTap: _handleMapTap,
            onMapReady: _handleMapReady,
          ),
          children: [
            const BaseTileLayer(),
            if (marker != null) MarkerLayer(markers: [marker]),
          ],
        ),
        Positioned(
          left: AppConstants.segmentPickerOverlayInset,
          right: AppConstants.segmentPickerOverlayInset,
          top: AppConstants.segmentPickerOverlayInset,
          child: _WeighStationHint(hasPoint: _point != null),
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
                onPressed: _clearPoint,
              ),
            ],
          ),
        ),
      ],
    );

    return AspectRatio(
      aspectRatio: AppConstants.segmentPickerInlineAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.segmentPickerClipRadius),
        child: map,
      ),
    );
  }

  Marker? _buildMarker(Color color) {
    final point = _point;
    if (point == null) {
      return null;
    }

    return Marker(
      point: point,
      width: AppConstants.segmentPickerMarkerOuterDiameter,
      height: AppConstants.segmentPickerMarkerOuterDiameter,
      alignment: Alignment.center,
      child: DraggableMapMarker(
        mapKey: _mapKey,
        mapController: _mapController,
        onDragStart: _setPoint,
        onDragUpdate: _setPoint,
        onDragEnd: _setPoint,
        child: _WeighStationMarker(color: color),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    _setPoint(latLng);
  }

  void _handleMapReady() {
    _mapReady = true;
    if (_point != null) {
      _mapController.move(_point!, _mapController.camera.zoom);
    }
  }

  void _handleTextChanged() {
    if (!mounted) {
      return;
    }
    if (_suppressTextUpdate) {
      return;
    }
    final parsed = _parseLatLng(widget.coordinatesController.text);
    if (_pointsEqual(parsed, _point)) {
      return;
    }
    setState(() {
      _point = parsed;
    });
    if (parsed != null && _mapReady) {
      _mapController.move(parsed, _mapController.camera.zoom);
    }
  }

  bool _suppressTextUpdate = false;

  void _setPoint(LatLng? value) {
    setState(() {
      _point = value;
    });
    _updateController(value);
  }

  void _updateController(LatLng? value) {
    final formatted = value == null ? '' : _formatLatLng(value);
    if (widget.coordinatesController.text == formatted) {
      return;
    }
    _suppressTextUpdate = true;
    widget.coordinatesController.text = formatted;
    _suppressTextUpdate = false;
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + delta);
  }

  void _clearPoint() {
    _setPoint(null);
  }

  LatLng? _parseLatLng(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) {
      return null;
    }
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) {
      return null;
    }
    if (!lat.isFinite || !lng.isFinite) {
      return null;
    }
    return LatLng(lat, lng);
  }

  String _formatLatLng(LatLng value) {
    return '${value.latitude.toStringAsFixed(6)}, '
        '${value.longitude.toStringAsFixed(6)}';
  }

  bool _pointsEqual(LatLng? a, LatLng? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    final distance = const Distance().distance(a, b);
    return distance < AppConstants.segmentPickerEqualityThresholdMeters;
  }
}

class _WeighStationMarker extends StatelessWidget {
  const _WeighStationMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: AppConstants.segmentPickerMarkerShadowBlurRadius,
            offset: Offset(0, AppConstants.segmentPickerMarkerShadowOffsetY),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.scale,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _WeighStationHint extends StatelessWidget {
  const _WeighStationHint({required this.hasPoint});

  final bool hasPoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = hasPoint
        ? AppMessages.weighStationMapHintDrag
        : AppMessages.weighStationMapHintPlace;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface
            .withOpacity(AppConstants.segmentPickerSurfaceOpacity),
        borderRadius:
            BorderRadius.circular(AppConstants.segmentPickerHintCornerRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.segmentPickerHintHorizontalPadding,
          vertical: AppConstants.segmentPickerHintVerticalPadding,
        ),
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
