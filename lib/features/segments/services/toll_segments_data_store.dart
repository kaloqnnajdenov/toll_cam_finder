import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'toll_segments_csv_constants.dart';
import 'toll_segments_file_system.dart';
import 'toll_segments_paths.dart';

/// In-memory cache for the latest toll segment data downloaded via sync.
class TollSegmentsDataStore {
  TollSegmentsDataStore._();

  static final TollSegmentsDataStore instance = TollSegmentsDataStore._();

  List<List<String>>? _remoteRows;

  /// Returns the cached remote rows if a sync has completed in this session.
  List<List<String>>? get remoteRows => _remoteRows;

  /// Updates the cached remote rows.
  void updateRemoteRows(List<List<String>> rows) {
    _remoteRows = List<List<String>>.from(
      rows.map((row) => List<String>.from(row)),
      growable: false,
    );
  }

  /// Ensures the remote rows are loaded into memory and returns a copy.
  Future<List<List<String>>> ensureRemoteRows({
    String assetPath = kTollSegmentsAssetPath,
  }) async {
    final rows = await _ensureRemoteRows(assetPath: assetPath);
    return List<List<String>>.from(
      rows.map((row) => List<String>.from(row)),
      growable: false,
    );
  }

  /// Clears the cached remote rows.
  void clear() {
    _remoteRows = null;
  }

  /// Loads the combined toll segment CSV contents by merging the remote rows
  /// from the last sync (if available) with the locally stored custom segments.
  Future<String> loadCombinedCsv({
    required TollSegmentsFileSystem fileSystem,
    String assetPath = kTollSegmentsAssetPath,
    TollSegmentsPathResolver? pathResolver,
  }) async {
    final remoteRows = await _ensureRemoteRows(assetPath: assetPath);
    final localRows = await _maybeLoadLocalRows(
      fileSystem: fileSystem,
      pathResolver: pathResolver,
    );

    final csvRows = <List<String>>[]
      ..add(TollSegmentsCsvSchema.header)
      ..addAll(remoteRows)
      ..addAll(localRows);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(csvRows);

    return '$csv\n';
  }

  /// Reads and returns the locally stored custom segments.
  Future<List<List<String>>> loadLocalRows({
    required TollSegmentsFileSystem fileSystem,
    TollSegmentsPathResolver? pathResolver,
  }) async {
    final csvPath = await resolveTollSegmentsDataPath(
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
          .startsWith(TollSegmentsCsvSchema.localSegmentIdPrefix)) {
        continue;
      }

      rows.add(normalized);
    }

    return rows;
  }

  Future<List<List<String>>> _maybeLoadLocalRows({
    required TollSegmentsFileSystem fileSystem,
    TollSegmentsPathResolver? pathResolver,
  }) async {
    if (kIsWeb) {
      return const <List<String>>[];
    }

    try {
      return await loadLocalRows(
        fileSystem: fileSystem,
        pathResolver: pathResolver,
      );
    } on TollSegmentsFileSystemException {
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
        'TollSegmentsDataStore: no bundled toll segments found at '
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
