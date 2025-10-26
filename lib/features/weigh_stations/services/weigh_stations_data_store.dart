import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'weigh_stations_csv_constants.dart';
import 'weigh_stations_file_system.dart';
import 'weigh_stations_paths.dart';

class WeighStationsDataStore {
  WeighStationsDataStore._();

  static final WeighStationsDataStore instance = WeighStationsDataStore._();

  List<List<String>>? _remoteRows;

  List<List<String>>? get remoteRows => _remoteRows;

  void updateRemoteRows(List<List<String>> rows) {
    _remoteRows = List<List<String>>.from(
      rows.map((row) => List<String>.from(row)),
      growable: false,
    );
  }

  Future<List<List<String>>> ensureRemoteRows({
    String assetPath = kWeighStationsAssetPath,
  }) async {
    final rows = await _ensureRemoteRows(assetPath: assetPath);
    return List<List<String>>.from(
      rows.map((row) => List<String>.from(row)),
      growable: false,
    );
  }

  void clear() {
    _remoteRows = null;
  }

  Future<String> loadCombinedCsv({
    required WeighStationsFileSystem fileSystem,
    String assetPath = kWeighStationsAssetPath,
    WeighStationsPathResolver? pathResolver,
  }) async {
    final remoteRows = await _ensureRemoteRows(assetPath: assetPath);
    final localRows = await _maybeLoadLocalRows(
      fileSystem: fileSystem,
      pathResolver: pathResolver,
    );

    final csvRows = <List<String>>[]
      ..add(WeighStationsCsvSchema.header)
      ..addAll(remoteRows)
      ..addAll(localRows);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(csvRows);

    return '$csv\n';
  }

  Future<List<List<String>>> loadLocalRows({
    required WeighStationsFileSystem fileSystem,
    WeighStationsPathResolver? pathResolver,
  }) async {
    final csvPath = await resolveWeighStationsDataPath(
      overrideResolver: pathResolver,
    );

    if (!await fileSystem.exists(csvPath)) {
      return const <List<String>>[];
    }

    final raw = await fileSystem.readAsString(csvPath);
    final parsed = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(raw);

    if (parsed.isEmpty) {
      return const <List<String>>[];
    }

    final rows = <List<String>>[];
    for (final row in parsed.skip(1)) {
      final normalized = row
          .map((value) => value.toString())
          .toList(growable: false);
      if (normalized.isEmpty) {
        continue;
      }

      if (!normalized.first
          .startsWith(WeighStationsCsvSchema.localWeighStationIdPrefix)) {
        continue;
      }

      rows.add(normalized);
    }

    return rows;
  }

  Future<List<List<String>>> _maybeLoadLocalRows({
    required WeighStationsFileSystem fileSystem,
    WeighStationsPathResolver? pathResolver,
  }) async {
    if (kIsWeb) {
      return const <List<String>>[];
    }

    try {
      return await loadLocalRows(
        fileSystem: fileSystem,
        pathResolver: pathResolver,
      );
    } on WeighStationsFileSystemException {
      return const <List<String>>[];
    }
  }

  Future<List<List<String>>> _ensureRemoteRows({
    required String assetPath,
  }) async {
    final cached = _remoteRows;
    if (cached != null) {
      return cached;
    }

    String assetRaw;
    try {
      assetRaw = await rootBundle.loadString(assetPath);
    } on FlutterError catch (error) {
      debugPrint(
        'WeighStationsDataStore: no bundled weigh stations found at '
        '"$assetPath" ($error). Using an empty remote dataset until the '
        'next sync completes.',
      );
      _remoteRows = const <List<String>>[];
      return _remoteRows!;
    }

    final parsed = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(assetRaw);

    if (parsed.length <= 1) {
      return const <List<String>>[];
    }

    final rows = <List<String>>[];
    for (final row in parsed.skip(1)) {
      final normalized = row
          .map((value) => value.toString())
          .toList(growable: false);
      if (normalized.isEmpty) {
        continue;
      }

      rows.add(normalized);
    }

    _remoteRows = rows;
    return rows;
  }
}
