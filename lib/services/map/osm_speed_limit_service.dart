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

  final http.Client _client;
  final bool _ownsClient;

  /// Returns the speed limit in km/h for the given [location].
  ///
  /// Returns `null` when no speed limit could be determined.
  Future<String?> fetchSpeedLimit(LatLng location) async {
    final query = '''
[out:json];
way(around:40,${location.latitude},${location.longitude})["highway"]["maxspeed"];
out tags 1;
''';

    final uri = Uri.parse('$_endpoint?data=${Uri.encodeComponent(query)}');
    final response = await _client
        .get(uri, headers: {'User-Agent': 'toll_cam_finder/1.0'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'];
    if (elements is! List || elements.isEmpty) {
      return null;
    }

    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) continue;
      final raw = tags['maxspeed'];
      if (raw is String) {
        final parsed = _parseMaxSpeed(raw);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  String? _parseMaxSpeed(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'none' || normalized == 'signals') {
      return null;
    }

    final primary = normalized.split(';').first.trim();
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(primary);
    if (match == null) {
      return null;
    }

    final value = double.tryParse(match.group(1)!);
    if (value == null) {
      return null;
    }

    double inKmh = value;
    if (primary.contains('mph')) {
      inKmh = value * 1.60934;
    }

    return inKmh.round().toString();
  }
}
