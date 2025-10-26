abstract class WeighStationsFileSystem {
  const WeighStationsFileSystem();

  Future<bool> exists(String path);

  Future<String> readAsString(String path);

  Future<void> writeAsString(String path, String data);

  Future<void> ensureParentDirectory(String path);
}

class WeighStationsFileSystemException implements Exception {
  const WeighStationsFileSystemException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'WeighStationsFileSystemException: $message';
}
