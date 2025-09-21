import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';

void main() {
  final service = SegmentIndexService.instance;

  setUp(() {
    service.resetForTest();
  });

  group('SegmentIndexService parsing helpers', () {
    test('parsePlainArrayForTest parses point arrays and start/end fallbacks', () {
      final segments = service.parsePlainArrayForTest([
        {
          'id': 'with-points',
          'points': [
            {'lat': 10, 'lon': 20},
            {'lat': 11, 'lng': 21},
          ],
          'length_m': 42.5,
        },
        {
          'id': 'with-start-end',
          'start': {'lat': 0, 'lon': 0},
          'end': {'lat': 0.5, 'lng': 1},
        },
        {
          'id': 'no-geometry',
        },
      ]);

      expect(segments, hasLength(2), reason: 'Entries missing geometry should be skipped.');

      final withPoints =
          segments.firstWhere((seg) => seg.id == 'with-points', orElse: () => throw StateError('Segment not parsed.'));
      expect(withPoints.path, hasLength(2), reason: 'Both coordinates should be preserved.');
      expect(withPoints.path.first, predicate<GeoPoint>((p) => p.lat == 10 && p.lon == 20));
      expect(withPoints.path.last, predicate<GeoPoint>((p) => p.lat == 11 && p.lon == 21),
          reason: 'The parser must accept lng as an alias for lon.');
      expect(withPoints.lengthMeters, closeTo(42.5, 1e-9));

      final startEnd =
          segments.firstWhere((seg) => seg.id == 'with-start-end', orElse: () => throw StateError('Segment not parsed.'));
      expect(startEnd.path.first, predicate<GeoPoint>((p) => p.lat == 0 && p.lon == 0));
      expect(startEnd.path.last, predicate<GeoPoint>((p) => p.lat == 0.5 && p.lon == 1));
      expect(startEnd.lengthMeters, isNull, reason: 'Length is optional and defaults to null.');
    });

    test('parseGeoJsonForTest flattens MultiLineString and skips unsupported geometry', () {
      final featureCollection = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'segment_id': 'line-string', 'length_m': 123},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [100.0, 0.0],
                [100.001, 0.001],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'segment_id': 'multi'},
            'geometry': {
              'type': 'MultiLineString',
              'coordinates': [
                [
                  [110.0, 1.0],
                  [110.0005, 1.0005],
                ],
                [
                  [110.001, 1.001],
                  [110.0015, 1.0015],
                ],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'segment_id': 'skip-me'},
            'geometry': {
              'type': 'Polygon',
            },
          },
          {
            'type': 'Feature',
            'properties': {'segment_id': 'degenerate'},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [0.0, 0.0],
              ],
            },
          },
        ],
      };

      final segments = service.parseGeoJsonForTest(featureCollection.cast<String, dynamic>());
      expect(segments, hasLength(2), reason: 'Unsupported geometries and degenerate paths should be filtered out.');

      final lineString =
          segments.firstWhere((seg) => seg.id == 'line-string', orElse: () => throw StateError('LineString missing.'));
      expect(lineString.path, hasLength(2));
      expect(lineString.lengthMeters, 123);

      final multi = segments.firstWhere((seg) => seg.id == 'multi', orElse: () => throw StateError('MultiLine missing.'));
      expect(multi.path, hasLength(4), reason: 'All coordinates from each part must be flattened into one path.');
    });

    test('toGeoPointsFromLonLatListForTest ignores malformed coordinates', () {
      final points = service.toGeoPointsFromLonLatListForTest([
        [1, 2],
        [3, 4, 5],
        [6],
        'bad',
      ]);

      expect(points, hasLength(3));
      expect(points[0], predicate<GeoPoint>((p) => p.lat == 2 && p.lon == 1));
      expect(points[1], predicate<GeoPoint>((p) => p.lat == 4 && p.lon == 3));
      expect(points[2], predicate<GeoPoint>((p) => p.lat == 5 && p.lon == 6));
    });
  });

  group('SegmentIndexService candidate queries', () {
    test('candidateIdsNearLatLng returns empty list when index is not built', () {
      final hits = service.candidateIdsNearLatLng(const LatLng(0, 0));
      expect(hits, isEmpty, reason: 'Querying before building the index should not throw.');
    });

    test('candidateIdsNearLatLng finds segments whose bounding boxes touch the search radius', () async {
      const radius = 150.0;
      const metersPerDegree = 111320.0;
      final boundaryLonDelta = radius / metersPerDegree;

      await service.buildFromGeometries([
        SegmentGeometry(
          id: 'touching',
          path: [
            GeoPoint(0, boundaryLonDelta),
            GeoPoint(0, boundaryLonDelta + 0.0001),
          ],
        ),
        SegmentGeometry(
          id: 'inside',
          path: [
            const GeoPoint(0.0005, 0.0005),
            const GeoPoint(0.0006, 0.0006),
          ],
        ),
        SegmentGeometry(
          id: 'outside',
          path: [
            const GeoPoint(0.1, 0.1),
            const GeoPoint(0.2, 0.2),
          ],
        ),
      ]);

      final hits = service.candidateIdsNearLatLng(const LatLng(0, 0), radiusMeters: radius);

      expect(hits, containsAll(<String>{'touching', 'inside'}));
      expect(hits, isNot(contains('outside')));
    });
  });
}
