import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/core/app_messages.dart';

import 'weigh_stations_csv_constants.dart';
import 'weigh_stations_data_store.dart';
import 'weigh_stations_file_system.dart';
import 'weigh_stations_file_system_stub.dart'
    if (dart.library.io) 'weigh_stations_file_system_io.dart' as fs_impl;
import 'weigh_stations_paths.dart';

class WeighStationsSyncResult {
  const WeighStationsSyncResult({
    required this.downloaded,
    required this.removed,
    required this.localApproved,
  });

  final int downloaded;
  final int removed;
  final int localApproved;
}

class WeighStationsSyncException implements Exception {
  const WeighStationsSyncException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'WeighStationsSyncException: $message';
}

class WeighStationsSyncService {
  WeighStationsSyncService({
    this.tableName = 'Weigh_Stations',
    WeighStationsFileSystem? fileSystem,
    WeighStationsPathResolver? localPathResolver,
  })  : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
        _localPathResolver = localPathResolver;

  final String tableName;
  final WeighStationsFileSystem _fileSystem;
  final WeighStationsPathResolver? _localPathResolver;

  static const String _addedByUserColumn = 'added_by_user';

  Future<WeighStationsSyncResult> sync({
    required SupabaseClient client,
  }) async {
    if (kIsWeb) {
      throw const WeighStationsSyncException(
        'Sync is not supported on the web.',
      );
    }

    try {
      final localCsvPath = await _resolveLocalCsvPath();
      await _fileSystem.ensureParentDirectory(localCsvPath);

      final remoteRows = await _fetchRemoteRows(client);
      final localRows = await _readLocalRows(localCsvPath);
      final approvalOutcome = _filterApprovedLocalStations(
        remoteRows,
        localRows.localRows,
      );
      final diff = _calculateDiff(
        localRows.remoteRows,
        remoteRows,
        approvedLocalStations: approvalOutcome.approvedCount,
      );

      await _writeLocalRows(localCsvPath, approvalOutcome.remainingLocalRows);
      WeighStationsDataStore.instance.updateRemoteRows(remoteRows);

      return diff;
    } on WeighStationsSyncException {
      rethrow;
    } on SocketException catch (error) {
      throw WeighStationsSyncException(
        AppMessages.syncRequiresInternetConnection,
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw WeighStationsSyncException(
        AppMessages.failedToDownloadWeighStations(error.message),
        cause: error,
      );
    } on WeighStationsFileSystemException catch (error) {
      throw WeighStationsSyncException(
        AppMessages.failedToAccessWeighStationsFile(error.message),
        cause: error,
      );
    } catch (error, stackTrace) {
      throw WeighStationsSyncException(
        AppMessages.unexpectedSyncError,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<List<String>>> _fetchRemoteRows(SupabaseClient client) async {
    final attemptedTables = <String>[];
    PostgrestException? lastMissingTableException;

    for (final candidate in _candidateTableNames) {
      try {
        final response = await _selectRemoteRows(client, candidate);

        if (candidate != tableName) {
          debugPrint(
            'WeighStationsSyncService: using "$candidate" as the weigh stations source.',
          );
        }

        return response
            .map((record) => _toCanonicalRow(record))
            .toList(growable: false);
      } on WeighStationsSyncException {
        rethrow;
      } on PostgrestException catch (error) {
        if (_isMissingTableError(error)) {
          attemptedTables.add(candidate);
          lastMissingTableException = error;
          continue;
        }
        rethrow;
      }
    }

    if (attemptedTables.isEmpty) {
      throw WeighStationsSyncException(
        AppMessages.tableReturnedNoRows(tableName),
        cause: lastMissingTableException,
      );
    }

    throw WeighStationsSyncException(
      AppMessages.noTollSegmentRowsFound(attemptedTables.join(', ')),
      cause: lastMissingTableException,
    );
  }

  Future<List<Map<String, dynamic>>> _selectRemoteRows(
    SupabaseClient client,
    String table,
  ) async {
    final List<dynamic> response = await client.from(table).select('*');

    return response
        .cast<Map<String, dynamic>>()
        .map(
          (record) => Map<String, dynamic>.from(record)
            ..removeWhere(
              (key, value) =>
                  _normalize(key) == _normalize(_addedByUserColumn),
            ),
        )
        .toList(growable: false);
  }

  Iterable<String> get _candidateTableNames {
    final normalized = tableName.trim();
    final lower = normalized.toLowerCase();
    final snake = _toSnakeCase(normalized);
    final title = lower.isEmpty
        ? lower
        : lower[0].toUpperCase() + lower.substring(1);

    return <String>{normalized, lower, title, snake}
      ..removeWhere((name) => name.isEmpty);
  }

  bool _isMissingTableError(PostgrestException error) {
    final code = error.code?.toUpperCase();
    if (code == '42P01') {
      return true;
    }
    final message = error.message.toLowerCase();
    return message.contains('does not exist') ||
        message.contains('not exist') ||
        message.contains('unknown table');
  }

  Future<String> _resolveLocalCsvPath() async {
    return resolveWeighStationsDataPath(
      overrideResolver: _localPathResolver,
    );
  }

  Future<_LocalRows> _readLocalRows(String path) async {
    if (!await _fileSystem.exists(path)) {
      return const _LocalRows.empty();
    }

    final raw = await _fileSystem.readAsString(path);
    if (raw.trim().isEmpty) {
      return const _LocalRows.empty();
    }

    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(raw);

    if (rows.isEmpty) {
      return const _LocalRows.empty();
    }

    final header = rows.first
        .map((value) => value.toString())
        .toList(growable: false);
    final dataRows = rows
        .skip(1)
        .map(
          (row) => row
              .map((value) => value.toString())
              .toList(growable: false),
        )
        .toList(growable: false);

    return _LocalRows(header: header, rows: dataRows);
  }

  Future<void> _writeLocalRows(
    String path,
    List<List<String>> rows,
  ) async {
    final csvRows = <List<String>>[]
      ..add(WeighStationsCsvSchema.header)
      ..addAll(rows);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(csvRows);

    await _fileSystem.writeAsString(path, '$csv\n');
  }

  _ApprovalOutcome _filterApprovedLocalStations(
    List<List<String>> remoteRows,
    List<List<String>> localRows,
  ) {
    if (localRows.isEmpty) {
      return const _ApprovalOutcome(
        approvedCount: 0,
        remainingLocalRows: <List<String>>[],
      );
    }

    final remoteIds = remoteRows.map((row) => row.first).toSet();
    final remaining = <List<String>>[];
    var approved = 0;
    for (final row in localRows) {
      if (row.isEmpty) {
        continue;
      }
      final id = row.first;
      if (!id.startsWith(WeighStationsCsvSchema.localWeighStationIdPrefix)) {
        continue;
      }
      if (remoteIds.contains(id)) {
        approved += 1;
        continue;
      }
      remaining.add(row);
    }

    return _ApprovalOutcome(
      approvedCount: approved,
      remainingLocalRows: remaining,
    );
  }

  WeighStationsSyncResult _calculateDiff(
    List<List<String>> localRemoteRows,
    List<List<String>> remoteRows,
    {required int approvedLocalStations,}
  ) {
    final localIds = localRemoteRows.map((row) => row.first).toSet();
    final remoteIds = remoteRows.map((row) => row.first).toSet();

    final added = remoteIds.difference(localIds).length;
    final removed = localIds.difference(remoteIds).length;

    return WeighStationsSyncResult(
      downloaded: added,
      removed: removed,
      localApproved: approvedLocalStations,
    );
  }

  List<String> _toCanonicalRow(Map<String, dynamic> record) {
    final normalized = <String, String>{};
    record.forEach((key, value) {
      normalized[_normalize(key)] = value?.toString() ?? '';
    });

    final id = normalized['id'] ?? '';
    final name = normalized['name'] ?? '';
    final road = normalized['road'] ?? '';
    final coordinates = normalized['coordinates'] ?? '';

    return <String>[id, name, road, coordinates];
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _toSnakeCase(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (_isUppercase(char) && i > 0 && value[i - 1] != '_') {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  bool _isUppercase(String char) {
    return char.toUpperCase() == char && char.toLowerCase() != char;
  }
}

class _LocalRows {
  const _LocalRows({required this.header, required this.rows});

  const _LocalRows.empty()
      : header = const <String>[],
        rows = const <List<String>>[];

  final List<String> header;
  final List<List<String>> rows;

  List<List<String>> get localRows => rows;

  List<List<String>> get remoteRows => rows
      .where(
        (row) => !row.first
            .startsWith(WeighStationsCsvSchema.localWeighStationIdPrefix),
      )
      .toList(growable: false);
}

class _ApprovalOutcome {
  const _ApprovalOutcome({
    required this.approvedCount,
    required this.remainingLocalRows,
  });

  final int approvedCount;
  final List<List<String>> remainingLocalRows;
}
