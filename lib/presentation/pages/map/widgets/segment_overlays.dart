import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

import 'segment_debug_styles.dart';

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

class SegmentTrackerOverlay extends StatelessWidget {
  const SegmentTrackerOverlay({
    super.key,
    required this.snapshot,
    required this.startGeofenceRadiusMeters,
  });

  final SegmentTrackerDebugSnapshot snapshot;
  final double startGeofenceRadiusMeters;

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];
    final circles = <CircleMarker>[];

    SegmentTrackerDebugMatch? bestMatch;
    for (final match in snapshot.matches) {
      final points = _toLatLng(match.segment.path);
      if (points.length < 2) continue;
      final isActive = snapshot.activeSegment?.id == match.segment.id;
      final color = SegmentDebugStyles.colorForMatch(match, isActive: isActive);
      final stroke = SegmentDebugStyles.strokeWidthForMatch(match, isActive: isActive);
      polylines.add(
        Polyline(
          points: points,
          strokeWidth: stroke,
          color: color.withOpacity(isActive || match.isBestCandidate ? 0.95 : 0.6),
          isDotted: !match.onPath && !match.geofenceHit,
        ),
      );
      if (match.isBestCandidate) {
        bestMatch = match;
      }
    }

    final activeSegment = snapshot.activeSegment;
    if (activeSegment != null &&
        !snapshot.matches.any((m) => m.segment.id == activeSegment.id)) {
      final points = _toLatLng(activeSegment.path);
      if (points.length >= 2) {
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 6,
            color: Colors.greenAccent.withOpacity(0.9),
          ),
        );
      }
    }

    final exited = snapshot.exitedSegment;
    if (exited != null) {
      final points = _toLatLng(exited.path);
      if (points.length >= 2) {
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 4,
            isDotted: true,
            color: Colors.redAccent.withOpacity(0.65),
          ),
        );
      }
    }

    final drawnCircles = <String>{};
    void addCircle(SegmentGeometry segment, Color color, double fillOpacity) {
      if (drawnCircles.contains(segment.id)) return;
      drawnCircles.add(segment.id);
      final start = segment.path.first;
      circles.add(
        CircleMarker(
          point: LatLng(start.lat, start.lon),
          radius: startGeofenceRadiusMeters,
          useRadiusInMeter: true,
          color: color.withOpacity(fillOpacity),
          borderColor: color.withOpacity(0.85),
          borderStrokeWidth: 1.5,
        ),
      );
    }

    if (activeSegment != null) {
      addCircle(activeSegment, Colors.greenAccent, 0.08);
    }

    if (bestMatch != null &&
        (activeSegment == null || activeSegment.id != bestMatch.segment.id)) {
      addCircle(bestMatch.segment, Colors.blueAccent, 0.08);
    }

    if (exited != null) {
      addCircle(exited, Colors.redAccent, 0.05);
    }

    final layers = <Widget>[];
    if (polylines.isNotEmpty) {
      layers.add(PolylineLayer(polylines: polylines));
    }
    if (circles.isNotEmpty) {
      layers.add(CircleLayer(circles: circles));
    }

    if (layers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(children: layers);
  }

  List<LatLng> _toLatLng(List<GeoPoint> path) {
    return path.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);
  }
}