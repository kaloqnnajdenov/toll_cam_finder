import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'package:toll_cam_finder/core/app_messages.dart';

import 'segments_metadata_service.dart';
import 'toll_segments_csv_constants.dart';
import 'toll_segments_file_system.dart';
import 'toll_segments_file_system_stub.dart'
    if (dart.library.io) 'toll_segments_file_system_io.dart'
    as fs_impl;
import 'toll_segments_paths.dart';
import 'segment_id_generator.dart';

/// Persists user-created segments to the local toll segments CSV.
class LocalSegmentsService {
  LocalSegmentsService({
    TollSegmentsFileSystem? fileSystem,
    TollSegmentsPathResolver? pathResolver,
    SegmentsMetadataService? metadataService,
  }) : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
       _pathResolver = pathResolver,
       _metadataService =
           metadataService ??
           SegmentsMetadataService(
             fileSystem: fileSystem,
             pathResolver: pathResolver,
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
    double? speedLimitKph,
  }) async {
    final draft = prepareDraft(
      name: name,
      startDisplayName: startDisplayName,
      endDisplayName: endDisplayName,
      startCoordinates: startCoordinates,
      endCoordinates: endCoordinates,
      speedLimitKph: speedLimitKph,
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
    double? speedLimitKph,
  }) {
    final normalizedName = name.trim().isEmpty
        ? AppMessages.personalSegmentDefaultName
        : name.trim();
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
          : AppMessages.segmentDefaultStartName(normalizedName),
      endDisplayName: normalizedEndDisplayName?.isNotEmpty == true
          ? normalizedEndDisplayName!
          : AppMessages.segmentDefaultEndName(normalizedName),
      startCoordinates: normalizedStart,
      endCoordinates: normalizedEnd,
      isPublic: isPublic,
      speedLimitKph: speedLimitKph,
    );
  }

  /// Persists a [SegmentDraft] locally and returns the generated identifier.
  Future<String> saveDraft(SegmentDraft draft) async {
    if (kIsWeb) {
      throw LocalSegmentsServiceException(
        AppMessages.savingLocalSegmentsNotSupportedOnWeb,
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
      draft.speedLimitKph != null
          ? draft.speedLimitKph!.toString()
          : '',
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

  /// Loads the locally stored segment that matches the provided identifier.
  Future<SegmentDraft> loadDraft(String id) async {
    if (kIsWeb) {
      throw LocalSegmentsServiceException(
        AppMessages.loadingLocalSegmentsNotSupportedOnWeb,
      );
    }

    if (!id.startsWith(TollSegmentsCsvSchema.localSegmentIdPrefix)) {
      throw LocalSegmentsServiceException(
        AppMessages.onlySegmentsSavedLocallyCanBeShared,
      );
    }

    final csvPath = await resolveTollSegmentsDataPath(
      overrideResolver: _pathResolver,
    );

    if (!await _fileSystem.exists(csvPath)) {
      throw LocalSegmentsServiceException(
        AppMessages.segmentNotFoundLocally,
      );
    }

    final rows = await _readExistingRows(csvPath);
    if (rows.isEmpty) {
      throw LocalSegmentsServiceException(
        AppMessages.segmentNotFoundLocally,
      );
    }

    for (final row in rows) {
      if (_isHeaderRow(row)) {
        continue;
      }

      if (row.isEmpty || row.first != id) {
        continue;
      }

      final name = row.length > 1 ? row[1].trim() : '';
      final roadName = row.length > 2 ? row[2].trim() : '';
      final startDisplayName = row.length > 3 ? row[3].trim() : '';
      final endDisplayName = row.length > 4 ? row[4].trim() : '';
      final startCoordinates = row.length > 5 ? row[5].trim() : '';
      final endCoordinates = row.length > 6 ? row[6].trim() : '';
      final speedLimit = row.length > 7 ? row[7].trim() : '';
      final speedLimitKph =
          speedLimit.isEmpty ? null : double.tryParse(speedLimit);

      if (startCoordinates.isEmpty || endCoordinates.isEmpty) {
        throw LocalSegmentsServiceException(
          AppMessages.segmentMissingCoordinates,
        );
      }

      final resolvedName =
          name.isNotEmpty ? name : AppMessages.personalSegmentDefaultName;
      final resolvedStartDisplayName = startDisplayName.isNotEmpty
          ? startDisplayName
          : AppMessages.segmentDefaultStartName(resolvedName);
      final resolvedEndDisplayName = endDisplayName.isNotEmpty
          ? endDisplayName
          : AppMessages.segmentDefaultEndName(resolvedName);

      return SegmentDraft(
        name: resolvedName,
        roadName: roadName,
        startDisplayName: resolvedStartDisplayName,
        endDisplayName: resolvedEndDisplayName,
        startCoordinates: startCoordinates,
        endCoordinates: endCoordinates,
        isPublic: true,
        speedLimitKph: speedLimitKph,
      );
    }

    throw LocalSegmentsServiceException(
      AppMessages.segmentNotFoundLocally,
    );
  }

  Future<bool> deleteLocalSegment(String id) async {
    if (kIsWeb) {
      throw LocalSegmentsServiceException(
        AppMessages.deletingLocalSegmentsNotSupportedOnWeb,
      );
    }

    if (!id.startsWith(TollSegmentsCsvSchema.localSegmentIdPrefix)) {
      throw LocalSegmentsServiceException(
        AppMessages.onlyLocalSegmentsCanBeDeleted,
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
        .map(
          (row) => row.map((cell) => cell.toString()).toList(growable: false),
        )
        .toList(growable: true);
  }

  void _upgradeLegacyHeader(List<List<String>> rows) {
    if (rows.isEmpty) {
      return;
    }

    final expectedHeader = TollSegmentsCsvSchema.header;
    final headerRow =
        rows.first.map((cell) => cell.toString().trim()).toList(growable: false);
    final headerRowLower =
        headerRow.map((value) => value.toLowerCase()).toList(growable: false);

    bool matchesHeader(List<String> candidate) {
      if (candidate.length != headerRowLower.length) {
        return false;
      }
      for (var i = 0; i < candidate.length; i++) {
        if (candidate[i].toLowerCase() != headerRowLower[i]) {
          return false;
        }
      }
      return true;
    }

    void padToLength(List<String> row) {
      while (row.length < expectedHeader.length) {
        row.add('');
      }
    }

    const legacyWithoutName = <String>[
      'ID',
      'road',
      'Start name',
      'End name',
      'Start',
      'End',
    ];

    const headerWithoutSpeedLimit = <String>[
      'ID',
      'name',
      'road',
      'Start name',
      'End name',
      'Start',
      'End',
    ];

    if (matchesHeader(expectedHeader)) {
      rows[0] = expectedHeader;
      for (var i = 1; i < rows.length; i++) {
        final upgraded = List<String>.from(rows[i]);
        padToLength(upgraded);
        rows[i] = upgraded;
      }
      return;
    }

    if (matchesHeader(legacyWithoutName)) {
      rows[0] = expectedHeader;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final upgraded = <String>[];
        if (row.isNotEmpty) {
          upgraded.add(row[0]);
          upgraded.add('');
          upgraded.addAll(row.skip(1));
        }
        padToLength(upgraded);
        rows[i] = upgraded;
      }
      return;
    }

    if (matchesHeader(headerWithoutSpeedLimit)) {
      rows[0] = expectedHeader;
      for (var i = 1; i < rows.length; i++) {
        final upgraded = List<String>.from(rows[i])..add('');
        padToLength(upgraded);
        rows[i] = upgraded;
      }
      return;
    }

    if (headerRow.length < expectedHeader.length) {
      rows[0] = expectedHeader;
      for (var i = 1; i < rows.length; i++) {
        final upgraded = List<String>.from(rows[i]);
        padToLength(upgraded);
        rows[i] = upgraded;
      }
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

    try {
      await _metadataService.updatePublicFlag(id, isPublic);
    } on SegmentsMetadataException catch (error) {
      throw LocalSegmentsServiceException(error.message);
    }
  }

  String _normalizeCoordinates(String input) {
    final parts = input.split(',');
    if (parts.length < 2) {
      throw LocalSegmentsServiceException(
        AppMessages.coordinatesMustBeProvided,
      );
    }

    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    if (lat == null || lon == null) {
      throw LocalSegmentsServiceException(
        AppMessages.coordinatesMustBeDecimalNumbers,
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
    this.speedLimitKph,
  });

  final String name;
  final String roadName;
  final String startDisplayName;
  final String endDisplayName;
  final String startCoordinates;
  final String endCoordinates;
  final bool isPublic;
  final double? speedLimitKph;
}
