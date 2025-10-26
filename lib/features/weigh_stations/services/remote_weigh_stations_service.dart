import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/core/app_messages.dart';

import 'weigh_stations_csv_constants.dart';

class RemoteWeighStationsService {
  RemoteWeighStationsService({
    SupabaseClient? client,
    this.tableName = 'Weigh_Stations',
  }) : _client = client;

  final SupabaseClient? _client;
  final String tableName;

  static const String _moderationStatusColumn = 'moderation_status';
  static const String _pendingStatus = 'pending';
  static const String _approvedStatus = 'approved';
  static const String _addedByUserColumn = 'added_by_user';
  static const String _coordinatesColumn = 'coordinates';
  static const String _nameColumn = 'name';
  static const String _roadColumn = 'road';
  static const String _idColumn = 'id';
  static const int _smallIntMax = 32767;

  Future<void> submitForModeration({
    required String name,
    required String road,
    required String coordinates,
    required String addedByUserId,
  }) async {
    final client = _client;
    if (client == null) {
      throw RemoteWeighStationsServiceException(
        AppMessages.supabaseNotConfiguredForModeration,
      );
    }

    if (addedByUserId.trim().isEmpty) {
      throw RemoteWeighStationsServiceException(
        AppMessages.userRequiredForPublicModeration,
      );
    }

    var pendingId = await _computeNextRemoteId(client);

    try {
      while (true) {
        try {
          await client.from(tableName).insert(<String, dynamic>{
            'id': pendingId,
            _nameColumn: name,
            _roadColumn: road,
            _coordinatesColumn: coordinates,
            _moderationStatusColumn: _pendingStatus,
            _addedByUserColumn: addedByUserId,
          });
          break;
        } on PostgrestException catch (error) {
          if (_isIdConflict(error)) {
            pendingId += 1;
            if (pendingId > _smallIntMax) {
              throw RemoteWeighStationsServiceException(
                AppMessages.unableToAssignNewSegmentId,
                cause: error,
              );
            }
            continue;
          }
          rethrow;
        }
      }
    } on SocketException catch (error) {
      throw RemoteWeighStationsServiceException(
        AppMessages.noConnectionUnableToSubmitForModeration,
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteWeighStationsServiceException(
        AppMessages.failedToSubmitSegmentForModerationWithReason(
          error.message,
        ),
        cause: error,
      );
    } catch (error, stackTrace) {
      if (error is RemoteWeighStationsServiceException) {
        rethrow;
      }
      throw RemoteWeighStationsServiceException(
        AppMessages.unexpectedErrorSubmittingForModeration,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> hasPendingSubmission({
    required String addedByUserId,
    required String name,
    required String coordinates,
  }) async {
    final client = _client;
    if (client == null) {
      throw RemoteWeighStationsServiceException(
        AppMessages.supabaseNotConfiguredForPublicSubmissions,
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
        _coordinatesColumn: coordinates,
      }).limit(1);

      return rows.isNotEmpty;
    } on SocketException catch (error) {
      throw RemoteWeighStationsServiceException(
        AppMessages.noConnectionUnableToManageSubmissions,
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteWeighStationsServiceException(
        AppMessages.failedToCheckSubmissionStatusWithReason(error.message),
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteWeighStationsServiceException(
        AppMessages.unexpectedErrorCheckingSubmissionStatus,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> deleteSubmission({
    required String addedByUserId,
    required String name,
    required String coordinates,
  }) async {
    final client = _client;
    if (client == null) {
      throw RemoteWeighStationsServiceException(
        AppMessages.supabaseNotConfiguredForPublicSubmissions,
      );
    }

    try {
      final List<dynamic> deleted = await client
          .from(tableName)
          .delete()
          .match(<String, Object>{
        _addedByUserColumn: addedByUserId,
        _nameColumn: name,
        _coordinatesColumn: coordinates,
      }).select('$_idColumn');

      return deleted.isNotEmpty;
    } on SocketException catch (error) {
      throw RemoteWeighStationsServiceException(
        AppMessages.noConnectionUnableToManageSubmissions,
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteWeighStationsServiceException(
        AppMessages.failedToCancelSubmissionWithReason(error.message),
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteWeighStationsServiceException(
        AppMessages.unexpectedErrorCancellingSubmission,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> _computeNextRemoteId(SupabaseClient client) async {
    try {
      final List<dynamic> rows = await client
          .from(tableName)
          .select('$_idColumn')
          .order(_idColumn, ascending: false)
          .limit(1);
      if (rows.isEmpty) {
        return 1;
      }
      final dynamic value = rows.first[_idColumn];
      if (value is int) {
        return value + 1;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed + 1;
        }
      }
      throw const RemoteWeighStationsServiceException(
        'Unable to determine next weigh station id.',
      );
    } on PostgrestException catch (error) {
      if (_isMissingColumnError(error, _idColumn)) {
        throw RemoteWeighStationsServiceException(
          AppMessages.missingRequiredColumn(_idColumn),
          cause: error,
        );
      }
      rethrow;
    }
  }

  bool _isIdConflict(PostgrestException error) {
    final code = error.code?.toUpperCase();
    if (code == '23505') {
      return true;
    }
    final message = error.message.toLowerCase();
    return message.contains('duplicate key value') ||
        message.contains('unique constraint');
  }

  bool _isMissingColumnError(PostgrestException error, String column) {
    final code = error.code?.toUpperCase();
    if (code == '42703') {
      return true;
    }
    final normalizedMessage = error.message.toLowerCase();
    return normalizedMessage.contains('column') &&
        normalizedMessage.contains(column.toLowerCase());
  }
}

class RemoteWeighStationsServiceException implements Exception {
  const RemoteWeighStationsServiceException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'RemoteWeighStationsServiceException: $message';
}
