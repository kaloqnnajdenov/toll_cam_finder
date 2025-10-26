import 'dart:io';

import 'weigh_stations_file_system.dart';

class IoWeighStationsFileSystem extends WeighStationsFileSystem {
  const IoWeighStationsFileSystem();

  @override
  Future<void> ensureParentDirectory(String path) async {
    final directory = Directory(path).parent;
    if (await directory.exists()) {
      return;
    }
    await directory.create(recursive: true);
  }

  @override
  Future<bool> exists(String path) async {
    return File(path).exists();
  }

  @override
  Future<String> readAsString(String path) async {
    try {
      return await File(path).readAsString();
    } on FileSystemException catch (error) {
      throw WeighStationsFileSystemException(error.message, error);
    }
  }

  @override
  Future<void> writeAsString(String path, String data) async {
    try {
      await File(path).writeAsString(data);
    } on FileSystemException catch (error) {
      throw WeighStationsFileSystemException(error.message, error);
    }
  }
}

WeighStationsFileSystem createFileSystem() => const IoWeighStationsFileSystem();
