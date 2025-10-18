import 'dart:convert';

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
  way(around:120,${location.latitude},${location.longitude})["highway"];
  relation(around:120,${location.latitude},${location.longitude})["type"="route"]["route"~"road|highway|motorway"];
  node(around:80,${location.latitude},${location.longitude})["maxspeed"];
  node(around:80,${location.latitude},${location.longitude})["traffic_sign"~"maxspeed", i];
);
out tags center qt;
''';

    final uri = Uri.parse('$_endpoint?data=${Uri.encodeComponent(query)}');
    final response = await _client
        .get(uri, headers: {'User-Agent': 'toll_cam_finder/1.0'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      return null;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }

    final elements = decoded['elements'];
    if (elements is! List || elements.isEmpty) {
      return null;
    }

    _SpeedCandidate? bestCandidate;

    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final tagsRaw = element['tags'];
      if (tagsRaw is! Map) continue;
      final tags = tagsRaw.cast<String, dynamic>();

      final parsed = _extractMaxSpeed(tags);
      if (parsed == null) continue;

      final elementPriority = _elementPriority(element['type']);
      final distanceMeters = _distanceToElement(element, location);
      final combinedPriority = elementPriority * 100 + parsed.priority;

      final candidate = _SpeedCandidate(
        value: parsed.value,
        priority: combinedPriority,
        distanceMeters: distanceMeters,
      );

      if (bestCandidate == null ||
          candidate.priority < bestCandidate.priority ||
          (candidate.priority == bestCandidate.priority &&
              (candidate.distanceMeters ?? double.infinity) <
                  (bestCandidate.distanceMeters ?? double.infinity))) {
        bestCandidate = candidate;
      }
    }

    return bestCandidate?.value;
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

  int _elementPriority(dynamic type) {
    if (type == 'way') {
      return 0;
    }
    if (type == 'relation') {
      return 1;
    }
    return 2;
  }

  double? _distanceToElement(Map<String, dynamic> element, LatLng origin) {
    final center = element['center'];
    if (center is Map<String, dynamic>) {
      final lat = center['lat'];
      final lon = center['lon'];
      if (lat is num && lon is num) {
        return _distance.as(
          LengthUnit.Meter,
          origin,
          LatLng(lat.toDouble(), lon.toDouble()),
        );
      }
    }

    final lat = element['lat'];
    final lon = element['lon'];
    if (lat is num && lon is num) {
      return _distance.as(
        LengthUnit.Meter,
        origin,
        LatLng(lat.toDouble(), lon.toDouble()),
      );
    }

    return null;
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
