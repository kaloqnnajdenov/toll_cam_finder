import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';

import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

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
class SegmentPolylineOverlay extends StatelessWidget {
  const SegmentPolylineOverlay({
    super.key,
    required this.paths,
    required this.startGeofenceRadius,
    required this.endGeofenceRadius,
  });

  final List<SegmentDebugPath> paths;
  final double startGeofenceRadius;
  final double endGeofenceRadius;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();

    final polylines = <Polyline>[];
    final geofencePolygons = <Polygon>[];
    final markers = <Marker>[];

    for (final path in paths) {
      final color = _resolveColor(path);
      polylines.add(
        Polyline(
          points: path.polyline,
          strokeWidth: path.isActive ? 5.0 : 3.0,
          color: color,
        ),
      );

      if (path.nearestPoint != null) {
        markers.add(
          Marker(
            point: path.nearestPoint!,
            width: 150,
            height: _estimateMarkerHeight(path),
            alignment: Alignment.topLeft,
            child: _SegmentDebugMarker(path: path, color: color),
          ),
        );
      }

      if (path.isActive && path.polyline.isNotEmpty) {
        final startPoly = _circlePolygon(
          center: path.polyline.first,
          radiusMeters: startGeofenceRadius,
          color: Colors.blueAccent,
        );
        if (startPoly != null) {
          geofencePolygons.add(startPoly);
        }
        final endPoly = _circlePolygon(
          center: path.polyline.last,
          radiusMeters: endGeofenceRadius,
          color: Colors.deepPurpleAccent,
        );
        if (endPoly != null) {
          geofencePolygons.add(endPoly);
        }
      }
    }

    return Stack(
      children: [
        if (geofencePolygons.isNotEmpty)
          PolygonLayer(polygons: geofencePolygons),
        PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }

  Color _resolveColor(SegmentDebugPath path) {
    if (path.isActive) {
      return Colors.redAccent.withOpacity(0.9);
    }
    if (path.isWithinTolerance) {
      return Colors.greenAccent.withOpacity(0.75);
    }
    return Colors.orangeAccent.withOpacity(0.65);
  }

  double _estimateMarkerHeight(SegmentDebugPath path) {
    var lineCount = 2; // id + distance
    if (path.remainingDistanceMeters.isFinite) {
      lineCount += 1;
    }
    // Tags are always present (at least approx/detailed), so count that line.
    lineCount += 1;

    const padding = 12.0; // container vertical padding
    const gapAndDot = 4.0 + 10.0; // SizedBox + indicator dot
    const lineHeight = 14.0;

    final estimated = (lineCount * lineHeight) + padding + gapAndDot + 6.0;
    return estimated.clamp(70.0, 140.0);
  }

  Polygon? _circlePolygon({
    required LatLng center,
    required double radiusMeters,
    required Color color,
  }) {
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      return null;
    }
    final points = _approximateCircle(center, radiusMeters, segments: 36);
    return Polygon(
      points: points,
      color: color.withOpacity(0.18),
      borderColor: color,
      borderStrokeWidth: 1.4,
    );
  }

  List<LatLng> _approximateCircle(
    LatLng center,
    double radiusMeters, {
    int segments = 32,
  }) {
    const double mPerDegLat = 111320.0;
    final double latRad = center.latitude * math.pi / 180.0;
    final double mPerDegLon = (mPerDegLat * math.cos(latRad)).clamp(1e-9, double.infinity);

    final pts = <LatLng>[];
    for (var i = 0; i <= segments; i++) {
      final double angle = 2 * math.pi * (i / segments);
      final double dx = math.cos(angle) * radiusMeters;
      final double dy = math.sin(angle) * radiusMeters;
      final double lat = center.latitude + (dy / mPerDegLat);
      final double lon = center.longitude + (dx / mPerDegLon);
      pts.add(LatLng(lat, lon));
    }
    return pts;
  }
}

class _SegmentDebugMarker extends StatelessWidget {
  const _SegmentDebugMarker({
    required this.path,
    required this.color,
  });

  final SegmentDebugPath path;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);
    final tags = <String>[
      path.isDetailed
          ? localizations.translate('segmentDebugTagDetailed')
          : localizations.translate('segmentDebugTagApprox'),
      if (path.startHit)
        localizations.translate('segmentDebugTagStart'),
      if (path.endHit) localizations.translate('segmentDebugTagEnd'),
    ];
    final separator = localizations.translate('segmentDebugTagSeparator');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle(
            style: textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ) ??
                const TextStyle(color: Colors.white, fontSize: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  path.id,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  localizations.translate(
                    'segmentDebugDistanceMeters',
                    {'distance': path.distanceMeters.toStringAsFixed(1)},
                  ),
                ),
                if (path.remainingDistanceMeters.isFinite)
                  Text(
                    localizations.translate(
                      'segmentDebugDistanceKilometersLeft',
                      {
                        'distance': (path.remainingDistanceMeters / 1000)
                            .toStringAsFixed(2),
                      },
                    ),
                  ),
                if (tags.isNotEmpty) Text(tags.join(separator)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: path.isActive ? Colors.redAccent : color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.2),
          ),
        ),
      ],
    );
  }
}