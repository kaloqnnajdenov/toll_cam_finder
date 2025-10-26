import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station_vote.dart';

class WeighStationVotesSnapshot {
  const WeighStationVotesSnapshot({
    required this.votes,
    required this.userVotes,
  });

  final Map<String, WeighStationVotes> votes;
  final Map<String, bool> userVotes;
}

class RemoteWeighStationVotesService {
  RemoteWeighStationVotesService({
    this.tableName = 'Weigh_Station_Votes',
  });

  final String tableName;

  static const String _stationIdColumn = 'station_id';
  static const String _userIdColumn = 'user_id';
  static const String _isUpvoteColumn = 'is_upvote';

  Future<WeighStationVotesSnapshot> fetchVotes({
    required SupabaseClient client,
    String? currentUserId,
  }) async {
    try {
      final List<dynamic> response = await client
          .from(tableName)
          .select('$_stationIdColumn,$_userIdColumn,$_is_upvoteColumn');

      final votes = <String, WeighStationVotes>{};
      final userVotes = <String, bool>{};

      for (final dynamic entry in response) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final stationId = '${entry[_stationIdColumn] ?? ''}'.trim();
        if (stationId.isEmpty) {
          continue;
        }
        final bool? isUpvote = _parseVote(entry[_isUpvoteColumn]);
        if (isUpvote == null) {
          continue;
        }

        final existing = votes[stationId] ?? const WeighStationVotes();
        votes[stationId] = isUpvote
            ? existing.copyWith(upvotes: existing.upvotes + 1)
            : existing.copyWith(downvotes: existing.downvotes + 1);

        final userId = entry[_userIdColumn]?.toString();
        if (currentUserId != null && currentUserId == userId) {
          userVotes[stationId] = isUpvote;
        }
      }

      return WeighStationVotesSnapshot(votes: votes, userVotes: userVotes);
    } on SocketException catch (error) {
      throw RemoteWeighStationVotesException(
        'Network error while loading weigh station votes.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteWeighStationVotesException(
        error.message,
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteWeighStationVotesException(
        'Unexpected error while loading weigh station votes.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> applyVote({
    required SupabaseClient client,
    required String stationId,
    required String userId,
    required bool? vote,
  }) async {
    try {
      if (vote == null) {
        await client
            .from(tableName)
            .delete()
            .match(<String, String>{
          _stationIdColumn: stationId,
          _userIdColumn: userId,
        });
        return;
      }

      await client.from(tableName).upsert(
        <String, dynamic>{
          _stationIdColumn: stationId,
          _userIdColumn: userId,
          _isUpvoteColumn: vote,
        },
        onConflict: '$_stationIdColumn,$_userIdColumn',
      );
    } on SocketException catch (error) {
      throw RemoteWeighStationVotesException(
        'Network error while submitting weigh station vote.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteWeighStationVotesException(
        error.message,
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteWeighStationVotesException(
        'Unexpected error while submitting weigh station vote.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool? _parseVote(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        return null;
      }
      if (normalized == 'true' || normalized == 't' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'f' || normalized == '0') {
        return false;
      }
    }
    return null;
  }
}

class RemoteWeighStationVotesException implements Exception {
  const RemoteWeighStationVotesException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'RemoteWeighStationVotesException: $message';
}
