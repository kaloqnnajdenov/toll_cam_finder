import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Retrieves speed limit information for the road surrounding a coordinate
/// using the OpenStreetMap Overpass API.
class OsmSpeedLimitService {
  OsmSpeedLimitService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const String _endpoint = 'https://overpass-api.de/api/interpreter';
  static const Duration _timeout = Duration(seconds: 10);
  static const double _mphToKmh = 1.60934;

  final http.Client _client;
  final bool _ownsClient;
  final Distance _distance = const Distance();

  /// Returns the speed limit in km/h for the given [location].
  ///
  /// Returns `null` when no speed limit could be determined.
  Future<String?> fetchSpeedLimit(LatLng location) async {
    final query = '''
[out:json][timeout:10];
(
  way(around:60,${location.latitude},${location.longitude})["highway"];
  node(around:40,${location.latitude},${location.longitude})["maxspeed"];
  node(around:40,${location.latitude},${location.longitude})["traffic_sign"~"maxspeed", i];
);
out tags geom qt;
''';

    final uri = Uri.parse('$_endpoint?data=${Uri.encodeComponent(query)}');
    const logLabel = '[OSM Overpass]';
    if (kDebugMode) {
      debugPrint(
        '$logLabel Requesting speed limit near '
        '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}',
      );
    }

    final response = await _client
        .get(uri, headers: {'User-Agent': 'toll_cam_finder/1.0'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('$logLabel Non-200 response (${response.statusCode})');
      }
      return null;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      if (kDebugMode) {
        debugPrint('$logLabel Failed to decode response body');
      }
      return null;
    }

    final elements = decoded['elements'];
    if (elements is! List || elements.isEmpty) {
      if (kDebugMode) {
        debugPrint('$logLabel No elements returned for this location');
      }
      return null;
    }

    _SpeedCandidate? bestWayCandidate;
    _SpeedCandidate? bestNodeCandidate;

    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final tagsRaw = element['tags'];
      if (tagsRaw is! Map) continue;
      final tags = tagsRaw.cast<String, dynamic>();

      final parsed = _extractMaxSpeed(tags);
      if (parsed == null) continue;

      final type = element['type'];
      if (type == 'way') {
        final distanceMeters = _distanceToWay(element, location);
        if (distanceMeters == null) continue;
        if (distanceMeters > _maxWayDistanceMeters) continue;
        final candidate = _SpeedCandidate(
          value: parsed.value,
          priority: parsed.priority,
          distanceMeters: distanceMeters,
        );
        if (bestWayCandidate == null ||
            _isBetterCandidate(candidate, bestWayCandidate!)) {
          bestWayCandidate = candidate;
        }
      } else if (type == 'node') {
        final distanceMeters = _distanceToNode(element, location);
        if (distanceMeters == null) continue;
        if (distanceMeters > _maxNodeDistanceMeters) continue;
        final candidate = _SpeedCandidate(
          value: parsed.value,
          priority: parsed.priority,
          distanceMeters: distanceMeters,
        );
        if (bestNodeCandidate == null ||
            _isBetterCandidate(candidate, bestNodeCandidate!)) {
          bestNodeCandidate = candidate;
        }
      }
    }

    final result = bestWayCandidate?.value ?? bestNodeCandidate?.value;
    if (kDebugMode) {
      if (result != null) {
        debugPrint('$logLabel Using speed limit $result km/h');
      } else {
        debugPrint('$logLabel Unable to determine speed limit');
      }
    }
    return result;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  _ParsedSpeed? _extractMaxSpeed(Map<String, dynamic> tags) {
    _ParsedSpeed? best;

    void consider(dynamic raw, {int basePriority = 0}) {
      if (raw is! String) return;
      final normalized = raw.trim();
      if (normalized.isEmpty) return;

      final parts = normalized.split(RegExp(r'[|;,]'));
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final parsed = _parseMaxSpeed(trimmed, basePriority: basePriority);
        if (parsed == null) continue;
        if (best == null || parsed.priority < best!.priority) {
          best = parsed;
        }
      }
    }

    consider(tags['maxspeed']);
    consider(tags['maxspeed:forward']);
    consider(tags['maxspeed:backward']);
    consider(tags['maxspeed:forward:conditional'], basePriority: 1);
    consider(tags['maxspeed:backward:conditional'], basePriority: 1);
    consider(tags['maxspeed:conditional'], basePriority: 1);
    consider(tags['maxspeed:lanes'], basePriority: 1);
    consider(tags['maxspeed:type'], basePriority: 2);
    consider(tags['source:maxspeed'], basePriority: 2);
    consider(tags['zone:maxspeed'], basePriority: 2);
    consider(tags['maxspeed:sign'], basePriority: 1);
    consider(tags['maxspeed:sign:forward'], basePriority: 1);
    consider(tags['maxspeed:sign:backward'], basePriority: 1);
    consider(tags['traffic_sign'], basePriority: 1);
    consider(tags['traffic_sign:forward'], basePriority: 1);
    consider(tags['traffic_sign:backward'], basePriority: 1);

