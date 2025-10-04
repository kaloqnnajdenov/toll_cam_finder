import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'toll_segments_csv_constants.dart';
import 'toll_segments_file_system.dart';
import 'toll_segments_file_system_stub.dart'
    if (dart.library.io) 'toll_segments_file_system_io.dart' as fs_impl;
import 'toll_segments_paths.dart';
import 'segment_id_generator.dart';

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
    bool isPublic = false,
  }) async {
    final draft = prepareDraft(
      name: name,
      startCoordinates: startCoordinates,
      endCoordinates: endCoordinates,
    );

    await saveDraft(draft, isPublic: isPublic);
  }

  /// Normalizes the provided input fields and returns a [SegmentDraft] that can
  /// be stored locally or submitted to the backend.
  SegmentDraft prepareDraft({
    required String name,
    required String startCoordinates,
    required String endCoordinates,
  }) {
    final normalizedName = name.trim().isEmpty ? 'Personal segment' : name.trim();
    final normalizedStart = _normalizeCoordinates(startCoordinates);
    final normalizedEnd = _normalizeCoordinates(endCoordinates);

    return SegmentDraft(
      name: normalizedName,
      startDisplayName: '$normalizedName start',
      endDisplayName: '$normalizedName end',
      startCoordinates: normalizedStart,
      endCoordinates: normalizedEnd,
    );
  }

  /// Persists a [SegmentDraft] locally and returns the generated identifier.
  Future<String> saveDraft(
    SegmentDraft draft, {
    bool isPublic = false,
  }) async {
    if (kIsWeb) {
      throw const LocalSegmentsServiceException(
        'Saving local segments is not supported on the web.',
      );
    }

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

    final localId = SegmentIdGenerator.generateLocalId();
    final newRow = <String>[
      localId,
      draft.name,
      draft.startDisplayName,
      draft.endDisplayName,
      draft.startCoordinates,
      draft.endCoordinates,
    ];

    rows.add(newRow);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(rows);

    await _fileSystem.writeAsString(csvPath, '$csv\n');

    try {
      await _updateSubmissionFlag(localId, isPublic);
    } catch (error) {
      debugPrint('Failed to update submission flag for $localId: $error');
    }

    return localId;
  }

  Future<bool> deleteLocalSegment(String id) async {
    if (kIsWeb) {
      throw const LocalSegmentsServiceException(
        'Deleting local segments is not supported on the web.',
      );
    }

    if (!id.startsWith(TollSegmentsCsvSchema.localSegmentIdPrefix)) {
      throw const LocalSegmentsServiceException(
        'Only segments saved locally can be deleted.',
      );
    }

    final csvPath = await resolveTollSegmentsDataPath(
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
    } else {
      final csv = const ListToCsvConverter(
        fieldDelimiter: ';',
        textDelimiter: '"',
        textEndDelimiter: '"',
      ).convert(updatedRows);

      await _fileSystem.writeAsString(csvPath, '$csv\n');
    }

    try {
      await _updateSubmissionFlag(id, false);
    } catch (error) {
      debugPrint('Failed to clear submission flag for $id: $error');
    }

    return true;
  }

  Future<bool> isSubmittedForPublicReview(String id) async {
    if (kIsWeb) {
      return false;
    }

    final metadataPath = await resolveTollSegmentsMetadataPath(
      overrideResolver: _pathResolver,
    );
    final submitted = await _readSubmittedSegmentIds(metadataPath);
    return submitted.contains(id);
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

  Future<void> _updateSubmissionFlag(String id, bool isPublic) async {
    if (kIsWeb) {
      return;
    }

    final metadataPath = await resolveTollSegmentsMetadataPath(
      overrideResolver: _pathResolver,
    );

    await _fileSystem.ensureParentDirectory(metadataPath);
    final submitted = await _readSubmittedSegmentIds(metadataPath);

    if (isPublic) {
      submitted.add(id);
    } else {
      submitted.remove(id);
    }

    if (submitted.isEmpty) {
      await _fileSystem.writeAsString(metadataPath, '');
      return;
    }

    final payload = jsonEncode(submitted.toList()..sort());
    await _fileSystem.writeAsString(metadataPath, '$payload\n');
  }

  Future<Set<String>> _readSubmittedSegmentIds(String path) async {
    if (!await _fileSystem.exists(path)) {
      return <String>{};
    }

    final contents = await _fileSystem.readAsString(path);
    if (contents.trim().isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(contents);
      if (decoded is List) {
        return decoded.map((entry) => '$entry').toSet();
      }
    } catch (_) {
      // Ignore malformed metadata and treat it as absent.
    }

    return <String>{};
  }
}

class LocalSegmentsServiceException implements Exception {
  const LocalSegmentsServiceException(this.message);

  final String message;

  @override
  String toString() => 'LocalSegmentsServiceException: $message';
}

/// Normalized representation of a user-created segment.
class SegmentDraft {
  const SegmentDraft({
    required this.name,
    required this.startDisplayName,
    required this.endDisplayName,
    required this.startCoordinates,
    required this.endCoordinates,
  });

  final String name;
  final String startDisplayName;
  final String endDisplayName;
  final String startCoordinates;
  final String endCoordinates;
}
