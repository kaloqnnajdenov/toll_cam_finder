/// Abstraction over simple file system operations required by the toll
/// segments sync service. Implementations are provided per-platform so the
/// service can remain platform-agnostic.
abstract class TollSegmentsFileSystem {
  const TollSegmentsFileSystem();

  Future<bool> exists(String path);

  Future<String> readAsString(String path);

  Future<void> writeAsString(String path, String data);

  Future<void> ensureParentDirectory(String path);
}

class TollSegmentsFileSystemException implements Exception {
  const TollSegmentsFileSystemException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'TollSegmentsFileSystemException: $message';
}