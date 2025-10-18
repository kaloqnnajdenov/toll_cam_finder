import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service responsible for querying OpenStreetMap (Overpass API) for speed
/// limits near a geographic coordinate.
class OsmSpeedLimitService {
  OsmSpeedLimitService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';
  static const double _milesToKilometers = 1.60934;

  final http.Client _httpClient;

  /// Fetches the nearest `maxspeed` tag (in km/h) around [latitude] and
  /// [longitude]. Returns `null` if no maxspeed tag could be resolved or if the
  /// network request fails.
  Future<double?> fetchSpeedLimit({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_overpassUrl);
    final String query = _buildQuery(latitude: latitude, longitude: longitude);

    try {
      final response = await _httpClient.post(
        uri,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'data=$query',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'OSM speed limit request failed with status: '
          '${response.statusCode}',
        );
        return null;
      }

      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? elements = decoded['elements'] as List<dynamic>?;

      if (elements == null || elements.isEmpty) {
        return null;
      }

      for (final dynamic element in elements) {
        if (element is! Map<String, dynamic>) continue;
        final Map<String, dynamic>? tags =
            element['tags'] as Map<String, dynamic>?;
        if (tags == null || tags.isEmpty) continue;

        final double? limit = _resolveSpeedLimit(tags);
        if (limit != null) {
          return limit;
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to fetch OSM speed limit: $error');
      debugPrint('$stackTrace');
    }

    return null;
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _httpClient.close();
  }

  static String _buildQuery({
    required double latitude,
    required double longitude,
  }) {
    return '[out:json][timeout:10];'
        '(way(around:70,$latitude,$longitude)["maxspeed"]);'
        'out tags;';
  }

  static final RegExp _speedPattern = RegExp(r'([0-9]+(?:\.[0-9]+)?)');

  static double? _resolveSpeedLimit(Map<String, dynamic> tags) {
    final Iterable<String?> candidates = <String?>[
      _stringTag(tags, 'maxspeed'),
      _stringTag(tags, 'maxspeed:forward'),
      _stringTag(tags, 'maxspeed:backward'),
      _stringTag(tags, 'maxspeed:advisory'),
    ];

    for (final String? value in candidates) {
      if (value == null || value.isEmpty) continue;
      final double? parsed = _parseSpeed(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static String? _stringTag(Map<String, dynamic> tags, String key) {
    final dynamic value = tags[key];
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static double? _parseSpeed(String raw) {
    final Match? match = _speedPattern.firstMatch(raw);
    if (match == null) {
      return null;
    }

    final double? value = double.tryParse(match.group(1)!);
    if (value == null) {
      return null;
    }

    final bool isMph = raw.toLowerCase().contains('mph');
    return isMph ? value * _milesToKilometers : value;
  }

  @visibleForTesting
  static double? resolveFromTags(Map<String, dynamic> tags) {
    return _resolveSpeedLimit(tags);
  }
}
