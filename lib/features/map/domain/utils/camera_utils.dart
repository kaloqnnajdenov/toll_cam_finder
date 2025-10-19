// services/camera_utils.dart
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_data_store.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_file_system_stub.dart'
    if (dart.library.io)
      'package:toll_cam_finder/features/segments/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/features/segments/services/toll_segments_paths.dart';

class CameraUtils {
  CameraUtils({
    this.boundsPaddingDeg = AppConstants.cameraUtilsBoundsPaddingDeg,
    TollSegmentsFileSystem? fileSystem,
  }) : _fileSystem = fileSystem ?? fs_impl.createFileSystem();

  final double boundsPaddingDeg;
  final TollSegmentsFileSystem _fileSystem;

  List<LatLng> _allCameras = [];
  List<LatLng> _visibleCameras = [];
  bool _loading = true;
  String? _error;
  final Distance _distance = const Distance();
  _KdNode? _kdTree;

  // --- public getters (read-only to the outside) ---
  List<LatLng> get allCameras => _allCameras;
  List<LatLng> get visibleCameras => _visibleCameras;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Loads GeoJSON from asset and fills [_allCameras]. Also sets the
  /// initial [_visibleCameras] to all (until a bounds-based filter runs).
  Future<void> loadFromAsset(
    String assetPath, {
    Set<String> excludedSegmentIds = const <String>{},
  }) async {
    _loading = true;
    _error = null;

    try {
      final data = await _loadCameraData(assetPath);

      final pts = assetPath.toLowerCase().endsWith('.csv')
          ? _parseCamerasFromCsv(data, excludedSegmentIds)
          : _parseCamerasFromGeoJson(data);
      _setCameraPoints(pts);
      _loading = false;
    } catch (e) {
      _loading = false;
      _error = AppMessages.failedToLoadCameras('$e');
      _setCameraPoints(const []);
    }
  }

  @visibleForTesting
  void loadFromPoints(List<LatLng> points) {
    _setCameraPoints(points);
  }

  /// Updates [_visibleCameras] using the (optionally) provided map bounds.
  /// If [bounds] is null or there are no cameras, all cameras are made visible.
  void updateVisible({LatLngBounds? bounds}) {
    if (bounds == null || _allCameras.isEmpty) {
      _visibleCameras = _allCameras;
      return;
    }

    final padded = _padBounds(bounds, boundsPaddingDeg);
    final res = <LatLng>[];
    for (final p in _allCameras) {
      if (_boundsContains(padded, p)) res.add(p);
    }
    _visibleCameras = res;
  }

  /// Calculates the distance to the nearest camera from [point], returning the
  /// value in meters. When no cameras are loaded the method yields `null`.
  double? nearestCameraDistanceMeters(LatLng point) {
    if (_kdTree == null) {
      return null;
    }
    return _nearestNeighbor(_kdTree!, point, double.infinity);
  }

  // --- helpers ---
  void _setCameraPoints(List<LatLng> points) {
    final pts = List<LatLng>.unmodifiable(points);
    _allCameras = pts;
    _visibleCameras = pts;
    _kdTree = pts.isEmpty ? null : _buildKdTree(pts, 0);
  }

  List<LatLng> _parseCamerasFromGeoJson(String jsonStr) {
    final obj = json.decode(jsonStr) as Map<String, dynamic>;
    final features = (obj['features'] as List?) ?? const [];

    final pts = <LatLng>[];
    for (final f in features) {
      final feat = (f as Map).cast<String, dynamic>();
      final geom = (feat['geometry'] as Map?)?.cast<String, dynamic>();
      if (geom == null) continue;
      if (geom['type'] != 'Point') continue;

      final coords = (geom['coordinates'] as List?) ?? const [];
      if (coords.length < 2) continue;

      final lon = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      pts.add(LatLng(lat, lon));
    }

    return pts;
  }

