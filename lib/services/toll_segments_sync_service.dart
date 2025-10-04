import 'dart:async';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'toll_segments_file_system.dart';
import 'toll_segments_file_system_stub.dart'
    if (dart.library.io) 'toll_segments_file_system_io.dart'
    as fs_impl;
import 'toll_segments_paths.dart';
import 'toll_segments_csv_constants.dart';

/// Handles downloading the latest toll segments from Supabase, comparing them
/// with the local CSV asset, and writing back the updated data.
class TollSegmentsSyncService {
  TollSegmentsSyncService({
    this.tableName = 'Toll_Segments',
    TollSegmentsFileSystem? fileSystem,
    TollSegmentsPathResolver? localPathResolver,
  }) : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
       _localPathResolver = localPathResolver;

  /// Supabase table that stores the toll segment rows.
  final String tableName;

  final TollSegmentsFileSystem _fileSystem;
  final TollSegmentsPathResolver? _localPathResolver;

  static const String _moderationStatusColumn = 'moderation_status';
  static const String _approvedStatus = 'approved';

  /// Performs the synchronization flow.
  ///
  /// 1. Downloads the latest table contents from Supabase.
  /// 2. Compares them to the current local CSV, calculating additions/removals.
  /// 3. Writes the downloaded data to the local CSV file.
  Future<TollSegmentsSyncResult> sync({required SupabaseClient client}) async {
    if (kIsWeb) {
      throw const TollSegmentsSyncException(
        'Syncing toll segments is not supported on the web.',
      );
    }

    try {
      final localCsvPath = await _resolveLocalCsvPath();
      await _fileSystem.ensureParentDirectory(localCsvPath);

      final remoteRows = await _fetchRemoteRows(client);

      final localRows = await _readLocalRows(localCsvPath);
      final approvalOutcome = _filterApprovedLocalSegments(
        remoteRows,
        localRows.localRows,
      );
      final diff = _calculateDiff(
        localRows.remoteRows,
        remoteRows,
        approvedLocalSegments: approvalOutcome.approvedCount,
      );
      await _writeRowsToLocal(
        localCsvPath,
        remoteRows,
        approvalOutcome.remainingLocalRows,
      );

      return diff;
    } on TollSegmentsSyncException {
      rethrow;
    } on PostgrestException catch (error) {
      throw TollSegmentsSyncException(
        'Failed to download toll segments: ${error.message}',
        cause: error,
      );
    } on TollSegmentsFileSystemException catch (error) {
      throw TollSegmentsSyncException(
        'Failed to access the toll segments file: ${error.message}',
        cause: error,
      );
    } catch (error, stackTrace) {
      throw TollSegmentsSyncException(
        'Unexpected error while syncing toll segments.',
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
        final response = await _selectApprovedRows(client, candidate);

        if (candidate != tableName) {
          debugPrint(
            'TollSegmentsSyncService: using "$candidate" as the toll segments source.',
          );
        }

        return response
            .map((record) => _toCanonicalRow(record))
            .toList(growable: false);
      } on TollSegmentsSyncException {
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
      throw TollSegmentsSyncException(
        'The $tableName table did not return any rows.',
        cause: lastMissingTableException,
      );
    }

    throw TollSegmentsSyncException(
      'No toll segment rows were returned from Supabase. Checked tables: '
      '${attemptedTables.join(', ')}. Ensure your account has access to the data.',
      cause: lastMissingTableException,
    );
  }

  Future<List<Map<String, dynamic>>> _selectApprovedRows(
    SupabaseClient client,
    String table,
  ) async {
    try {
      final List<dynamic> response = await client
          .from(table)
          .select('*')
          .eq(_moderationStatusColumn, _approvedStatus);

      return response.cast<Map<String, dynamic>>();
    } on PostgrestException catch (error) {
      if (_isMissingColumnError(error, _moderationStatusColumn)) {
        throw TollSegmentsSyncException(
          'The "$table" table is missing the "$_moderationStatusColumn" column required for moderation.',
          cause: error,
        );
      }
      rethrow;
    }
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

  bool _isMissingColumnError(PostgrestException error, String column) {
    final code = error.code?.toUpperCase();
    if (code == '42703') {
      return true;
    }

    final normalizedMessage = error.message.toLowerCase();
    return normalizedMessage.contains('column') &&
        normalizedMessage.contains(column.toLowerCase()) &&
        (normalizedMessage.contains('does not exist') ||
            normalizedMessage.contains('not exist'));
  }

  String _toSnakeCase(String value) {
    final buffer = StringBuffer();
    var lastWasSeparator = false;
    var hasOutput = false;

    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final isUppercase =
          char.toUpperCase() == char && char.toLowerCase() != char;
      final isAlphabetic = char.toLowerCase() != char.toUpperCase();
      final isNumeric = int.tryParse(char) != null;

      if (isAlphabetic || isNumeric) {
        if (isUppercase && hasOutput && !lastWasSeparator) {
          buffer.write('_');
        }
        buffer.write(char.toLowerCase());
        hasOutput = true;
        lastWasSeparator = false;
      } else if (hasOutput && !lastWasSeparator) {
        buffer.write('_');
        lastWasSeparator = true;
      }
    }

    var result = buffer.toString();
    if (result.endsWith('_')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  Future<_PartitionedLocalRows> _readLocalRows(String localCsvPath) async {
    final exists = await _fileSystem.exists(localCsvPath);
    if (!exists) {
      return const _PartitionedLocalRows();
    }

    final raw = await _fileSystem.readAsString(localCsvPath);
    if (raw.trim().isEmpty) {
      return const _PartitionedLocalRows();
    }

    final parsed = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(raw);

    if (parsed.length <= 1) {
      return const _PartitionedLocalRows();
    }

    final remoteRows = <List<String>>[];
    final localRows = <List<String>>[];

    for (final row in parsed.skip(1)) {
      final normalized = row
          .map((value) => value.toString())
          .toList(growable: false);
      if (normalized.isEmpty) {
        continue;
      }

      final id = normalized.first;
      if (id.startsWith(TollSegmentsCsvSchema.localSegmentIdPrefix)) {
        localRows.add(normalized);
      } else {
        remoteRows.add(normalized);
      }
    }

    return _PartitionedLocalRows(remoteRows: remoteRows, localRows: localRows);
  }

  Future<void> _writeRowsToLocal(
    String localCsvPath,
    List<List<String>> remoteRows,
    List<List<String>> localRows,
  ) async {
    final csvRows = <List<String>>[];
    csvRows.add(TollSegmentsCsvSchema.header);
    csvRows.addAll(remoteRows);
    csvRows.addAll(localRows);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(csvRows);

    await _fileSystem.writeAsString(localCsvPath, '$csv\n');
  }

  Future<String> _resolveLocalCsvPath() async {
    try {
      return await resolveTollSegmentsDataPath(
        overrideResolver: _localPathResolver,
      );
    } catch (error, stackTrace) {
      throw TollSegmentsSyncException(
        'Failed to determine the local toll segments storage path.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  TollSegmentsSyncResult _calculateDiff(
    List<List<String>> localRows,
    List<List<String>> remoteRows, {
    int approvedLocalSegments = 0,
  }) {
    final localSet = localRows.map(_canonicalizeForDiff).toSet();
    final remoteSet = remoteRows.map(_canonicalizeForDiff).toSet();

    final added = remoteSet.difference(localSet).length;
    final removed = localSet.difference(remoteSet).length;

    return TollSegmentsSyncResult(
      addedSegments: added,
      removedSegments: removed,
      totalSegments: remoteRows.length,
      approvedLocalSegments: approvedLocalSegments,
    );
  }

  _ApprovedLocalSegmentsOutcome _filterApprovedLocalSegments(
    List<List<String>> remoteRows,
    List<List<String>> localRows,
  ) {
    if (remoteRows.isEmpty || localRows.isEmpty) {
      return _ApprovedLocalSegmentsOutcome(
        remainingLocalRows: localRows,
        approvedCount: 0,
      );
    }

    final remoteCounts = <String, int>{};
    for (final row in remoteRows) {
      final signature = _signatureExcludingId(row);
      if (signature.isEmpty) {
        continue;
      }
      remoteCounts.update(signature, (value) => value + 1, ifAbsent: () => 1);
    }

    final remainingLocalRows = <List<String>>[];
    var approvedCount = 0;

    for (final row in localRows) {
      final signature = _signatureExcludingId(row);
      if (signature.isEmpty) {
        remainingLocalRows.add(row);
        continue;
      }

      final available = remoteCounts[signature];
      if (available != null && available > 0) {
        approvedCount++;
        if (available == 1) {
          remoteCounts.remove(signature);
        } else {
          remoteCounts[signature] = available - 1;
        }
        continue;
      }

      remainingLocalRows.add(row);
    }

    return _ApprovedLocalSegmentsOutcome(
      remainingLocalRows: remainingLocalRows,
      approvedCount: approvedCount,
    );
  }

  String _signatureExcludingId(List<String> row) {
    if (row.length <= 1) {
      return '';
    }

    return row.skip(1).map((value) => value.trim().toLowerCase()).join('|');
  }

  List<String> _toCanonicalRow(Map<String, dynamic> record) {
    final values = <String>[];
    for (final column in TollSegmentsCsvSchema.header) {
      final value = _extractField(record, column);
      if (value == null) {
        throw TollSegmentsSyncException(
          'Missing required column "$column" in the Toll_Segments table.',
        );
      }
      values.add(value);
    }
    return values;
  }

  String _canonicalizeForDiff(List<String> row) {
    return row.map((value) => value.trim()).join('|');
  }

  String? _extractField(Map<String, dynamic> record, String column) {
    final normalizedColumn = _normalize(column);
    for (final entry in record.entries) {
      final key = entry.key;
      final normalizedKey = _normalize(key);
      if (normalizedColumn == normalizedKey) {
        return entry.value?.toString() ?? '';
      }
    }

    // Support a few aliases commonly used when exporting CSVs.
    for (final alias in _columnAliases[column] ?? const <String>[]) {
      final normalizedAlias = _normalize(alias);
      for (final entry in record.entries) {
        if (_normalize(entry.key) == normalizedAlias) {
          return entry.value?.toString() ?? '';
        }
      }
    }

    return null;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static const Map<String, List<String>> _columnAliases =
      <String, List<String>>{
        'ID': <String>['id'],
        'road': <String>['road_name'],
        'Start name': <String>['start_name', 'startname'],
        'End name': <String>['end_name', 'endname'],
        'Start': <String>['start_point', 'start_coordinates'],
        'End': <String>['end_point', 'end_coordinates'],
      };
}

/// Result of synchronizing toll segments from Supabase to the local CSV.
class TollSegmentsSyncResult {
  const TollSegmentsSyncResult({
    required this.addedSegments,
    required this.removedSegments,
    required this.totalSegments,
    required this.approvedLocalSegments,
  });

  final int addedSegments;
  final int removedSegments;
  final int totalSegments;
  final int approvedLocalSegments;
}

/// Error raised when synchronizing toll segments fails.
class TollSegmentsSyncException implements Exception {
  const TollSegmentsSyncException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'TollSegmentsSyncException: $message';
}

class _PartitionedLocalRows {
  const _PartitionedLocalRows({
    this.remoteRows = const <List<String>>[],
    this.localRows = const <List<String>>[],
  });

  final List<List<String>> remoteRows;
  final List<List<String>> localRows;
}

class _ApprovedLocalSegmentsOutcome {
  const _ApprovedLocalSegmentsOutcome({
    required this.remainingLocalRows,
    required this.approvedCount,
  });

  final List<List<String>> remainingLocalRows;
  final int approvedCount;
}
