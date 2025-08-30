import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/models/segment.dart';

class TollSegmentsLayer extends StatelessWidget {
  final List<TollSegment> segments;
  final double strokeWidth;
  final Color color;
  final double? zIndex;

  const TollSegmentsLayer({
    super.key,
    required this.segments,
    this.strokeWidth = 3.0,
    this.color = Colors.red,
    this.zIndex,
  });

  @override
  Widget build(BuildContext context) {
    final polylines = segments.map((s) {
      return Polyline(
        points: s.coords,
        strokeWidth: strokeWidth,
        color: color.withOpacity(0.85),
        pattern: const StrokePattern.dotted(),
      );
    }).toList();

    return PolylineLayer(
      polylines: polylines,
      minimumHitbox: 10,
      cullingMargin: 10, // helps a bit with performance
    );
  }
}
