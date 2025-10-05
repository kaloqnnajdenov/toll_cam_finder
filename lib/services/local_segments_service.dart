import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'segment_id_generator.dart';
import 'segments_metadata_service.dart';
import 'toll_segments_csv_constants.dart';
import 'toll_segments_file_system.dart';
import 'toll_segments_file_system_stub.dart'
    if (dart.library.io) 'toll_segments_file_system_io.dart' as fs_impl;
import 'toll_segments_paths.dart';

/// Persists user-created segments to the local toll segments CSV.
class LocalSegmentsService {
  factory LocalSegmentsService({
    TollSegmentsFileSystem? fileSystem,
    TollSegmentsPathResolver? pathResolver,
    SegmentsMetadataService? metadataService,
  }) {
    final fs = fileSystem ?? fs_impl.createFileSystem();
    return LocalSegmentsService._(
      fs,
      pathResolver,
      metadataService ??
          SegmentsMetadataService(
            fileSystem: fs,
            pathResolver: pathResolver,
          ),
    );
  }

  LocalSegmentsService._(
    this._fileSystem,
    this._pathResolver,
    this._metadataService,
  );

  final TollSegmentsFileSystem _fileSystem;
  final TollSegmentsPathResolver? _pathResolver;
  final SegmentsMetadataService _metadataService;

  /// Stores a user-created segment on disk. The resulting row is marked with a
  /// local identifier so that it survives future synchronisation runs.
  Future<void> saveLocalSegment({
    required String name,
    String? startDisplayName,
    String? endDisplayName,
    required String startCoordinates,
    required String endCoordinates,
  }) async {
    final draft = prepareDraft(
      name: name,
      startDisplayName: startDisplayName,
      endDisplayName: endDisplayName,
      startCoordinates: startCoordinates,
      endCoordinates: endCoordinates,
    );

    await saveDraft(draft);
  }

  /// Normalizes the provided input fields and returns a [SegmentDraft] that can
  /// be stored locally or submitted to the backend.
  SegmentDraft prepareDraft({
    required String name,
    String? roadName,
    String? startDisplayName,
    String? endDisplayName,
    required String startCoordinates,
    required String endCoordinates,
    bool isPublic = false,
  }) {
    final normalizedName = name.trim().isEmpty ? 'Personal segment' : name.trim();
    final normalizedRoadName = roadName?.trim() ?? '';
    final normalizedStartDisplayName = startDisplayName?.trim();
    final normalizedEndDisplayName = endDisplayName?.trim();
    final normalizedStart = _normalizeCoordinates(startCoordinates);
    final normalizedEnd = _normalizeCoordinates(endCoordinates);

    return SegmentDraft(
      name: normalizedName,
      roadName: normalizedRoadName,
      startDisplayName: normalizedStartDisplayName?.isNotEmpty == true
          ? normalizedStartDisplayName!
          : '$normalizedName start',
      endDisplayName: normalizedEndDisplayName?.isNotEmpty == true
          ? normalizedEndDisplayName!
          : '$normalizedName end',
      startCoordinates: normalizedStart,
      endCoordinates: normalizedEnd,
      isPublic: isPublic,
    );
  }

  /// Persists a [SegmentDraft] locally and returns the generated identifier.
  Future<String> saveDraft(SegmentDraft draft) async {
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
    _upgradeLegacyHeader(rows);
    if (rows.isEmpty) {
      rows.add(TollSegmentsCsvSchema.header);
    } else if (!_isHeaderRow(rows.first)) {
      rows.insert(0, TollSegmentsCsvSchema.header);
    }

    final localId = SegmentIdGenerator.generateLocalId();
    final newRow = <String>[
      localId,
      draft.name,
      draft.roadName,
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
    await _updateVisibilityFlag(localId, draft.isPublic);
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
      await _updateVisibilityFlag(id, false);
      return true;
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(updatedRows);

    await _fileSystem.writeAsString(csvPath, '$csv\n');
    await _updateVisibilityFlag(id, false);
    return true;
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

  void _upgradeLegacyHeader(List<List<String>> rows) {
    if (rows.isEmpty) {
      return;
    }

    const legacyHeader = <String>[
      'ID',
      'road',
      'Start name',
      'End name',
      'Start',
      'End',
    ];

    final headerRow = rows.first;
    if (headerRow.length != legacyHeader.length) {
      return;
    }

    for (var i = 0; i < legacyHeader.length; i++) {
      if (headerRow[i].trim() != legacyHeader[i]) {
        return;
      }
    }

    rows[0] = TollSegmentsCsvSchema.header;
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final upgraded = <String>[];
      if (row.isNotEmpty) {
        upgraded.add(row[0]);
        upgraded.add('');
        upgraded.addAll(row.skip(1));
      }
      while (upgraded.length < TollSegmentsCsvSchema.header.length) {
        upgraded.add('');
      }
      rows[i] = upgraded;
    }
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

  Future<void> _updateVisibilityFlag(String id, bool isPublic) async {
    if (kIsWeb) {
      return;
    }

    await _metadataService.setPublicFlag(id, isPublic);
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

/// Normalized representation of a user-created segment.
class SegmentDraft {
  const SegmentDraft({
    required this.name,
    required this.roadName,
    required this.startDisplayName,
    required this.endDisplayName,
    required this.startCoordinates,
    required this.endCoordinates,
    this.isPublic = false,
  });

  final String name;
  final String roadName;
  final String startDisplayName;
  final String endDisplayName;
  final String startCoordinates;
  final String endCoordinates;
  final bool isPublic;
}
