import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/core/spatial/segment_geometry.dart';
import 'package:toll_cam_finder/features/segemnt_index_service.dart';

/// Wraps the segment index to keep debugging logic out of the page widget.
class SegmentDebugger {
  SegmentDebugger(this._index);

  final SegmentIndexService _index;

  bool _segmentsReady = false;
  List<SegmentGeometry> _debugCandidates = const [];
  List<LatLng> _debugQuerySquare = const [];
  DateTime? _lastLog;

  bool get isReady => _segmentsReady;
  List<SegmentGeometry> get candidates => _debugCandidates;
  List<LatLng> get querySquare => _debugQuerySquare;

  Future<bool> initialise({required String assetPath}) async {
    await _index.tryLoadFromDefaultAsset(assetPath: assetPath);
    _segmentsReady = _index.isReady;
    if (_segmentsReady) {
      if (kDebugMode) debugPrint('[SEGIDX] index ready');
      return true;
    }
    if (kDebugMode) {
      debugPrint('[SEGIDX] not ready — missing asset or parse failure.');
    }
    return false;
  }

  void refresh(LatLng gps, {String reason = 'gps'}) {
    if (!_segmentsReady) return;

    final sw = Stopwatch()..start();
    final cands = _index.candidatesNearLatLng(
      gps,
      radiusMeters: AppConstants.candidateRadiusMeters,
    );
    sw.stop();

    _debugCandidates = cands;
    _debugQuerySquare = _computeQuerySquare(gps, AppConstants.candidateRadiusMeters);

    if (!kDebugMode) return;

    final now = DateTime.now();
    if (_lastLog == null || now.difference(_lastLog!) > const Duration(seconds: 1)) {
      debugPrint(
        '[SEGIDX/$reason] ${cands.length} candidates in ${sw.elapsedMicroseconds}µs '
        '@ ${gps.latitude.toStringAsFixed(5)},${gps.longitude.toStringAsFixed(5)} '
        '(r=${AppConstants.candidateRadiusMeters.toInt()}m)',
      );
      _lastLog = now;
    }
  }

  List<LatLng> _computeQuerySquare(LatLng c, double radiusMeters) {
    const mPerDegLat = 111320.0;
    final mPerDegLon = (mPerDegLat * math.cos(c.latitude * math.pi / 180.0))
        .clamp(1e-9, double.infinity);
    final dLat = radiusMeters / mPerDegLat;
    final dLon = radiusMeters / mPerDegLon;

    final minLat = c.latitude - dLat;
    final maxLat = c.latitude + dLat;
    final minLon = c.longitude - dLon;
    final maxLon = c.longitude + dLon;

    return <LatLng>[
      LatLng(minLat, minLon),
      LatLng(minLat, maxLon),
      LatLng(maxLat, maxLon),
      LatLng(maxLat, minLon),
      LatLng(minLat, minLon),
    ];
  }
}