    if (best == null) {
      for (final entry in tags.entries) {
        final key = entry.key;
        if (key.startsWith('maxspeed:') && key.endsWith(':conditional')) {
          consider(entry.value, basePriority: 2);
        }
      }
    }

    return best;
  }

  _ParsedSpeed? _parseMaxSpeed(String raw, {int basePriority = 0}) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized == 'none' || normalized == 'signals' ||
        normalized == 'variable') {
      return null;
    }

    final alias = _maxspeedAliases[normalized] ??
        (normalized.contains(':')
            ? _maxspeedAliases[normalized.substring(normalized.lastIndexOf(':') + 1)]
            : null);
    if (alias != null) {
      final value = alias.isMph ? alias.value * _mphToKmh : alias.value;
      return _ParsedSpeed(
        value.round().toString(),
        priority: basePriority + alias.priority,
      );
    }

    final cleaned = normalized.split('@').first.trim();
    final matches =
        RegExp(r'([0-9]+(?:\.[0-9]+)?)').allMatches(cleaned).toList();
    if (matches.isEmpty) {
      return null;
    }

    final match = matches.last;
    final number = double.tryParse(match.group(1)!);
    if (number == null) {
      return null;
    }

    double inKmh = number;
    if (cleaned.contains('mph') || cleaned.contains('mi/h')) {
      inKmh = number * _mphToKmh;
    }

    return _ParsedSpeed(inKmh.round().toString(), priority: basePriority);
  }

  bool _isBetterCandidate(_SpeedCandidate next, _SpeedCandidate current) {
    final nextDistance = next.distanceMeters ?? double.infinity;
    final currentDistance = current.distanceMeters ?? double.infinity;
    if ((nextDistance - currentDistance).abs() > _distanceEpsilonMeters) {
      return nextDistance < currentDistance;
    }
    return next.priority < current.priority;
  }

  double? _distanceToNode(Map<String, dynamic> element, LatLng origin) {
    final lat = element['lat'];
    final lon = element['lon'];
    if (lat is num && lon is num) {
      return _distance.as(
        LengthUnit.Meter,
        origin,
        LatLng(lat.toDouble(), lon.toDouble()),
      );
    }

    final center = element['center'];
    if (center is Map<String, dynamic>) {
      final centerLat = center['lat'];
      final centerLon = center['lon'];
      if (centerLat is num && centerLon is num) {
        return _distance.as(
          LengthUnit.Meter,
          origin,
          LatLng(centerLat.toDouble(), centerLon.toDouble()),
        );
      }
    }

    return null;
  }

  double? _distanceToWay(Map<String, dynamic> element, LatLng origin) {
    final geometry = element['geometry'];
    if (geometry is List) {
      final points = <LatLng>[];
      for (final point in geometry) {
        if (point is Map<String, dynamic>) {
          final lat = point['lat'];
          final lon = point['lon'];
          if (lat is num && lon is num) {
            points.add(LatLng(lat.toDouble(), lon.toDouble()));
          }
        }
      }
      if (points.isNotEmpty) {
        return _closestDistanceToPolyline(points, origin);
      }
    }

    return _distanceToNode(element, origin);
  }

  double? _closestDistanceToPolyline(List<LatLng> points, LatLng origin) {
    if (points.length == 1) {
      return _distance.as(LengthUnit.Meter, origin, points.first);
    }

    double? bestDistance;
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final distance = _distanceToSegmentMeters(origin, start, end);
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
      }
    }

    return bestDistance;
  }

  double _distanceToSegmentMeters(LatLng origin, LatLng start, LatLng end) {
    final startPoint = _projectToMeters(origin, start);
    final endPoint = _projectToMeters(origin, end);

    final abx = endPoint.x - startPoint.x;
    final aby = endPoint.y - startPoint.y;
    final apx = -startPoint.x;
    final apy = -startPoint.y;
    final denom = abx * abx + aby * aby;

    double t = 0;
    if (denom > 0) {
      t = (apx * abx + apy * aby) / denom;
      t = t.clamp(0, 1).toDouble();
    }

    final closestX = startPoint.x + abx * t;
    final closestY = startPoint.y + aby * t;
    return math.sqrt(closestX * closestX + closestY * closestY);
  }

  math.Point<double> _projectToMeters(LatLng origin, LatLng point) {
    const double radiansPerDegree = math.pi / 180;
    const double earthRadiusMeters = 6371000;

    final double originLatRad = origin.latitude * radiansPerDegree;
    final double deltaLat = (point.latitude - origin.latitude) * radiansPerDegree;
    final double deltaLon = (point.longitude - origin.longitude) * radiansPerDegree;

    final double x = deltaLon * earthRadiusMeters * math.cos(originLatRad);
    final double y = deltaLat * earthRadiusMeters;
    return math.Point<double>(x, y);
  }

  static const Map<String, _SpeedAlias> _maxspeedAliases = {
    'de:urban': _SpeedAlias(50),
    'de:rural': _SpeedAlias(100),
    'de:motorway': _SpeedAlias(130),
    'de:zone20': _SpeedAlias(20),
    'de:zone30': _SpeedAlias(30),
    'at:urban': _SpeedAlias(50),
    'at:rural': _SpeedAlias(100),
    'at:motorway': _SpeedAlias(130),
    'at:zone30': _SpeedAlias(30),
    'ch:urban': _SpeedAlias(50),
    'ch:rural': _SpeedAlias(80),
    'ch:motorway': _SpeedAlias(120),
    'fr:urban': _SpeedAlias(50),
    'fr:rural': _SpeedAlias(80),
    'fr:motorway': _SpeedAlias(130),
    'fr:zone30': _SpeedAlias(30),
    'it:urban': _SpeedAlias(50),
    'it:rural': _SpeedAlias(90),
    'it:motorway': _SpeedAlias(130),
    'it:zone30': _SpeedAlias(30),
    'es:urban': _SpeedAlias(50),
    'es:rural': _SpeedAlias(90),
    'es:motorway': _SpeedAlias(120),
    'es:zone30': _SpeedAlias(30),
    'uk:nsl_single': _SpeedAlias(60, isMph: true),
    'uk:nsl_single_carriageway': _SpeedAlias(60, isMph: true),
    'uk:nsl_dual': _SpeedAlias(70, isMph: true),
    'uk:nsl_dual_carriageway': _SpeedAlias(70, isMph: true),
    'uk:nsl_mw': _SpeedAlias(70, isMph: true),
    'uk:motorway': _SpeedAlias(70, isMph: true),
    'uk:urban': _SpeedAlias(30, isMph: true),
    'ru:urban': _SpeedAlias(60),
    'ru:rural': _SpeedAlias(90),
    'ru:motorway': _SpeedAlias(110),
    'pl:urban': _SpeedAlias(50),
    'pl:rural': _SpeedAlias(90),
    'pl:expressway': _SpeedAlias(120),
    'pl:motorway': _SpeedAlias(140),
    'nl:urban': _SpeedAlias(50),
    'nl:rural': _SpeedAlias(80),
    'nl:motorway': _SpeedAlias(100),
    'se:urban': _SpeedAlias(50),
    'se:rural': _SpeedAlias(80),
    'se:motorway': _SpeedAlias(110),
    'no:urban': _SpeedAlias(50),
    'no:rural': _SpeedAlias(80),
    'no:motorway': _SpeedAlias(110),
    'fi:urban': _SpeedAlias(50),
    'fi:rural': _SpeedAlias(80),
    'fi:motorway': _SpeedAlias(120),
    'dk:urban': _SpeedAlias(50),
    'dk:rural': _SpeedAlias(80),
    'dk:motorway': _SpeedAlias(130),
    'us:urban': _SpeedAlias(25, isMph: true),
    'us:rural': _SpeedAlias(55, isMph: true),
    'us:motorway': _SpeedAlias(65, isMph: true),
    'us:school': _SpeedAlias(20, isMph: true),
    'ca:urban': _SpeedAlias(50),
    'ca:rural': _SpeedAlias(80),
    'ca:motorway': _SpeedAlias(110),
    'au:urban': _SpeedAlias(50),
    'au:rural': _SpeedAlias(100),
    'au:motorway': _SpeedAlias(110),
    'nz:urban': _SpeedAlias(50),
    'nz:rural': _SpeedAlias(100),
    'nz:motorway': _SpeedAlias(110),
    'zone:20': _SpeedAlias(20),
    'zone:30': _SpeedAlias(30),
    'zone20': _SpeedAlias(20),
    'zone30': _SpeedAlias(30),
    'walk': _SpeedAlias(6),
    'living_street': _SpeedAlias(7),
  };
}

class _SpeedAlias {
  const _SpeedAlias(this.value, {this.isMph = false, this.priority = 3});

  final double value;
  final bool isMph;
  final int priority;
}

class _ParsedSpeed {
  const _ParsedSpeed(this.value, {required this.priority});

  final String value;
  final int priority;
}

class _SpeedCandidate {
  const _SpeedCandidate({
    required this.value,
    required this.priority,
    required this.distanceMeters,
  });

  final String value;
  final int priority;
  final double? distanceMeters;
}

const double _maxWayDistanceMeters = 60;
const double _maxNodeDistanceMeters = 30;
const double _distanceEpsilonMeters = 0.5;
