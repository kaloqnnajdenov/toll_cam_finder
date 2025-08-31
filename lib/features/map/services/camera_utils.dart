// services/camera_utils.dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CameraUtils {
  CameraUtils({this.boundsPaddingDeg = 0.05});

  final double boundsPaddingDeg;

  List<LatLng> _allCameras = [];
  List<LatLng> _visibleCameras = [];
  bool _loading = true;
  String? _error;

  // --- public getters (read-only to the outside) ---
  List<LatLng> get allCameras => _allCameras;
  List<LatLng> get visibleCameras => _visibleCameras;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Loads GeoJSON from asset and fills [_allCameras]. Also sets the
  /// initial [_visibleCameras] to all (until a bounds-based filter runs).
  Future<void> loadFromAsset(String assetPath) async {
    _loading = true;
    _error = null;

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
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

      _allCameras = pts;
      _visibleCameras = pts;
      _loading = false;
    } catch (e) {
      _loading = false;
      _error = 'Failed to load cameras: $e';
    }
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

  // --- helpers ---

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
}
