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

class WeighStationsState {
  const WeighStationsState({
    required this.error,
    required this.isLoading,
    required this.visibleStations,
  });

  final String? error;
  final bool isLoading;
  final List<WeighStationMarker> visibleStations;
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
  String? _error;
  bool _isLoading = false;

  WeighStationsState get state => WeighStationsState(
        error: _error,
        isLoading: _isLoading,
        visibleStations: _visibleStations,
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
      updateVisible(bounds: bounds);
    } catch (error, stackTrace) {
      debugPrint('WeighStationController: failed to load stations: $error\n$stackTrace');
      _error = error.toString();
      _allStations = const [];
      _visibleStations = const [];
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
