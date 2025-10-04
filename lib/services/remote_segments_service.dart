import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_segments_service.dart';
import 'segment_id_generator.dart';

/// Handles submitting user-created segments to Supabase for moderation.
class RemoteSegmentsService {
  RemoteSegmentsService({
    SupabaseClient? client,
    this.tableName = 'Toll_Segments',
  }) : _client = client;

  final SupabaseClient? _client;
  final String tableName;

  static const String _moderationStatusColumn = 'moderation_status';
  static const String _pendingStatus = 'pending';

  /// Uploads the supplied [draft] to Supabase, marking it as pending moderation.
  Future<void> submitForModeration(SegmentDraft draft) async {
    final client = _client;
    if (client == null) {
      throw const RemoteSegmentsServiceException(
        'Supabase is not configured. Unable to submit the segment for moderation.',
      );
    }

    final pendingId = SegmentIdGenerator.generateRemoteId();

    try {
      await client.from(tableName).insert(<String, dynamic>{
        'id': pendingId,
        'road': draft.name,
        'Start name': draft.startDisplayName,
        'End name': draft.endDisplayName,
        'Start': draft.startCoordinates,
        'End': draft.endCoordinates,
        _moderationStatusColumn: _pendingStatus,
      });
    } on PostgrestException catch (error) {
      throw RemoteSegmentsServiceException(
        'Failed to submit the segment for moderation: ${error.message}',
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteSegmentsServiceException(
        'Unexpected error while submitting the segment for moderation.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Error raised when submitting a segment for moderation fails.
class RemoteSegmentsServiceException implements Exception {
  const RemoteSegmentsServiceException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'RemoteSegmentsServiceException: $message';
}
