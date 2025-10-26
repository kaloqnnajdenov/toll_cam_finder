import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_repository.dart';

class WeighStationMarker {
  const WeighStationMarker({
    required this.id,
    required this.position,
  });

  final String id;
  final LatLng position;
}

class WeighStationVotes {
  const WeighStationVotes({
    this.upvotes = 0,
    this.downvotes = 0,
  });

  final int upvotes;
  final int downvotes;

  WeighStationVotes copyWith({int? upvotes, int? downvotes}) {
    return WeighStationVotes(
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
    );
  }
}

class WeighStationsState {
  const WeighStationsState({
    required this.error,
    required this.isLoading,
    required this.visibleStations,
    required this.votes,
  });

  final String? error;
  final bool isLoading;
  final List<WeighStationMarker> visibleStations;
  final Map<String, WeighStationVotes> votes;
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
  String? _error;
  bool _isLoading = false;

  WeighStationsState get state => WeighStationsState(
        error: _error,
        isLoading: _isLoading,
        visibleStations: _visibleStations,
        votes: Map.unmodifiable(_votes),
      );

  Future<void> loadFromAsset(
    String assetPath, {
    LatLngBounds? bounds,
  }) async {
    _isLoading = true;
    _error = null;
    try {
      final stations = await _repository.loadStations(assetPath: assetPath);
      _allStations = stations
          .map((station) {
            final position = _parseCoordinates(station.coordinates);
            if (position == null) {
              return null;
            }
            return WeighStationMarker(id: station.id, position: position);
          })
          .whereType<WeighStationMarker>()
          .toList(growable: false);
      _syncVotesWithStations();
      updateVisible(bounds: bounds);
    } catch (error, stackTrace) {
      debugPrint('WeighStationController: failed to load stations: $error\n$stackTrace');
      _error = error.toString();
      _allStations = const [];
      _visibleStations = const [];
      _votes.clear();
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

  WeighStationVotes registerVote({
    required String stationId,
    required bool isUpvote,
  }) {
    final WeighStationVotes current =
        _votes[stationId] ?? const WeighStationVotes();
    final WeighStationVotes updated = isUpvote
        ? current.copyWith(upvotes: current.upvotes + 1)
        : current.copyWith(downvotes: current.downvotes + 1);
    _votes[stationId] = updated;
    return updated;
  }

  void _syncVotesWithStations() {
    final Map<String, WeighStationVotes> synchronized =
        <String, WeighStationVotes>{};
    for (final station in _allStations) {
      synchronized[station.id] = _votes[station.id] ?? const WeighStationVotes();
    }
    _votes
      ..clear()
      ..addAll(synchronized);
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
