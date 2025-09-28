import 'dart:io' as io;

import 'toll_segments_file_system.dart';

class IoTollSegmentsFileSystem extends TollSegmentsFileSystem {
  const IoTollSegmentsFileSystem();

  @override
  Future<void> ensureParentDirectory(String path) async {
    final directory = io.File(path).parent;
    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
      } on io.FileSystemException catch (error) {
        throw TollSegmentsFileSystemException(error.message, error);
      }
    }
  }

  @override
  Future<bool> exists(String path) => io.File(path).exists();

  @override
  Future<String> readAsString(String path) async {
    try {
      return await io.File(path).readAsString();
    } on io.FileSystemException catch (error) {
      throw TollSegmentsFileSystemException(error.message, error);
    }
  }

  @override
  Future<void> writeAsString(String path, String data) async {
    try {
      await io.File(path).writeAsString(data, flush: true);
    } on io.FileSystemException catch (error) {
      throw TollSegmentsFileSystemException(error.message, error);
    }
  }
}

TollSegmentsFileSystem createFileSystem() => const IoTollSegmentsFileSystem();