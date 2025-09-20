import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';

class QuerySquareOverlay extends StatelessWidget {
  const QuerySquareOverlay({
    super.key,
    required this.points,
  });

  final List<LatLng> points;

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: points,
          color: Colors.transparent,
          borderColor: Colors.blue,
          borderStrokeWidth: 1.5,
          disableHolesBorder: true,
        ),
      ],
    );
  }
}

class CandidateBoundsOverlay extends StatelessWidget {
  const CandidateBoundsOverlay({
    super.key,
    required this.candidates,
  });

  final List<SegmentGeometry> candidates;

  @override
  Widget build(BuildContext context) {
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
        borderColor: Colors.blueAccent,
        borderStrokeWidth: 1.8,
        disableHolesBorder: true,
      );
    }).toList();

    return PolygonLayer(polygons: polygons);
  }
}