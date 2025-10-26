import 'package:toll_cam_finder/core/app_messages.dart';

import 'weigh_stations_file_system.dart';

class UnsupportedWeighStationsFileSystem extends WeighStationsFileSystem {
  const UnsupportedWeighStationsFileSystem();

  Future<T> _unsupported<T>() {
    throw WeighStationsFileSystemException(
      AppMessages.fileSystemOperationsNotSupported,
    );
  }

  @override
  Future<void> ensureParentDirectory(String path) => _unsupported();

  @override
  Future<bool> exists(String path) => _unsupported();

  @override
  Future<String> readAsString(String path) => _unsupported();

  @override
  Future<void> writeAsString(String path, String data) => _unsupported();
}

WeighStationsFileSystem createFileSystem() =>
    const UnsupportedWeighStationsFileSystem();
