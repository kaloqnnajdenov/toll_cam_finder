import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';


class CandidateBoundsOverlay extends StatelessWidget {
  final List<SegmentGeometry> candidates;
  const CandidateBoundsOverlay({super.key, required this.candidates});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || candidates.isEmpty) return const SizedBox.shrink();

    final polygons = candidates.map((g) {
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
        borderColor: Colors.redAccent,
        borderStrokeWidth: 1.5,
        disableHolesBorder: true,
      );
    }).toList();

    return PolygonLayer(polygons: polygons);
  }
}
