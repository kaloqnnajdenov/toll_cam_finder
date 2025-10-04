import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:toll_cam_finder/services/toll_segments_csv_constants.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system_stub.dart'
    if (dart.library.io) 'package:toll_cam_finder/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/services/toll_segments_paths.dart';

class SegmentInfo {
  const SegmentInfo({
    required this.id,
    required this.name,
    required this.startDisplayName,
    required this.endDisplayName,
    required this.startCoordinates,
    required this.endCoordinates,
    this.isLocalOnly = false,
    this.isMarkedPublic = false,
  });

  final String id;
  final String name;
  final String startDisplayName;
  final String endDisplayName;
  final String startCoordinates;
  final String endCoordinates;
  final bool isLocalOnly;
  final bool isMarkedPublic;

  String get startLabel =>
      startDisplayName.isNotEmpty ? startDisplayName : startCoordinates;

  String get endLabel =>
      endDisplayName.isNotEmpty ? endDisplayName : endCoordinates;

  String get displayId {
    if (!isLocalOnly) {
      return id;
    }

    final prefix = TollSegmentsCsvSchema.localSegmentIdPrefix;
    if (id.startsWith(prefix)) {
      return id.substring(prefix.length);
    }
    return id;
  }
}

class SegmentsRepository {
  SegmentsRepository({TollSegmentsFileSystem? fileSystem})
      : _fileSystem = fileSystem ?? fs_impl.createFileSystem();

  final TollSegmentsFileSystem _fileSystem;

  Future<List<SegmentInfo>> loadSegments({
    String assetPath = kTollSegmentsAssetPath,
    bool onlyLocal = false,
  }) async {
    final raw = await _loadSegmentsData(assetPath);
    final rows = const CsvToListConverter(fieldDelimiter: ';').convert(raw);
    if (rows.isEmpty) {
      return const [];
    }

    final publicFlags = await _loadPublicFlags();

    final header = rows.first.map((cell) => '$cell'.trim().toLowerCase()).toList();
    final idIndex = header.indexOf('id');
    final nameIndex = _findColumn(header, const ['name', 'road']);
    final startNameIndex = header.indexOf('start name');
    final startCoordinatesIndex = header.indexOf('start');
    final endNameIndex = header.indexOf('end name');
    final endCoordinatesIndex = header.indexOf('end');

    if (idIndex == -1 ||
        nameIndex == -1 ||
        (startNameIndex == -1 && startCoordinatesIndex == -1) ||
        (endNameIndex == -1 && endCoordinatesIndex == -1)) {
      return const [];
    }

    final segments = <SegmentInfo>[];
    for (final row in rows.skip(1)) {
      if (row.length <= idIndex || row.length <= nameIndex) {
        continue;
      }

      if (startNameIndex != -1 && row.length <= startNameIndex) {
        continue;
      }

      if (startCoordinatesIndex != -1 && row.length <= startCoordinatesIndex) {
        continue;
      }

      if (endNameIndex != -1 && row.length <= endNameIndex) {
        continue;
      }

      if (endCoordinatesIndex != -1 && row.length <= endCoordinatesIndex) {
        continue;
      }

      final id = _stringAt(row, idIndex);
      final name = _stringAt(row, nameIndex);
      final startDisplayName = _stringAt(row, startNameIndex);
      final endDisplayName = _stringAt(row, endNameIndex);
      final startCoordinates = _stringAt(row, startCoordinatesIndex);
      final endCoordinates = _stringAt(row, endCoordinatesIndex);

      if (id.isEmpty &&
          name.isEmpty &&
          startDisplayName.isEmpty &&
          endDisplayName.isEmpty &&
          startCoordinates.isEmpty &&
          endCoordinates.isEmpty) {
        continue;
      }

      final isLocalOnly = id.startsWith(TollSegmentsCsvSchema.localSegmentIdPrefix);
      final resolvedName =
          name.isEmpty && isLocalOnly ? 'Personal segment' : name;

      segments.add(
        SegmentInfo(
          id: id,
          name: resolvedName,
          startDisplayName: startDisplayName,
          endDisplayName: endDisplayName,
          startCoordinates: startCoordinates,
          endCoordinates: endCoordinates,
          isLocalOnly: isLocalOnly,
          isMarkedPublic: publicFlags[id] ?? false,
        ),
      );
    }

    if (onlyLocal) {
      segments.retainWhere((segment) => segment.isLocalOnly);
    }

    segments.sort(_compareSegments);
    return segments;
  }

  int _compareSegments(SegmentInfo a, SegmentInfo b) {
    final idComparison = _compareDisplayIds(a.displayId, b.displayId);
    if (idComparison != 0) {
      return idComparison;
    }

    final nameComparison = a.name.compareTo(b.name);
    if (nameComparison != 0) {
      return nameComparison;
    }

    return a.id.compareTo(b.id);
  }

  int _compareDisplayIds(String a, String b) {
    final numericA = int.tryParse(a);
    final numericB = int.tryParse(b);

    if (numericA != null && numericB != null) {
      return numericA.compareTo(numericB);
    }

    if (numericA != null) {
      return -1;
    }

    if (numericB != null) {
      return 1;
    }

    return a.compareTo(b);
  }

  int _findColumn(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final index = header.indexOf(candidate.toLowerCase());
      if (index != -1) {
        return index;
      }
    }
    return -1;
  }

  String _stringAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    final value = row[index];
    if (value == null) {
      return '';
    }
    return '$value'.trim();
  }

  Future<String> _loadSegmentsData(String assetPath) async {
    if (!kIsWeb && assetPath == kTollSegmentsAssetPath) {
      try {
        final localPath = await resolveTollSegmentsDataPath();
        if (await _fileSystem.exists(localPath)) {
          return await _fileSystem.readAsString(localPath);
        }
      } catch (_) {
        // Fall back to bundled asset if local file access fails.
      }
    }

    return rootBundle.loadString(assetPath);
  }

  Future<Map<String, bool>> _loadPublicFlags() async {
    if (kIsWeb) {
      return const <String, bool>{};
    }

    try {
      final metadataPath = await resolveTollSegmentsMetadataPath();
      if (!await _fileSystem.exists(metadataPath)) {
        return const <String, bool>{};
      }

      final contents = await _fileSystem.readAsString(metadataPath);
      if (contents.trim().isEmpty) {
        return const <String, bool>{};
      }

      final dynamic decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) {
        return const <String, bool>{};
      }

      return decoded.map((key, value) => MapEntry(key, value == true));
    } catch (_) {
      return const <String, bool>{};
    }
  }
}