  List<LatLng> _parseCamerasFromCsv(
    String raw,
    Set<String> excludedSegmentIds,
  ) {
    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(raw);

    if (rows.isEmpty) {
      return const [];
    }
    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList(growable: false);
    final idIdx = header.indexOf('id');
    final startIdx = header.indexOf('start');
    final endIdx = header.indexOf('end');

    if (startIdx == -1 || endIdx == -1) {
      throw FormatException(AppMessages.csvMissingStartEndColumns);
    }

    final pts = <LatLng>[];
    final seen = <String>{};

    for (final row in rows.skip(1)) {
      if (row.length <= startIdx || row.length <= endIdx) continue;

      final start = _latLngFromCsvValue(row[startIdx]);
      final end = _latLngFromCsvValue(row[endIdx]);

      if (idIdx != -1 && row.length > idIdx) {
        final segmentId = row[idIdx]?.toString().trim();
        if (segmentId != null &&
            segmentId.isNotEmpty &&
            excludedSegmentIds.contains(segmentId)) {
          continue;
        }
      }

      if (start != null && seen.add('${start.latitude},${start.longitude}')) {
        pts.add(start);
      }
      if (end != null && seen.add('${end.latitude},${end.longitude}')) {
        pts.add(end);
      }
    }

    return pts;
  }

  LatLng? _latLngFromCsvValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parts = text.split(',').map((p) => p.trim()).toList();
    if (parts.length < 2) return null;

    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }

  LatLngBounds _padBounds(LatLngBounds b, double delta) {
    return LatLngBounds(
      LatLng(b.south - delta, b.west - delta),
      LatLng(b.north + delta, b.east + delta),
    );
  }

  bool _boundsContains(LatLngBounds b, LatLng p) {
    return p.latitude >= b.south &&
        p.latitude <= b.north &&
        p.longitude >= b.west &&
        p.longitude <= b.east;
  }

  Future<String> _loadCameraData(String assetPath) async {
    if (assetPath == kTollSegmentsAssetPath) {
      try {
        return await TollSegmentsDataStore.instance.loadCombinedCsv(
          fileSystem: _fileSystem,
          assetPath: assetPath,
        );
      } catch (error) {
        debugPrint('CameraUtils: falling back to asset ($error).');
      }
    }

    return rootBundle.loadString(assetPath);
  }

  _KdNode? _buildKdTree(List<LatLng> points, int depth) {
    if (points.isEmpty) return null;

    final axis = depth % 2;
    final sorted = List<LatLng>.of(points)
      ..sort((a, b) =>
          _axisValue(a, axis).compareTo(_axisValue(b, axis)));
    final mid = sorted.length >> 1;
    final left = sorted.sublist(0, mid);
    final right = mid + 1 < sorted.length
        ? sorted.sublist(mid + 1)
        : const <LatLng>[];

    return _KdNode(
      sorted[mid],
      axis,
      left: _buildKdTree(left, depth + 1),
      right: _buildKdTree(right, depth + 1),
    );
  }

  double _axisValue(LatLng point, int axis) =>
      axis == 0 ? point.latitude : point.longitude;

  double _nearestNeighbor(_KdNode node, LatLng target, double best) {
    var bestDistance = best;
    final currentDistance = _distance(target, node.point);
    if (currentDistance < bestDistance) {
      bestDistance = currentDistance;
    }

    final diff =
        _axisValue(target, node.axis) - _axisValue(node.point, node.axis);
    final first = diff <= 0 ? node.left : node.right;
    final second = diff <= 0 ? node.right : node.left;

    if (first != null) {
      bestDistance = _nearestNeighbor(first, target, bestDistance);
    }

    final planeDistance = _distanceToAxisPlane(target, node);
    if (second != null && planeDistance < bestDistance) {
      bestDistance = _nearestNeighbor(second, target, bestDistance);
    }

    return bestDistance;
  }

  double _distanceToAxisPlane(LatLng target, _KdNode node) {
    final planeValue = _axisValue(node.point, node.axis);
    if (node.axis == 0) {
      return _distance(target, LatLng(planeValue, target.longitude));
    }
    return _distance(target, LatLng(target.latitude, planeValue));
  }
}

class _KdNode {
  _KdNode(this.point, this.axis, {this.left, this.right});

  final LatLng point;
  final int axis;
  final _KdNode? left;
  final _KdNode? right;
}
