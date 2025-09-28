import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:toll_cam_finder/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system_stub.dart'
    if (dart.library.io) 'package:toll_cam_finder/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/services/toll_segments_paths.dart';

class SegmentInfo {
  const SegmentInfo({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
  });

  final String id;
  final String name;
  final String start;
  final String end;
}

class SegmentsRepository {
  SegmentsRepository({TollSegmentsFileSystem? fileSystem})
      : _fileSystem = fileSystem ?? fs_impl.createFileSystem();

  final TollSegmentsFileSystem _fileSystem;

  Future<List<SegmentInfo>> loadSegments({
    String assetPath = kTollSegmentsAssetPath,
  }) async {
    final raw = await _loadSegmentsData(assetPath);
    final rows = const CsvToListConverter(fieldDelimiter: ';').convert(raw);
    if (rows.isEmpty) {
      return const [];
    }

    final header = rows.first.map((cell) => '$cell'.trim().toLowerCase()).toList();
    final idIndex = header.indexOf('id');
    final nameIndex = _findColumn(header, const ['name', 'road']);
    final startIndex = _findColumn(header, const ['start name', 'start']);
    final endIndex = _findColumn(header, const ['end name', 'end']);

    if (idIndex == -1 || nameIndex == -1 || startIndex == -1 || endIndex == -1) {
      return const [];
    }

    final segments = <SegmentInfo>[];
    for (final row in rows.skip(1)) {
      if (row.length <= idIndex ||
          row.length <= nameIndex ||
          row.length <= startIndex ||
          row.length <= endIndex) {
        continue;
      }

      final id = _stringAt(row, idIndex);
      final name = _stringAt(row, nameIndex);
      final start = _stringAt(row, startIndex);
      final end = _stringAt(row, endIndex);

      if (id.isEmpty && name.isEmpty && start.isEmpty && end.isEmpty) {
        continue;
      }

      segments.add(
        SegmentInfo(
          id: id,
          name: name,
          start: start,
          end: end,
        ),
      );
    }

    segments.sort((a, b) => a.id.compareTo(b.id));
    return segments;
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