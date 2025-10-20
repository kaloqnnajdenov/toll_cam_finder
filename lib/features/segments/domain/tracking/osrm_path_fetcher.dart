import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/spatial/geo.dart';

/// Fetches detailed routes from the public OSRM API.
Future<List<GeoPoint>?> fetchOsrmRoute({
  required http.Client client,
  required GeoPoint start,
  required GeoPoint end,
  void Function(String message)? onDebug,
}) async {
  final uri = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/'
    '${start.lon},${start.lat};${end.lon},${end.lat}'
    '?overview=full&geometries=geojson',
  );

  const logLabel = '[OSM Routing]';
  final logMessage =
      '$logLabel Requesting route from ${start.lat.toStringAsFixed(6)}, '
      '${start.lon.toStringAsFixed(6)} '
      'to ${end.lat.toStringAsFixed(6)}, ${end.lon.toStringAsFixed(6)}';
  onDebug?.call(logMessage);
  if (kDebugMode) {
    debugPrint(logMessage);
  }

  try {
    final response = await client.get(uri, headers: const {
      'User-Agent': 'toll_cam_finder/segment-tracker',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      final statusMessage =
          '$logLabel Non-200 response (${response.statusCode}) for ${uri.path}';
      onDebug?.call(statusMessage);
      if (kDebugMode) {
        debugPrint(statusMessage);
      }
      return null;
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first;
    if (route is! Map<String, dynamic>) return null;

    dynamic geometry = route['geometry'];
    List? coords;
    if (geometry is Map<String, dynamic> && geometry['coordinates'] is List) {
      coords = geometry['coordinates'] as List;
    } else if (geometry is List) {
      coords = geometry;
    }
    if (coords == null) return null;

    final path = <GeoPoint>[];
    for (final coord in coords) {
      if (coord is List && coord.length >= 2) {
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        path.add(GeoPoint(lat, lon));
      }
    }

    if (path.length < 2) {
      return null;
    }

    final distance = const Distance();
    if (distance.as(
          LengthUnit.Meter,
          LatLng(path.first.lat, path.first.lon),
          LatLng(start.lat, start.lon),
        ) >
        5) {
      path.insert(0, start);
    }
    if (distance.as(
          LengthUnit.Meter,
          LatLng(path.last.lat, path.last.lon),
          LatLng(end.lat, end.lon),
        ) >
        5) {
      path.add(end);
    }

    return path;
  } catch (e) {
    final failureMessage = '$logLabel Failed to fetch enhanced path: $e';
    onDebug?.call(failureMessage);
    if (kDebugMode) {
      debugPrint(failureMessage);
    }
    return null;
  }
}
