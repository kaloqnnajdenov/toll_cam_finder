import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'package:toll_cam_finder/core/app_messages.dart';

import 'weigh_stations_csv_constants.dart';
import 'weigh_stations_data_store.dart';
import 'weigh_stations_file_system.dart';
import 'weigh_stations_file_system_stub.dart'
    if (dart.library.io) 'weigh_stations_file_system_io.dart' as fs_impl;
import 'weigh_stations_paths.dart';

class LocalWeighStationsService {
  LocalWeighStationsService({
    WeighStationsFileSystem? fileSystem,
    WeighStationsPathResolver? pathResolver,
  })  : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
        _pathResolver = pathResolver;

  final WeighStationsFileSystem _fileSystem;
  final WeighStationsPathResolver? _pathResolver;

  Future<void> saveStation({
    required String coordinates,
  }) async {
    final draft = prepareDraft(
      coordinates: coordinates,
    );
    await saveDraft(draft);
  }

  WeighStationDraft prepareDraft({
    required String coordinates,
  }) {
    final normalizedCoordinates = coordinates.trim();

    if (normalizedCoordinates.isEmpty) {
      throw LocalWeighStationsServiceException(
        AppMessages.coordinatesMustBeProvided,
      );
    }

    return WeighStationDraft(
      coordinates: normalizedCoordinates,
    );
  }

  Future<String> saveDraft(WeighStationDraft draft) async {
    if (kIsWeb) {
      throw LocalWeighStationsServiceException(
        AppMessages.savingLocalSegmentsNotSupportedOnWeb,
      );
    }

    final csvPath = await resolveWeighStationsDataPath(
      overrideResolver: _pathResolver,
    );
    await _fileSystem.ensureParentDirectory(csvPath);

    final rows = await _readExistingRows(csvPath);
    if (rows.isEmpty) {
      rows.add(WeighStationsCsvSchema.header);
    } else if (!_isHeaderRow(rows.first)) {
      rows.insert(0, WeighStationsCsvSchema.header);
    } else if (rows.first.length != WeighStationsCsvSchema.header.length) {
      rows[0] = WeighStationsCsvSchema.header;
    }

    final remoteRows = await WeighStationsDataStore.instance.ensureRemoteRows();
    final remoteIds = remoteRows.map((row) => row.isNotEmpty ? row.first : '');
    final existingLocalIds = rows
        .where((row) => row.isNotEmpty)
        .where((row) => row.first.toLowerCase() != 'id')
        .map((row) => row.first);

    final localId = _generateLocalId(
      existingLocalIds: existingLocalIds,
      remoteIds: remoteIds,
    );

    rows.add(_buildLocalRow(localId: localId, coordinates: draft.coordinates));

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(rows);

    await _fileSystem.writeAsString(csvPath, '$csv\n');
    return localId;
  }

  Future<List<List<String>>> _readExistingRows(String path) async {
    if (!await _fileSystem.exists(path)) {
      return <List<String>>[];
    }
    final raw = await _fileSystem.readAsString(path);
    if (raw.trim().isEmpty) {
      return <List<String>>[];
    }
    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(raw);
    return rows
        .map((row) => row.map((value) => '$value').toList())
        .toList();
  }

  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) {
      return false;
    }
    final maxIndex = math.min(row.length, WeighStationsCsvSchema.header.length);
    for (var i = 0; i < maxIndex; i++) {
      if ('${row[i]}'.trim().toLowerCase() !=
          WeighStationsCsvSchema.header[i].trim().toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  String _generateLocalId({
    required Iterable<String> existingLocalIds,
    required Iterable<String> remoteIds,
  }) {
    final used = <int>{};
    final prefix = WeighStationsCsvSchema.localWeighStationIdPrefix;
    for (final id in existingLocalIds.followedBy(remoteIds)) {
      if (id.startsWith(prefix)) {
        final value = int.tryParse(id.substring(prefix.length));
        if (value != null) {
          used.add(value);
        }
      }
    }

    var candidate = 1;
    while (used.contains(candidate)) {
      candidate += 1;
    }
    return '$prefix$candidate';
  }

  Future<bool> deleteLocalStation(String id) async {
    if (kIsWeb) {
      throw LocalWeighStationsServiceException(
        AppMessages.deletingLocalWeighStationsNotSupportedOnWeb,
      );
    }

    if (!id.startsWith(WeighStationsCsvSchema.localWeighStationIdPrefix)) {
      throw LocalWeighStationsServiceException(
        AppMessages.onlyLocalWeighStationsCanBeDeleted,
      );
    }

    final csvPath = await resolveWeighStationsDataPath(
      overrideResolver: _pathResolver,
    );

    if (!await _fileSystem.exists(csvPath)) {
      return false;
    }

    final rows = await _readExistingRows(csvPath);
    if (rows.isEmpty) {
      return false;
    }

    final updatedRows = <List<String>>[];
    var removed = false;

    for (final row in rows) {
      if (_isHeaderRow(row)) {
        updatedRows.add(row);
        continue;
      }

      if (row.isNotEmpty && row.first == id) {
        removed = true;
        continue;
      }

      updatedRows.add(row);
    }

    if (!removed) {
      return false;
    }

    if (updatedRows.isEmpty) {
      await _fileSystem.writeAsString(csvPath, '');
      return true;
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(updatedRows);

    await _fileSystem.writeAsString(csvPath, '$csv\n');
    return true;
  }

  List<String> _buildLocalRow({
    required String localId,
    required String coordinates,
  }) {
    final row = List<String>.filled(WeighStationsCsvSchema.header.length, '');
    final idIndex =
        WeighStationsCsvSchema.header.indexOf(WeighStationsCsvSchema.columnId);
    if (idIndex >= 0) {
      row[idIndex] = localId;
    }
    final coordinatesIndex = WeighStationsCsvSchema.header
        .indexOf(WeighStationsCsvSchema.columnCoordinates);
    if (coordinatesIndex >= 0) {
      row[coordinatesIndex] = coordinates;
    }
    final upvotesIndex = WeighStationsCsvSchema.header
        .indexOf(WeighStationsCsvSchema.columnUpvotes);
    if (upvotesIndex >= 0) {
      row[upvotesIndex] = '0';
    }
    final downvotesIndex = WeighStationsCsvSchema.header
        .indexOf(WeighStationsCsvSchema.columnDownvotes);
    if (downvotesIndex >= 0) {
      row[downvotesIndex] = '0';
    }
    return row;
  }
}

class WeighStationDraft {
  const WeighStationDraft({
    required this.coordinates,
  });

  final String coordinates;
}

class LocalWeighStationsServiceException implements Exception {
  const LocalWeighStationsServiceException(this.message);

  final String message;
}
