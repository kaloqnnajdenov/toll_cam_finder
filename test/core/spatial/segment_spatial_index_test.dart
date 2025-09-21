import 'package:test/test.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/core/spatial/segment_spatial_index.dart';

void main() {
  group('Geo utilities', () {
    test('GeoBounds.around produces finite extents near the poles', () {
      final bounds = GeoBounds.around(const GeoPoint(89.9999, 45), 1000);
      expect(bounds.minLon.isFinite, isTrue, reason: 'Longitude range should be clamped to finite values.');
      expect(bounds.maxLon.isFinite, isTrue);
      expect(bounds.maxLat, greaterThan(bounds.minLat));
      expect(bounds.maxLon, greaterThan(bounds.minLon));
    });

    test('SegmentGeometry.bounds returns tight bounding box for a path', () {
      final geometry = SegmentGeometry(
        id: 'segment',
        path: const [
          GeoPoint(10, 20),
          GeoPoint(12, 25),
          GeoPoint(9, 27),
        ],
      );

      final bounds = geometry.bounds;
      expect(bounds.minLat, 9);
      expect(bounds.maxLat, 12);
      expect(bounds.minLon, 20);
      expect(bounds.maxLon, 27);
    });
  });

  group('SegmentSpatialIndex', () {
    test('candidatesNear returns segments with bounding boxes intersecting the search window', () {
      final index = SegmentSpatialIndex.build([
        SegmentGeometry(
          id: 'north',
          path: const [
            GeoPoint(0.01, 0),
            GeoPoint(0.02, 0),
          ],
        ),
        SegmentGeometry(
          id: 'east',
          path: const [
            GeoPoint(0, 0.015),
            GeoPoint(0, 0.02),
          ],
        ),
        SegmentGeometry(
          id: 'far',
          path: const [
            GeoPoint(1, 1),
            GeoPoint(1.1, 1.1),
          ],
        ),
      ]);

      final hits = index.candidatesNear(const GeoPoint(0, 0), radiusMeters: 2000);
      final hitIds = hits.map((g) => g.id).toSet();

      expect(hitIds, containsAll(<String>{'north', 'east'}));
      expect(hitIds, isNot(contains('far')));
    });

    test('candidatesNear honours zero radius by matching only overlapping bounding boxes', () {
      final boundaryPoint = const GeoPoint(0, 0.001);
      final index = SegmentSpatialIndex.build([
        SegmentGeometry(
          id: 'touching',
          path: const [
            GeoPoint(0, 0.001),
            GeoPoint(0, 0.0015),
          ],
        ),
        SegmentGeometry(
          id: 'disjoint',
          path: const [
            GeoPoint(0, 0.01),
            GeoPoint(0, 0.02),
          ],
        ),
      ]);

      final hits = index.candidatesNear(boundaryPoint, radiusMeters: 0);
      expect(hits.map((g) => g.id), contains('touching'));
      expect(hits.map((g) => g.id), isNot(contains('disjoint')));
    });
  });
}
