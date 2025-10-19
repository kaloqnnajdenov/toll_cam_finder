import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DraggableMapMarker extends StatefulWidget {
  const DraggableMapMarker({
    super.key,
    required this.child,
    required this.mapKey,
    required this.mapController,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Widget child;
  final GlobalKey mapKey;
  final MapController mapController;
  final ValueChanged<LatLng> onDragStart;
  final ValueChanged<LatLng> onDragUpdate;
  final ValueChanged<LatLng> onDragEnd;

  @override
  State<DraggableMapMarker> createState() => _DraggableMapMarkerState();
}

class _DraggableMapMarkerState extends State<DraggableMapMarker> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      child: widget.child,
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final latLng = _positionToLatLng(details.globalPosition);
    if (latLng == null) {
      return;
    }
    widget.onDragStart(latLng);
    setState(() {
      _dragging = true;
    });
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_dragging) return;
    final latLng = _positionToLatLng(details.globalPosition);
    if (latLng == null) {
      return;
    }
    widget.onDragUpdate(latLng);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_dragging) return;
    final latLng = _positionToLatLng(details.globalPosition);
    if (latLng != null) {
      widget.onDragEnd(latLng);
    }
    setState(() {
      _dragging = false;
    });
  }

  LatLng? _positionToLatLng(Offset globalPosition) {
    final mapContext = widget.mapKey.currentContext;
    if (mapContext == null) return null;
    final renderObject = mapContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final localOffset = renderObject.globalToLocal(globalPosition);
    return widget.mapController.camera.screenOffsetToLatLng(localOffset);
  }
}
