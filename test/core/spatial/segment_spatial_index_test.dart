import 'package:test/test.dart';
import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/core/spatial/segment_spatial_index.dart';

void main() {
  group('Geo utilities', () {
    // Verifies that the helper keeps longitude values finite when we request
    // a bounding box very close to the poles. This guards against NaNs that
    // could otherwise leak into spatial index queries.
    test('GeoBounds.around produces finite extents near the poles', () {
      final bounds = GeoBounds.around(const GeoPoint(89.9999, 45), 1000);
      expect(
        bounds.minLon.isFinite,
        isTrue,
        reason: 'Longitude range should be clamped to finite values.',
      );
      expect(bounds.maxLon.isFinite, isTrue);
      expect(bounds.maxLat, greaterThan(bounds.minLat));
      expect(bounds.maxLon, greaterThan(bounds.minLon));
    });

    // Ensures the geometry bounding box is the tightest possible around the
    // provided polyline. This catches regressions where min/max comparisons
    // might be flipped or where end points are ignored.
    test('SegmentGeometry.bounds returns tight bounding box for a path', () {
      final geometry = SegmentGeometry(
        id: 'segment',
        path: const [GeoPoint(10, 20), GeoPoint(12, 25), GeoPoint(9, 27)],
      );

      final bounds = geometry.bounds;
      expect(bounds.minLat, 9);
      expect(bounds.maxLat, 12);
      expect(bounds.minLon, 20);
      expect(bounds.maxLon, 27);
    });
  });

  group('SegmentSpatialIndex', () {
    // Confirms that nearby segments are returned when their bounding boxes
    // intersect the search window, while far-away segments are filtered out.
    test(
      'candidatesNear returns segments with bounding boxes intersecting the search window',
      () {
        final index = SegmentSpatialIndex.build([
          SegmentGeometry(
            id: 'north',
            path: const [GeoPoint(0.01, 0), GeoPoint(0.02, 0)],
          ),
          SegmentGeometry(
            id: 'east',
            path: const [GeoPoint(0, 0.015), GeoPoint(0, 0.02)],
          ),
          SegmentGeometry(
            id: 'far',
            path: const [GeoPoint(1, 1), GeoPoint(1.1, 1.1)],
          ),
        ]);

        final hits = index.candidatesNear(
          const GeoPoint(0, 0),
          radiusMeters: 2000,
        );
        final hitIds = hits.map((g) => g.id).toSet();

        expect(hitIds, containsAll(<String>{'north', 'east'}));
        expect(hitIds, isNot(contains('far')));
      },
    );

    // Validates that a zero-radius search behaves as a pure bounding box
    // intersection test. Only geometries touching the query point are kept,
    // even if others are close but do not overlap.
    test(
      'candidatesNear honours zero radius by matching only overlapping bounding boxes',
      () {
        final boundaryPoint = const GeoPoint(0, 0.001);
        final index = SegmentSpatialIndex.build([
          SegmentGeometry(
            id: 'touching',
            path: const [GeoPoint(0, 0.001), GeoPoint(0, 0.0015)],
          ),
          SegmentGeometry(
            id: 'disjoint',
            path: const [GeoPoint(0, 0.01), GeoPoint(0, 0.02)],
          ),
        ]);

        final hits = index.candidatesNear(boundaryPoint, radiusMeters: 0);
        expect(hits.map((g) => g.id), contains('touching'));
        expect(hits.map((g) => g.id), isNot(contains('disjoint')));
      },
    );
  });
}
