import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/services/segments_metadata_service.dart';
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
    this.speedLimitKph,
    this.isLocalOnly = false,
    this.isMarkedPublic = false,
    this.isDeactivated = false,
  });

  final String id;
  final String name;
  final String startDisplayName;
  final String endDisplayName;
  final String startCoordinates;
  final String endCoordinates;
  final String? speedLimitKph;
  final bool isLocalOnly;
  final bool isMarkedPublic;
  final bool isDeactivated;

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
  SegmentsRepository({
    TollSegmentsFileSystem? fileSystem,
    SegmentsMetadataService? metadataService,
  }) : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
       _metadataService =
           metadataService ?? SegmentsMetadataService(fileSystem: fileSystem);

  final TollSegmentsFileSystem _fileSystem;
  final SegmentsMetadataService _metadataService;

  Future<List<SegmentInfo>> loadSegments({
    String assetPath = kTollSegmentsAssetPath,
    bool onlyLocal = false,
  }) async {
    final raw = await _loadSegmentsData(assetPath);
    final rows = const CsvToListConverter(fieldDelimiter: ';').convert(raw);
    if (rows.isEmpty) {
      return const [];
    }

    SegmentsMetadata metadata;
    try {
      metadata = await _metadataService.load();
    } on SegmentsMetadataException {
      // If metadata cannot be loaded we still want to surface the segments.
      metadata = SegmentsMetadata();
    }
    final publicFlags = metadata.publicFlags;
    final deactivatedSegments = metadata.deactivatedSegmentIds;

    final header = rows.first
        .map((cell) => '$cell'.trim().toLowerCase())
        .toList();
    final idIndex = header.indexOf('id');
    final nameIndex = _findColumn(header, const ['name', 'road']);
    final startNameIndex = header.indexOf('start name');
    final startCoordinatesIndex = header.indexOf('start');
    final endNameIndex = header.indexOf('end name');
    final endCoordinatesIndex = header.indexOf('end');
    final speedLimitIndex = header.indexOf('speed_limit_kph');

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
      final speedLimit = _stringAt(row, speedLimitIndex);

      if (id.isEmpty &&
          name.isEmpty &&
          startDisplayName.isEmpty &&
          endDisplayName.isEmpty &&
          startCoordinates.isEmpty &&
          endCoordinates.isEmpty) {
        continue;
      }

      final isLocalOnly = id.startsWith(
        TollSegmentsCsvSchema.localSegmentIdPrefix,
      );
      final resolvedName = name.isEmpty && isLocalOnly
          ? AppMessages.personalSegmentDefaultName
          : name;

      segments.add(
        SegmentInfo(
          id: id,
          name: resolvedName,
          startDisplayName: startDisplayName,
          endDisplayName: endDisplayName,
          startCoordinates: startCoordinates,
          endCoordinates: endCoordinates,
          speedLimitKph: speedLimit.isEmpty ? null : speedLimit,
          isLocalOnly: isLocalOnly,
          isMarkedPublic: publicFlags[id] ?? false,
          isDeactivated: deactivatedSegments.contains(id),
        ),
      );
    }

    if (onlyLocal) {
      segments.retainWhere((segment) => segment.isLocalOnly);
       } else {
      // When a local segment is submitted for public review it should only be
      // surfaced in the dedicated "Local segments" view where it is labelled
      // with the "Review" badge. Showing the same entry alongside the
      // published network segments creates the impression that it is already
      // public. Hide such rows from the combined listing until they are
      // approved and synced back as real public entries.
      segments.removeWhere(
        (segment) => segment.isLocalOnly && segment.isMarkedPublic,
      );
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

}
