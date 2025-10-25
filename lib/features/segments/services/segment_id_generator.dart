import 'toll_segments_csv_constants.dart';

/// Generates unique identifiers for user-created segments that are stored locally.
class SegmentIdGenerator {
  SegmentIdGenerator._();

  /// Generates an identifier suitable for storing local-only segments.
  ///
  /// The identifier is derived from the highest numeric identifier present
  /// either in the locally stored custom segments or in the remote dataset and
  /// incremented by one. When neither source contains numeric identifiers the
  /// sequence starts at `1`.
  static String generateLocalId({
    required Iterable<String> existingLocalIds,
    required Iterable<String> remoteIds,
  }) {
    final prefix = TollSegmentsCsvSchema.localSegmentIdPrefix;
    final maxRemoteId = _highestNumericId(remoteIds);
    final maxLocalId = _highestNumericId(existingLocalIds.map(_stripLocalPrefix));
    final nextId = (maxRemoteId > maxLocalId ? maxRemoteId : maxLocalId) + 1;
    return '$prefix$nextId';
  }

  static String _stripLocalPrefix(String id) {
    final prefix = TollSegmentsCsvSchema.localSegmentIdPrefix;
    if (id.startsWith(prefix)) {
      return id.substring(prefix.length);
    }
    return id;
  }

  static int _highestNumericId(Iterable<String> ids) {
    var maxId = 0;
    for (final raw in ids) {
      final normalized = raw.trim();
      if (normalized.isEmpty) {
        continue;
      }

      final parsed = int.tryParse(normalized);
      if (parsed != null && parsed > maxId) {
        maxId = parsed;
      }
    }
    return maxId;
  }
}
