// lib/widgets/toll_cameras_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Minimal interface your page can satisfy. If you already have a type for this,
/// replace [TollCamerasState] with it.
class TollCamerasState {
  final String? error;
  final bool isLoading;
  final List<LatLng> visibleCameras;

  const TollCamerasState({
    required this.error,
    required this.isLoading,
    required this.visibleCameras,
  });
}

/// Draws either an error banner or the markers for toll cameras.
/// Returns nothing when loading.
class TollCamerasOverlay extends StatelessWidget {
  final TollCamerasState cameras;
  final Alignment errorAlignment;
  final EdgeInsets errorMargin;
  final EdgeInsets errorPadding;

  /// Optional: customize the marker widget (e.g., to use an asset).
  final Widget Function(BuildContext, LatLng)? markerBuilder;

  const TollCamerasOverlay({
    super.key,
    required this.cameras,
    this.errorAlignment = Alignment.topCenter,
    this.errorMargin = const EdgeInsets.only(top: 30),
    this.errorPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.markerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Error banner
    if (cameras.error != null) {
      return Align(
        alignment: errorAlignment,
        child: Container(
          margin: errorMargin,
          padding: errorPadding,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            cameras.error!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Loading: render nothing
    if (cameras.isLoading) {
      return const SizedBox.shrink();
    }

    // Marker layer
    return MarkerLayer(
      markers: cameras.visibleCameras.map((p) {
        return Marker(
          point: p,
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: markerBuilder?.call(context, p) ??
              const Icon(
                Icons.videocam,
                size: 24,
                color: Colors.deepOrangeAccent,
              ),
        );
      }).toList(),
    );
  }
}
