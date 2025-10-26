import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station_vote.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_csv_constants.dart';

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
    this.tableName = 'Weigh_Stations',
  });

  final String tableName;

  static const String _idColumn = 'id';
  static const String _upvotesColumn = 'upvotes';
  static const String _downvotesColumn = 'downvotes';

  Future<WeighStationVotesSnapshot> fetchVotes({
    required SupabaseClient client,
    String? currentUserId,
  }) async {
    try {
      final List<dynamic> response = await client
          .from(tableName)
          .select('$_idColumn,$_upvotesColumn,$_downvotesColumn');

      final votes = <String, WeighStationVotes>{};
      final userVotes = <String, bool>{};

      for (final dynamic entry in response) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final stationId = '${entry[_idColumn] ?? ''}'.trim();
        if (stationId.isEmpty) {
          continue;
        }
        final int upvotes = _parseCount(entry[_upvotesColumn]);
        final int downvotes = _parseCount(entry[_downvotesColumn]);

        votes[stationId] = WeighStationVotes(
          upvotes: upvotes,
          downvotes: downvotes,
        );
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
    required WeighStationVotes votes,
  }) async {
    try {
      final String normalizedId = stationId.trim();
      if (normalizedId.startsWith(
        WeighStationsCsvSchema.localWeighStationIdPrefix,
      )) {
        return;
      }
      final dynamic matchValue = int.tryParse(normalizedId) ?? normalizedId;
      await client
          .from(tableName)
          .update(<String, dynamic>{
            _upvotesColumn: votes.upvotes,
            _downvotesColumn: votes.downvotes,
          })
          .eq(_idColumn, matchValue);
    } on SocketException catch (error) {
      throw RemoteWeighStationVotesException(
        'Network error while updating weigh station votes.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      throw RemoteWeighStationVotesException(
        error.message,
        cause: error,
      );
    } catch (error, stackTrace) {
      throw RemoteWeighStationVotesException(
        'Unexpected error while updating weigh station votes.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  int _parseCount(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return 0;
      }
      return int.tryParse(normalized) ?? 0;
    }
    return 0;
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
