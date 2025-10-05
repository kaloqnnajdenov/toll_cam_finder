import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:toll_cam_finder/core/spatial/geo.dart';
import 'package:toll_cam_finder/services/segment_path_cache_service.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/services/toll_segments_paths.dart';

class _FakeTollSegmentsFileSystem extends TollSegmentsFileSystem {
  final Map<String, String> files = <String, String>{};
  final Set<String> ensuredDirectories = <String>{};

  @override
  Future<void> ensureParentDirectory(String path) async {
    ensuredDirectories.add(p.dirname(path));
  }

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<String> readAsString(String path) async {
    final contents = files[path];
    if (contents == null) {
      throw const TollSegmentsFileSystemException('File not found');
    }
    return contents;
  }

  @override
  Future<void> writeAsString(String path, String data) async {
    files[path] = data;
  }
}

void main() {
  const csvPath = '/tmp/toll_segments.csv';
  final cachePath = '$csvPath$kSegmentPathsSuffix';

  SegmentPathCacheService _createService(_FakeTollSegmentsFileSystem fs) {
    return SegmentPathCacheService(
      fileSystem: fs,
      pathResolver: () async => csvPath,
    );
  }

  test('loadAllPaths returns empty map when cache is missing', () async {
    final fs = _FakeTollSegmentsFileSystem();
    final service = _createService(fs);

    final result = await service.loadAllPaths();

    expect(result, isEmpty);
    expect(fs.files.containsKey(cachePath), isFalse);
  });

  test('savePath persists GeoJSON and can be reloaded', () async {
    final fs = _FakeTollSegmentsFileSystem();
    final service = _createService(fs);

    await service.savePath('123', const <GeoPoint>[
      GeoPoint(10.0, 20.0),
      GeoPoint(11.0, 21.0),
      GeoPoint(12.0, 22.0),
    ]);

    expect(fs.files.containsKey(cachePath), isTrue);
    expect(fs.ensuredDirectories, contains(p.dirname(cachePath)));

    final decoded = jsonDecode(fs.files[cachePath]!);
    expect(decoded, isA<Map<String, dynamic>>());
    expect(decoded['type'], 'FeatureCollection');

    final loaded = await service.loadAllPaths();
    final restored = loaded['123'];
    expect(restored, isNotNull);
    expect(restored, hasLength(3));
    expect(restored!.first.lat, 10.0);
    expect(restored.first.lon, 20.0);
  });

  test('savePath replaces existing entry', () async {
    final fs = _FakeTollSegmentsFileSystem();
    final service = _createService(fs);

    await service.savePath('abc', const <GeoPoint>[
      GeoPoint(0.0, 1.0),
      GeoPoint(2.0, 3.0),
    ]);

    await service.savePath('abc', const <GeoPoint>[
      GeoPoint(4.0, 5.0),
      GeoPoint(6.0, 7.0),
      GeoPoint(8.0, 9.0),
    ]);

    final loaded = await service.loadAllPaths();
    final restored = loaded['abc'];
    expect(restored, isNotNull);
    expect(restored, hasLength(3));
    expect(restored!.first.lat, 4.0);
    expect(restored.last.lon, 9.0);
  });

  test('loadAllPaths throws when GeoJSON cannot be parsed', () async {
    final fs = _FakeTollSegmentsFileSystem();
    fs.files[cachePath] = 'not-json';
    final service = _createService(fs);

    await expectLater(
      service.loadAllPaths(),
      throwsA(isA<SegmentPathCacheException>()),
    );
  });
}
