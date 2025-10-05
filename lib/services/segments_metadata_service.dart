import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:toll_cam_finder/services/toll_segments_file_system.dart';
import 'package:toll_cam_finder/services/toll_segments_file_system_stub.dart'
    if (dart.library.io) 'package:toll_cam_finder/services/toll_segments_file_system_io.dart'
    as fs_impl;
import 'package:toll_cam_finder/services/toll_segments_paths.dart';

class SegmentsMetadata {
  SegmentsMetadata({
    Map<String, bool>? publicFlags,
    Set<String>? deactivatedPublicSegmentIds,
  })  : publicFlags = Map<String, bool>.from(publicFlags ?? const {}),
        deactivatedPublicSegmentIds =
            Set<String>.from(deactivatedPublicSegmentIds ?? const {});

  final Map<String, bool> publicFlags;
  final Set<String> deactivatedPublicSegmentIds;

  bool get isEmpty =>
      publicFlags.isEmpty && deactivatedPublicSegmentIds.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (publicFlags.isNotEmpty) 'publicFlags': publicFlags,
      if (deactivatedPublicSegmentIds.isNotEmpty)
        'deactivatedPublicSegments': deactivatedPublicSegmentIds.toList(),
    };
  }

  static SegmentsMetadata fromDynamic(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return SegmentsMetadata();
    }

    if (data.containsKey('publicFlags') ||
        data.containsKey('deactivatedPublicSegments') ||
        data.containsKey('deactivatedSegments')) {
      final publicFlags = <String, bool>{};
      final rawPublicFlags = data['publicFlags'];
      if (rawPublicFlags is Map) {
        rawPublicFlags.forEach((key, value) {
          final id = key?.toString() ?? '';
          if (id.isEmpty) return;
          publicFlags[id] = value == true;
        });
      }

      final deactivated = <String>{};
      final rawDeactivated =
          data['deactivatedPublicSegments'] ?? data['deactivatedSegments'];
      if (rawDeactivated is List) {
        for (final entry in rawDeactivated) {
          final id = entry?.toString().trim();
          if (id != null && id.isNotEmpty) {
            deactivated.add(id);
          }
        }
      }

      return SegmentsMetadata(
        publicFlags: publicFlags,
        deactivatedPublicSegmentIds: deactivated,
      );
    }

    final legacyFlags = <String, bool>{};
    var legacyFormat = true;
    data.forEach((key, value) {
      if (value is bool) {
        legacyFlags[key] = value;
      } else if (value == null) {
        // Ignore null entries.
      } else {
        legacyFormat = false;
      }
    });

    if (!legacyFormat) {
      return SegmentsMetadata();
    }

    return SegmentsMetadata(publicFlags: legacyFlags);
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
      return SegmentsMetadata();
    }

    final path = await resolveTollSegmentsMetadataPath(
      overrideResolver: _pathResolver,
    );

    if (!await _fileSystem.exists(path)) {
      return SegmentsMetadata();
    }

    final contents = await _fileSystem.readAsString(path);
    if (contents.trim().isEmpty) {
      return SegmentsMetadata();
    }

    try {
      final dynamic decoded = jsonDecode(contents);
      return SegmentsMetadata.fromDynamic(decoded);
    } catch (_) {
      return SegmentsMetadata();
    }
  }

  Future<void> save(SegmentsMetadata metadata) async {
    if (kIsWeb) {
      return;
    }

    final path = await resolveTollSegmentsMetadataPath(
      overrideResolver: _pathResolver,
    );
    await _fileSystem.ensureParentDirectory(path);

    if (metadata.isEmpty) {
      await _fileSystem.writeAsString(path, '');
      return;
    }

    await _fileSystem.writeAsString(path, jsonEncode(metadata.toJson()));
  }

  Future<void> setPublicFlag(String id, bool isPublic) async {
    if (kIsWeb) {
      return;
    }

    final metadata = await load();
    if (isPublic) {
      metadata.publicFlags[id] = true;
    } else {
      metadata.publicFlags.remove(id);
    }

    await save(metadata);
  }

  Future<void> setSegmentActivation(String id, bool isActive) async {
    if (kIsWeb) {
      return;
    }

    final metadata = await load();
    if (isActive) {
      metadata.deactivatedPublicSegmentIds.remove(id);
    } else {
      metadata.deactivatedPublicSegmentIds.add(id);
    }

    await save(metadata);
  }
}
