import 'package:toll_cam_finder/core/app_messages.dart';

import 'toll_segments_file_system.dart';

class UnsupportedTollSegmentsFileSystem extends TollSegmentsFileSystem {
  const UnsupportedTollSegmentsFileSystem();

  Future<T> _unsupported<T>() {
    throw TollSegmentsFileSystemException(
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

TollSegmentsFileSystem createFileSystem() => const UnsupportedTollSegmentsFileSystem();