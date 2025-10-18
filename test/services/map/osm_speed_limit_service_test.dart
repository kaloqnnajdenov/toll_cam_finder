import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

import 'package:toll_cam_finder/services/map/osm_speed_limit_service.dart';

void main() {
  const location = LatLng(52.52, 13.405);

  group('OsmSpeedLimitService.fetchSpeedLimit', () {
    test('returns numeric maxspeed when present on a nearby way', () async {
      final service = OsmSpeedLimitService(
        client: _fakeClient([
          _element(
            type: 'way',
            tags: {'maxspeed': '50'},
            center: const LatLng(52.5205, 13.4052),
          ),
        ]),
      );

      final result = await service.fetchSpeedLimit(location);

      expect(result, '50');
    });

    test('parses mph values', () async {
      final service = OsmSpeedLimitService(
        client: _fakeClient([
          _element(
            type: 'way',
            tags: {'maxspeed': '30 mph'},
            center: const LatLng(52.5205, 13.4052),
          ),
        ]),
      );

      final result = await service.fetchSpeedLimit(location);

      expect(result, '48');
    });

    test('supports country specific tokens', () async {
      final service = OsmSpeedLimitService(
        client: _fakeClient([
          _element(
            type: 'way',
            tags: {'maxspeed': 'DE:urban'},
            center: const LatLng(52.5205, 13.4052),
          ),
        ]),
      );

      final result = await service.fetchSpeedLimit(location);

      expect(result, '50');
    });

    test('falls back to conditional values when numeric maxspeed missing',
        () async {
      final service = OsmSpeedLimitService(
        client: _fakeClient([
          _element(
            type: 'way',
            tags: {'maxspeed:conditional': '60 @ (07:00-19:00)'},
            center: const LatLng(52.5205, 13.4052),
          ),
        ]),
      );

      final result = await service.fetchSpeedLimit(location);

      expect(result, '60');
    });

    test('reads speed from traffic sign tags when present', () async {
      final service = OsmSpeedLimitService(
        client: _fakeClient([
          _element(
            type: 'node',
            tags: {'traffic_sign': 'DE:274-70'},
            location: const LatLng(52.5202, 13.4049),
          ),
        ]),
      );

      final result = await service.fetchSpeedLimit(location);

      expect(result, '70');
    });

    test('reads fallback sign tags when traffic_sign is missing', () async {
      final service = OsmSpeedLimitService(
        client: _fakeClient([
          _element(
            type: 'way',
            tags: {'maxspeed:sign': 'DE:274-60'},
            center: const LatLng(52.5205, 13.4052),
          ),
        ]),
      );

      final result = await service.fetchSpeedLimit(location);

      expect(result, '60');
    });
  });
}

http.Client _fakeClient(List<Map<String, dynamic>> elements) {
  return MockClient((request) async {
    final body = jsonEncode({
      'version': 0.6,
      'elements': elements,
    });
    return http.Response(body, 200, headers: {'content-type': 'application/json'});
  });
}

Map<String, dynamic> _element({
  required String type,
  required Map<String, String> tags,
  LatLng? center,
  LatLng? location,
}) {
  final map = <String, dynamic>{
    'type': type,
    'tags': tags,
  };

  if (center != null) {
    map['center'] = {'lat': center.latitude, 'lon': center.longitude};
  }

  if (location != null) {
    map['lat'] = location.latitude;
    map['lon'] = location.longitude;
  }

  return map;
}
