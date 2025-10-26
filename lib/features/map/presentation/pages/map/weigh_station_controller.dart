import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station_vote.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_repository.dart';

class WeighStationMarker {
  const WeighStationMarker({
    required this.id,
    required this.position,
  });

  final String id;
  final LatLng position;
}

class WeighStationsState {
  const WeighStationsState({
    required this.error,
    required this.isLoading,
    required this.visibleStations,
    required this.votes,
    required this.userVotes,
  });

  final String? error;
  final bool isLoading;
  final List<WeighStationMarker> visibleStations;
  final Map<String, WeighStationVotes> votes;
  final Map<String, bool> userVotes;
}

class NearestWeighStation {
  const NearestWeighStation({
    required this.marker,
    required this.distanceMeters,
  });

  final WeighStationMarker marker;
  final double distanceMeters;
}

class WeighStationController {
  WeighStationController({WeighStationsRepository? repository})
      : _repository = repository ?? WeighStationsRepository();

  final WeighStationsRepository _repository;

  final Distance _distance = const Distance();
  List<WeighStationMarker> _allStations = const [];
  List<WeighStationMarker> _visibleStations = const [];
  final Map<String, WeighStationVotes> _votes = <String, WeighStationVotes>{};
  final Map<String, bool> _userVotes = <String, bool>{};
  String? _error;
  bool _isLoading = false;

  WeighStationsState get state => WeighStationsState(
        error: _error,
        isLoading: _isLoading,
        visibleStations: _visibleStations,
        votes: Map.unmodifiable(_votes),
        userVotes: Map.unmodifiable(_userVotes),
      );

  Future<void> loadFromAsset(
    String assetPath, {
    LatLngBounds? bounds,
  }) async {
    _isLoading = true;
    _error = null;
    try {
      final stations = await _repository.loadStations(assetPath: assetPath);

      final markers = <WeighStationMarker>[];
      final votesByStation = <String, WeighStationVotes>{};

      for (final station in stations) {
        final position = _parseCoordinates(station.coordinates);
        if (position == null) {
          continue;
        }
        markers.add(WeighStationMarker(id: station.id, position: position));
        votesByStation[station.id] = WeighStationVotes(
          upvotes: station.upvotes,
          downvotes: station.downvotes,
        );
      }

      _allStations = markers;
      _votes
        ..clear()
        ..addAll(votesByStation);
      _syncVotesWithStations();
      updateVisible(bounds: bounds);
    } catch (error, stackTrace) {
      debugPrint('WeighStationController: failed to load stations: $error\n$stackTrace');
      _error = error.toString();
      _allStations = const [];
      _visibleStations = const [];
      _votes.clear();
      _userVotes.clear();
    } finally {
      _isLoading = false;
    }
  }

  void updateVisible({LatLngBounds? bounds}) {
    if (bounds == null) {
      _visibleStations = _allStations;
      return;
    }

    _visibleStations = _allStations
        .where((station) => bounds.contains(station.position))
        .toList(growable: false);
  }

  NearestWeighStation? nearestStation(LatLng point) {
    if (_allStations.isEmpty) {
      return null;
    }
    NearestWeighStation? nearest;
    for (final station in _allStations) {
      final distanceMeters =
          _distance.as(LengthUnit.Meter, station.position, point);
      if (nearest == null || distanceMeters < nearest.distanceMeters) {
        nearest = NearestWeighStation(
          marker: station,
          distanceMeters: distanceMeters,
        );
      }
    }
    return nearest;
  }

  WeighStationVoteResult registerVote({
    required String stationId,
    required bool isUpvote,
  }) {
    final WeighStationVotes currentVotes =
        _votes[stationId] ?? const WeighStationVotes();
    final bool? existingVote = _userVotes[stationId];

    WeighStationVotes updatedVotes = currentVotes;
    bool? updatedUserVote = existingVote;

    if (existingVote == null) {
      updatedVotes = isUpvote
          ? currentVotes.copyWith(upvotes: currentVotes.upvotes + 1)
          : currentVotes.copyWith(downvotes: currentVotes.downvotes + 1);
      _userVotes[stationId] = isUpvote;
      updatedUserVote = isUpvote;
    } else if (existingVote == isUpvote) {
      if (isUpvote) {
        final int newUpvotes =
            currentVotes.upvotes > 0 ? currentVotes.upvotes - 1 : 0;
        updatedVotes = currentVotes.copyWith(upvotes: newUpvotes);
      } else {
        final int newDownvotes =
            currentVotes.downvotes > 0 ? currentVotes.downvotes - 1 : 0;
        updatedVotes = currentVotes.copyWith(downvotes: newDownvotes);
      }
      _userVotes.remove(stationId);
      updatedUserVote = null;
    } else {
      if (isUpvote) {
        final int newDownvotes =
            currentVotes.downvotes > 0 ? currentVotes.downvotes - 1 : 0;
        updatedVotes = currentVotes.copyWith(
          upvotes: currentVotes.upvotes + 1,
          downvotes: newDownvotes,
        );
      } else {
        final int newUpvotes =
            currentVotes.upvotes > 0 ? currentVotes.upvotes - 1 : 0;
        updatedVotes = currentVotes.copyWith(
          upvotes: newUpvotes,
          downvotes: currentVotes.downvotes + 1,
        );
      }
      _userVotes[stationId] = isUpvote;
      updatedUserVote = isUpvote;
    }

    _votes[stationId] = updatedVotes;

    return WeighStationVoteResult(
      votes: updatedVotes,
      userVote: updatedUserVote,
    );
  }

  void applyRemoteVotes({
    required Map<String, WeighStationVotes> votes,
    required Map<String, bool> userVotes,
  }) {
    _votes
      ..clear()
      ..addAll(votes);
    _userVotes
      ..clear()
      ..addAll(userVotes);
    _syncVotesWithStations();
  }

  void _syncVotesWithStations() {
    final Map<String, WeighStationVotes> synchronizedVotes =
        <String, WeighStationVotes>{};
    final Map<String, bool> synchronizedUserVotes = <String, bool>{};
    for (final station in _allStations) {
      synchronizedVotes[station.id] =
          _votes[station.id] ?? const WeighStationVotes();
      final bool? existingVote = _userVotes[station.id];
      if (existingVote != null) {
        synchronizedUserVotes[station.id] = existingVote;
      }
    }
    _votes
      ..clear()
      ..addAll(synchronizedVotes);
    _userVotes
      ..clear()
      ..addAll(synchronizedUserVotes);
  }

  LatLng? _parseCoordinates(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) {
      return null;
    }
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) {
      return null;
    }
    if (!lat.isFinite || !lng.isFinite) {
      return null;
    }
    return LatLng(lat, lng);
  }
}
