import 'dart:async';

import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/features/map/services/osm_speed_limit_service.dart';

typedef _SpeedLimitChanged = void Function(String? speedLimitKph);
typedef _AvailabilityChanged = void Function(bool isAvailable);
typedef _OnUnavailableBeyondGrace = void Function();

class SpeedLimitPollingController {
  SpeedLimitPollingController({
    required OsmSpeedLimitService osmSpeedLimitService,
    required _SpeedLimitChanged onSpeedLimitChanged,
    required _AvailabilityChanged onAvailabilityChanged,
    required _OnUnavailableBeyondGrace onUnavailableBeyondGrace,
    Duration unavailableGracePeriod = const Duration(seconds: 3),
  })  : _osmSpeedLimitService = osmSpeedLimitService,
        _onSpeedLimitChanged = onSpeedLimitChanged,
        _onAvailabilityChanged = onAvailabilityChanged,
        _onUnavailableBeyondGrace = onUnavailableBeyondGrace,
        _osmUnavailableGracePeriod = unavailableGracePeriod;

  final OsmSpeedLimitService _osmSpeedLimitService;
  final _SpeedLimitChanged _onSpeedLimitChanged;
  final _AvailabilityChanged _onAvailabilityChanged;
  final _OnUnavailableBeyondGrace _onUnavailableBeyondGrace;
  final Duration _osmUnavailableGracePeriod;

  LatLng? _lastSpeedLimitQueryLocation;
  Timer? _speedLimitPollTimer;
  bool _isSpeedLimitRequestInFlight = false;
  bool _isMapInForeground = true;
  bool _isOsmServiceAvailable = true;
  DateTime? _osmUnavailableSince;
  String? _currentSpeedLimitKph;

  bool get isOsmServiceAvailable => _isOsmServiceAvailable;

  void updateVisibility({required bool isForeground}) {
    _isMapInForeground = isForeground;
    if (!_isMapInForeground) {
      _cancelSpeedLimitPolling();
      return;
    }

    final LatLng? lastLocation = _lastSpeedLimitQueryLocation;
    if (lastLocation != null) {
      _maybeFetchSpeedLimit(lastLocation);
    }
  }

  void updatePosition(LatLng position) {
    _maybeFetchSpeedLimit(position);
  }

  void dispose() {
    _cancelSpeedLimitPolling();
  }

  void _maybeFetchSpeedLimit(LatLng position) {
    _lastSpeedLimitQueryLocation = position;
    if (!_isMapInForeground) {
      _cancelSpeedLimitPolling();
      return;
    }

    final bool hasActiveTimer = _speedLimitPollTimer?.isActive ?? false;
    if (_isSpeedLimitRequestInFlight || hasActiveTimer) {
      return;
    }
    _speedLimitPollTimer = Timer(Duration.zero, _pollSpeedLimit);
  }

  void _scheduleNextSpeedLimitPoll() {
    if (!_isMapInForeground) {
      _cancelSpeedLimitPolling();
      return;
    }
    _speedLimitPollTimer?.cancel();
    _speedLimitPollTimer =
        Timer(_currentSpeedLimitPollInterval(), _pollSpeedLimit);
  }

  Duration _currentSpeedLimitPollInterval() {
    return _currentSpeedLimitKph == null
        ? const Duration(seconds: 1)
        : const Duration(seconds: 3);
  }

  void _cancelSpeedLimitPolling() {
    _speedLimitPollTimer?.cancel();
    _speedLimitPollTimer = null;
  }

  Future<void> _pollSpeedLimit() async {
    _cancelSpeedLimitPolling();
    if (_isSpeedLimitRequestInFlight) {
      _scheduleNextSpeedLimitPoll();
      return;
    }

    if (!_isMapInForeground) {
      return;
    }

    final LatLng? location = _lastSpeedLimitQueryLocation;
    if (location == null) {
      return;
    }

    _isSpeedLimitRequestInFlight = true;
    try {
      final result = await _osmSpeedLimitService.fetchSpeedLimit(location);

      _osmUnavailableSince = null;
      final bool shouldUpdateLimit =
          result != null && result != _currentSpeedLimitKph;
      final bool shouldUpdateAvailability = !_isOsmServiceAvailable;
      if (shouldUpdateLimit) {
        _currentSpeedLimitKph = result;
        _onSpeedLimitChanged(result);
      }
      if (shouldUpdateAvailability) {
        _isOsmServiceAvailable = true;
        _onAvailabilityChanged(true);
      } else {
        _isOsmServiceAvailable = true;
      }
    } catch (_) {
      final DateTime now = DateTime.now();
      if (_isOsmServiceAvailable) {
        _isOsmServiceAvailable = false;
        _onAvailabilityChanged(false);
      }

      _osmUnavailableSince ??= now;

      if (now.difference(_osmUnavailableSince!) >=
          _osmUnavailableGracePeriod) {
        _onUnavailableBeyondGrace();
      }
    } finally {
      _isSpeedLimitRequestInFlight = false;
      _scheduleNextSpeedLimitPoll();
    }
  }
}
