import 'package:uuid/uuid.dart';

import 'toll_segments_csv_constants.dart';

/// Generates unique identifiers for user-created segments that are stored locally.
class SegmentIdGenerator {
  SegmentIdGenerator._();

  static const Uuid _uuid = Uuid();

  /// Generates an identifier suitable for storing local-only segments.
  static String generateLocalId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
    final uniqueComponent = _uuid.v7().replaceAll('-', '');
    return '${TollSegmentsCsvSchema.localSegmentIdPrefix}$timestamp-$uniqueComponent';
  }
}
