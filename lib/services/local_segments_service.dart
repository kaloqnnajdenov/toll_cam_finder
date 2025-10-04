import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'toll_segments_csv_constants.dart';
import 'toll_segments_file_system.dart';
import 'toll_segments_file_system_stub.dart'
    if (dart.library.io) 'toll_segments_file_system_io.dart' as fs_impl;
import 'toll_segments_paths.dart';

/// Persists user-created segments to the local toll segments CSV.
class LocalSegmentsService {
  LocalSegmentsService({
    TollSegmentsFileSystem? fileSystem,
    TollSegmentsPathResolver? pathResolver,
  })  : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
        _pathResolver = pathResolver;

  final TollSegmentsFileSystem _fileSystem;
  final TollSegmentsPathResolver? _pathResolver;

  /// Stores a user-created segment on disk. The resulting row is marked with a
  /// local identifier so that it survives future synchronisation runs.
  Future<void> saveLocalSegment({
    required String name,
    required String startCoordinates,
    required String endCoordinates,
  }) async {
    if (kIsWeb) {
      throw const LocalSegmentsServiceException(
        'Saving local segments is not supported on the web.',
      );
    }

    final normalizedName = name.trim().isEmpty ? 'Personal segment' : name.trim();
    final normalizedStart = _normalizeCoordinates(startCoordinates);
    final normalizedEnd = _normalizeCoordinates(endCoordinates);

    final csvPath = await resolveTollSegmentsDataPath(
      overrideResolver: _pathResolver,
    );
    await _fileSystem.ensureParentDirectory(csvPath);

    final rows = await _readExistingRows(csvPath);
    if (rows.isEmpty) {
      rows.add(TollSegmentsCsvSchema.header);
    } else if (!_isHeaderRow(rows.first)) {
      rows.insert(0, TollSegmentsCsvSchema.header);
    }

    final newRow = <String>[
      _generateLocalId(),
      normalizedName,
      '$normalizedName start',
      '$normalizedName end',
      normalizedStart,
      normalizedEnd,
    ];

    rows.add(newRow);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(rows);

    await _fileSystem.writeAsString(csvPath, '$csv\n');
  }

  Future<List<List<String>>> _readExistingRows(String path) async {
    if (!await _fileSystem.exists(path)) {
      return <List<String>>[];
    }

    final contents = await _fileSystem.readAsString(path);
    if (contents.trim().isEmpty) {
      return <List<String>>[];
    }

    final parsed = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(contents);

    return parsed
        .map((row) => row.map((cell) => cell.toString()).toList(growable: false))
        .toList(growable: true);
  }

  bool _isHeaderRow(List<String> row) {
    if (row.length != TollSegmentsCsvSchema.header.length) {
      return false;
    }
    for (var i = 0; i < row.length; i++) {
      if (row[i].trim() != TollSegmentsCsvSchema.header[i]) {
        return false;
      }
    }
    return true;
  }

  String _generateLocalId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    return '${TollSegmentsCsvSchema.localSegmentIdPrefix}$timestamp-$random';
  }

  String _normalizeCoordinates(String input) {
    final parts = input.split(',');
    if (parts.length < 2) {
      throw const LocalSegmentsServiceException(
        'Coordinates must be provided in the format "lat, lon".',
      );
    }

    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    if (lat == null || lon == null) {
      throw const LocalSegmentsServiceException(
        'Coordinates must be valid decimal numbers.',
      );
    }

    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }
}

class LocalSegmentsServiceException implements Exception {
  const LocalSegmentsServiceException(this.message);

  final String message;

  @override
  String toString() => 'LocalSegmentsServiceException: $message';
}
