import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:toll_cam_finder/models/segment.dart';

class SegmentRepository {
  static Future<List<TollSegment>> loadFromAsset(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final features = (data['features'] as List?) ?? const [];

    final segments = <TollSegment>[];

    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final geom = feature['geometry'] as Map<String, dynamic>?;
      if (geom == null) continue;

      final type = geom['type'];
      if (type != 'LineString') continue;

      final coords = (geom['coordinates'] as List)
          .map<List<double>>((c) => (c as List).cast<num>().map((e) => e.toDouble()).toList())
          .map((xy) => LatLng(xy[1], xy[0])) // [lon, lat] -> LatLng(lat, lon)
          .toList();

      if (coords.length < 2) continue;

      final props = (feature['properties'] as Map?) ?? {};
      segments.add(
        TollSegment(
          id: (props['segment_id'] is int) ? props['segment_id'] as int : int.tryParse('${props['segment_id']}'),
          roadNo: props['road_no']?.toString(),
          name: props['segment_name']?.toString(),
          coords: coords,
        ),
      );
    }

    return segments;
  }
}
