import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_segments_service.dart';

/// Possible moderation statuses returned for a submitted segment.
enum SegmentSubmissionStatus { none, pending, approved, other }

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
  static const String _approvedStatus = 'approved';
  static const String _idColumn = 'id';
  static const int _smallIntMax = 32767;
  static const String _addedByUserColumn = 'added_by_user';
  static const String _nameColumn = 'name';
  static const String _roadColumn = 'road';
  static const String _startColumn = 'Start';
  static const String _endColumn = 'End';

  /// Uploads the supplied [draft] to Supabase, marking it as pending moderation.
  Future<void> submitForModeration(
    SegmentDraft draft, {
    required String addedByUserId,
  }) async {
    final client = _client;
    if (client == null) {
      throw const RemoteSegmentsServiceException(
        'Supabase is not configured. Unable to submit the segment for moderation.',
      );
    }

    if (addedByUserId.trim().isEmpty) {
      throw const RemoteSegmentsServiceException(
        'A logged in user is required to submit a public segment for moderation.',
      );
    }

    final pendingId = await _computeNextRemoteId(client);

    try {
      await client.from(tableName).insert(<String, dynamic>{
        'id': pendingId,
        _nameColumn: draft.name,
        _roadColumn: draft.roadName,
        'Start name': draft.startDisplayName,
        'End name': draft.endDisplayName,
        'Start': draft.startCoordinates,
        'End': draft.endCoordinates,
        'speed_limit_kph': draft.speedLimitKph,
        _moderationStatusColumn: _pendingStatus,
        _addedByUserColumn: addedByUserId,
      });
    } on SocketException catch (error) {
      throw RemoteSegmentsServiceException(
        'No internet connection. Unable to submit the segment for moderation.',
        cause: error,
      );
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

  /// Returns whether there is a pending moderation request for the provided
  /// segment created by the supplied user.
  Future<bool> hasPendingSubmission({
    required String addedByUserId,
    required String name,
    required String startCoordinates,
    required String endCoordinates,
  }) async {
    final client = _client;
    if (client == null) {
      throw const RemoteSegmentsServiceException(
        'Supabase is not configured. Unable to manage public submissions.',
      );
    }

    try {
      final List<dynamic> rows = await client
          .from(tableName)
          .select('$_idColumn')
          .match(<String, Object>{
        _moderationStatusColumn: _pendingStatus,
        _addedByUserColumn: addedByUserId,
        _nameColumn: name,
        _startColumn: startCoordinates,
        _endColumn: endCoordinates,
      }).limit(1);

      return rows.isNotEmpty;
    } on SocketException catch (error) {
      throw RemoteSegmentsServiceException(
        'No internet connection. Unable to manage public submissions.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteSegmentsServiceException(
        'Failed to check the public submission status: ${error.message}',
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteSegmentsServiceException(
        'Unexpected error while checking the public submission status.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes the moderation request that matches the provided segment for the
  /// supplied user, regardless of the current moderation status. Returns
  /// `true` if a submission was deleted.
  Future<bool> deleteSubmission({
    required String addedByUserId,
    required String name,
    required String startCoordinates,
    required String endCoordinates,
  }) async {
    final client = _client;
    if (client == null) {
      throw const RemoteSegmentsServiceException(
        'Supabase is not configured. Unable to manage public submissions.',
      );
    }

    try {
      final List<dynamic> deleted = await client
          .from(tableName)
          .delete()
          .match(<String, Object>{
        _addedByUserColumn: addedByUserId,
        _nameColumn: name,
        _startColumn: startCoordinates,
        _endColumn: endCoordinates,
      }).select('$_idColumn');

      return deleted.isNotEmpty;
    } on SocketException catch (error) {
      throw RemoteSegmentsServiceException(
        'No internet connection. Unable to manage public submissions.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteSegmentsServiceException(
        'Failed to cancel the public submission: ${error.message}',
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteSegmentsServiceException(
        'Unexpected error while cancelling the public submission.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches the moderation status for the provided submission.
  Future<SegmentSubmissionStatus> getSubmissionStatus({
    required String addedByUserId,
    required String name,
    required String startCoordinates,
    required String endCoordinates,
  }) async {
    final client = _client;
    if (client == null) {
      throw const RemoteSegmentsServiceException(
        'Supabase is not configured. Unable to manage public submissions.',
      );
    }

    try {
      final List<dynamic> rows = await client
          .from(tableName)
          .select('$_moderationStatusColumn')
          .match(<String, Object>{
        _addedByUserColumn: addedByUserId,
        _nameColumn: name,
        _startColumn: startCoordinates,
        _endColumn: endCoordinates,
      }).limit(1);

      if (rows.isEmpty) {
        return SegmentSubmissionStatus.none;
      }

      final rawStatus =
          (rows.first as Map<String, dynamic>)[_moderationStatusColumn];
      if (rawStatus is String) {
        final normalized = rawStatus.toLowerCase();
        if (normalized == _approvedStatus) {
          return SegmentSubmissionStatus.approved;
        }
        if (normalized == _pendingStatus) {
          return SegmentSubmissionStatus.pending;
        }
      }

      return SegmentSubmissionStatus.other;
    } on SocketException catch (error) {
      throw RemoteSegmentsServiceException(
        'No internet connection. Unable to manage public submissions.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteSegmentsServiceException(
        'Failed to check the public submission status: ${error.message}',
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteSegmentsServiceException(
        'Unexpected error while checking the public submission status.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> _computeNextRemoteId(SupabaseClient client) async {
    final List<dynamic> rows = await client
        .from(tableName)
        .select('$_idColumn')
        .inFilter(_moderationStatusColumn, const <String>[_pendingStatus, _approvedStatus])
        .order(_idColumn, ascending: false)
        .limit(1);

    final maxId = rows.isEmpty
        ? null
        : _parseId((rows.first as Map<String, dynamic>)[_idColumn]);
    final nextId = (maxId ?? 0) + 1;

    if (nextId > _smallIntMax) {
      throw const RemoteSegmentsServiceException(
        'Unable to assign a new segment id: all smallint values are exhausted.',
      );
    }

    return nextId;
  }

  int _parseId(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    throw const RemoteSegmentsServiceException(
      'Encountered an existing segment with a non-numeric id.',
    );
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
