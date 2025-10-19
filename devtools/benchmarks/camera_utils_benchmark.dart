import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/map/domain/utils/camera_utils.dart';

void main(List<String> args) {
  const cameraCount = 75000;
  const queryCount = 5000;
  final seed = args.isNotEmpty ? int.tryParse(args.first) ?? 42 : 42;
  final random = Random(seed);

  final cameras = List<LatLng>.generate(cameraCount, (_) {
    final lat = random.nextDouble() * 180 - 90;
    final lon = random.nextDouble() * 360 - 180;
    return LatLng(lat, lon);
  });

  final queries = List<LatLng>.generate(queryCount, (_) {
    final lat = random.nextDouble() * 180 - 90;
    final lon = random.nextDouble() * 360 - 180;
    return LatLng(lat, lon);
  });

  final utils = CameraUtils();
  utils.loadFromPoints(cameras);

  final naive = _NaiveNearest(cameras);

  final kdTreeTimer = Stopwatch()..start();
  for (final query in queries) {
    utils.nearestCameraDistanceMeters(query);
  }
  kdTreeTimer.stop();

  final naiveTimer = Stopwatch()..start();
  for (final query in queries) {
    naive.nearestCameraDistanceMeters(query);
  }
  naiveTimer.stop();

  final kdTreePerQuery = kdTreeTimer.elapsedMicroseconds / queryCount;
  final naivePerQuery = naiveTimer.elapsedMicroseconds / queryCount;

  print('Synthetic benchmark (seed=$seed)');
  print('Cameras: $cameraCount, queries: $queryCount');
  print('KD-tree total: ${kdTreeTimer.elapsed} (~${kdTreePerQuery.toStringAsFixed(2)} µs/query)');
  print('Naive total: ${naiveTimer.elapsed} (~${naivePerQuery.toStringAsFixed(2)} µs/query)');
  final speedup = naivePerQuery == 0
      ? 'n/a'
      : (naivePerQuery / kdTreePerQuery).toStringAsFixed(2);
  print('Approximate speedup: ${speedup}x');
}

class _NaiveNearest {
  _NaiveNearest(this.points);

  final List<LatLng> points;
  final Distance _distance = const Distance();

  double? nearestCameraDistanceMeters(LatLng point) {
    if (points.isEmpty) return null;

    var best = double.infinity;
    for (final camera in points) {
      final meters = _distance(point, camera);
      if (meters < best) {
        best = meters;
      }
    }
    return best;
  }
}
