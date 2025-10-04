import 'package:uuid/uuid.dart';

import 'toll_segments_csv_constants.dart';

/// Generates unique identifiers for user-created segments.
class SegmentIdGenerator {
  SegmentIdGenerator._();

  static const String _remotePrefix = 'REMOTE:';
  static const Uuid _uuid = Uuid();

  /// Generates an identifier suitable for storing local-only segments.
  static String generateLocalId() {
    return '${TollSegmentsCsvSchema.localSegmentIdPrefix}${_generateSuffix()}';
  }

  /// Generates an identifier suitable for submitting segments to the backend.
  static String generateRemoteId() {
    return '$_remotePrefix${_generateSuffix()}';
  }

  static String _generateSuffix() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
    final uniqueComponent = _uuid.v7().replaceAll('-', '');
    return '$timestamp-$uniqueComponent';
  }
}
