import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:toll_cam_finder/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system_stub.dart'
    if (dart.library.io) 'package:toll_cam_finder/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/services/toll_segments_paths.dart';

class SegmentsMetadata {
  const SegmentsMetadata({
    Map<String, bool>? publicFlags,
    Set<String>? deactivatedSegmentIds,
  })  : publicFlags = Map.unmodifiable(publicFlags ?? const <String, bool>{}),
        deactivatedSegmentIds =
            Set.unmodifiable(deactivatedSegmentIds ?? const <String>{});

  final Map<String, bool> publicFlags;
  final Set<String> deactivatedSegmentIds;

  bool get isEmpty =>
      publicFlags.isEmpty && deactivatedSegmentIds.isEmpty;

  SegmentsMetadata copyWith({
    Map<String, bool>? publicFlags,
    Set<String>? deactivatedSegmentIds,
  }) {
    return SegmentsMetadata(
      publicFlags: publicFlags ?? this.publicFlags,
      deactivatedSegmentIds:
          deactivatedSegmentIds ?? this.deactivatedSegmentIds,
    );
  }

  SegmentsMetadata updatePublicFlag(String id, bool isPublic) {
    final updated = Map<String, bool>.of(publicFlags);
    if (isPublic) {
      updated[id] = true;
    } else {
      updated.remove(id);
    }
    return copyWith(publicFlags: updated);
  }

  SegmentsMetadata updateDeactivated(String id, bool isDeactivated) {
    final updated = Set<String>.of(deactivatedSegmentIds);
    if (isDeactivated) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    return copyWith(deactivatedSegmentIds: updated);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'publicFlags': publicFlags,
      'deactivatedSegments': deactivatedSegmentIds.toList()..sort(),
    };
  }

  factory SegmentsMetadata.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      if (json.containsKey('publicFlags') ||
          json.containsKey('deactivatedSegments')) {
        final dynamic flagsRaw = json['publicFlags'];
        final dynamic deactivatedRaw = json['deactivatedSegments'];

        final flags = <String, bool>{};
        if (flagsRaw is Map<String, dynamic>) {
          for (final entry in flagsRaw.entries) {
            flags[entry.key] = entry.value == true;
          }
        }

        final deactivated = <String>{};
        if (deactivatedRaw is List) {
          for (final value in deactivatedRaw) {
            if (value is String && value.isNotEmpty) {
              deactivated.add(value);
            }
          }
        }

        return SegmentsMetadata(
          publicFlags: flags,
          deactivatedSegmentIds: deactivated,
        );
      }

      // Legacy structure: map of id -> bool indicating public flag.
      final flags = <String, bool>{};
      for (final entry in json.entries) {
        flags[entry.key] = entry.value == true;
      }
      return SegmentsMetadata(publicFlags: flags);
    }

    return const SegmentsMetadata();
  }
}

class SegmentsMetadataService {
  SegmentsMetadataService({
    TollSegmentsFileSystem? fileSystem,
    TollSegmentsPathResolver? pathResolver,
  })  : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
        _pathResolver = pathResolver;

  final TollSegmentsFileSystem _fileSystem;
  final TollSegmentsPathResolver? _pathResolver;

  Future<SegmentsMetadata> load() async {
    if (kIsWeb) {
      return const SegmentsMetadata();
    }

    try {
      final path = await resolveTollSegmentsMetadataPath(
        overrideResolver: _pathResolver,
      );
      if (!await _fileSystem.exists(path)) {
        return const SegmentsMetadata();
      }

      final contents = await _fileSystem.readAsString(path);
      if (contents.trim().isEmpty) {
        return const SegmentsMetadata();
      }

      final dynamic decoded = jsonDecode(contents);
      return SegmentsMetadata.fromJson(decoded);
    } on TollSegmentsFileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SegmentsMetadataException(
          'Failed to access the segments metadata file.',
          cause: error,
        ),
        stackTrace,
      );
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SegmentsMetadataException(
          'Failed to parse the segments metadata file.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  Future<void> updatePublicFlag(String id, bool isPublic) async {
    if (kIsWeb) {
      throw const SegmentsMetadataException(
        'Segment metadata cannot be updated on the web.',
      );
    }

    await _updateMetadata(
      (metadata) => metadata.updatePublicFlag(id, isPublic),
    );
  }

  Future<void> setSegmentDeactivated(String id, bool isDeactivated) async {
    if (kIsWeb) {
      throw const SegmentsMetadataException(
        'Segment metadata cannot be updated on the web.',
      );
    }

    await _updateMetadata(
      (metadata) => metadata.updateDeactivated(id, isDeactivated),
    );
  }

  Future<void> _updateMetadata(
    SegmentsMetadata Function(SegmentsMetadata) transform,
  ) async {
    try {
      final path = await resolveTollSegmentsMetadataPath(
        overrideResolver: _pathResolver,
      );
      await _fileSystem.ensureParentDirectory(path);

      final current = await load();
      final updated = transform(current);

      if (updated.isEmpty) {
        await _fileSystem.writeAsString(path, '');
        return;
      }

      await _fileSystem.writeAsString(
        path,
        jsonEncode(updated.toJson()),
      );
    } on SegmentsMetadataException {
      rethrow;
    } on TollSegmentsFileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SegmentsMetadataException(
          'Failed to write to the segments metadata file.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }
}

class SegmentsMetadataException implements Exception {
  const SegmentsMetadataException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'SegmentsMetadataException: $message';
}
