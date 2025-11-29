import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/widgets/segment_handover_banner.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/widgets/speed_limit_sign.dart';
import 'package:toll_cam_finder/features/segments/domain/controllers/current_segment_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/weigh_station_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/base_tile_layer.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/blue_dot_marker.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/features/map/presentation/widgets/weigh_stations_overlay.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.initialZoom,
    required this.onMapReady,
    required this.markerPoint,
    required this.visibleSegmentPolylines,
    required this.currentSegment,
    required this.showWeighStations,
    required this.weighStationsState,
    required this.onWeighStationLongPress,
    required this.cameraState,
    required this.osmSpeedLimitKph,
    required this.speedKmh,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final VoidCallback onMapReady;
  final LatLng? markerPoint;
  final List<Polyline> visibleSegmentPolylines;
  final CurrentSegmentController currentSegment;
  final bool showWeighStations;
  final WeighStationsState weighStationsState;
  final ValueChanged<WeighStationMarker> onWeighStationLongPress;
  final TollCamerasState cameraState;
  final String? osmSpeedLimitKph;
  final double? speedKmh;

  @override
  Widget build(BuildContext context) {
    final marker = markerPoint;
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            cameraConstraint: CameraConstraint.contain(
              bounds: AppConstants.europeBounds,
            ),
            onMapReady: onMapReady,
          ),
          children: [
            const BaseTileLayer(),
            if (marker != null) BlueDotMarker(point: marker),
            if (visibleSegmentPolylines.isNotEmpty)
              PolylineLayer(polylines: visibleSegmentPolylines),
            if (showWeighStations)
              WeighStationsOverlay(
                visibleStations: weighStationsState.visibleStations,
                onMarkerLongPress: onWeighStationLongPress,
              ),
            TollCamerasOverlay(cameras: cameraState),
          ],
        ),
        if (currentSegment.handoverStatus != null)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SegmentHandoverBanner(
                status: currentSegment.handoverStatus!,
                margin: const EdgeInsets.only(top: 16),
              ),
            ),
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: SpeedLimitSign(
                speedLimit: osmSpeedLimitKph,
                currentSpeedKmh: speedKmh,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Builder(
                builder: (context) {
                  final ScaffoldState? scaffoldState = Scaffold.maybeOf(
                    context,
                  );
                  final bool isDrawerOpen =
                      scaffoldState?.isEndDrawerOpen ?? false;
                  final Color backgroundColor = isDrawerOpen
                      ? palette.primary
                      : palette.surface.withOpacity(isDark ? 0.7 : 0.92);
                  final Color iconColor = isDrawerOpen
                      ? Colors.white
                      : palette.onSurface;
                  final BorderSide borderSide = BorderSide(
                    color: isDrawerOpen
                        ? Colors.transparent
                        : palette.divider.withOpacity(isDark ? 1 : 0.7),
                    width: 1,
                  );

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: backgroundColor,
                      shape: CircleBorder(side: borderSide),
                      child: IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: Icon(Icons.menu, color: iconColor),
                        tooltip: AppLocalizations.of(context).openMenu,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
