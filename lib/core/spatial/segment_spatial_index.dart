// lib/services/segments/segment_spatial_index.dart
import 'package:rbush/rbush.dart';
import 'geo.dart';
import 'segment_geometry.dart';

class _SegmentItem {
  final SegmentGeometry geom;
  const _SegmentItem(this.geom);
}

class SegmentSpatialIndex {
  final RBushDirect<_SegmentItem> _tree;

  SegmentSpatialIndex._(this._tree);

  factory SegmentSpatialIndex.build(
    List<SegmentGeometry> segments, {
    int maxEntries = 9,
  }) {
    final tree = RBushDirect<_SegmentItem>(maxEntries);
    final elements = <RBushElement<_SegmentItem>>[];

    for (final s in segments) {
      final b = s.bounds;
      elements.add(RBushElement(
        minX: b.minLon,
        minY: b.minLat,
        maxX: b.maxLon,
        maxY: b.maxLat,
        data: _SegmentItem(s),
      ));
    }

    tree.load(elements); // bulk build
    return SegmentSpatialIndex._(tree);
  }

  List<SegmentGeometry> candidatesNear(GeoPoint c, {double radiusMeters = 150}) {
    final q = GeoBounds.around(c, radiusMeters);
    final hits = _tree.search(RBushBox(
      minX: q.minLon, minY: q.minLat, maxX: q.maxLon, maxY: q.maxLat,
    ));
    return hits.map((e) => e.geom).toList(growable: false);
  }

  List<SegmentGeometry> segmentsWithinBounds(GeoBounds bounds) {
    final hits = _tree.search(RBushBox(
      minX: bounds.minLon,
      minY: bounds.minLat,
      maxX: bounds.maxLon,
      maxY: bounds.maxLat,
    ));
    return hits.map((e) => e.geom).toList(growable: false);
  }
}
