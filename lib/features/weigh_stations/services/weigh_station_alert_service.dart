import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/shared/audio/navigation_audio_context.dart';

class WeighStationAlertService {
  WeighStationAlertService({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    unawaited(_configurePlayer());
  }

  final AudioPlayer _player;
  String? _currentStationId;
  bool _hasPlayed = false;
  GuidanceAudioPolicy _audioPolicy = const GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );

  static const double alertDistanceMeters = 500.0;

  void updateAudioPolicy(GuidanceAudioPolicy policy) {
    if (_audioPolicy == policy) {
      return;
    }
    final bool hadAlert = _audioPolicy.allowAlertTones;
    _audioPolicy = policy;
    if (hadAlert && !policy.allowAlertTones) {
      unawaited(_player.stop());
    }
  }

  void updateDistance({required String? stationId, required double? distanceMeters}) {
    if (stationId == null || distanceMeters == null) {
      _resetState();
      return;
    }

    if (_currentStationId != stationId) {
      _currentStationId = stationId;
      _hasPlayed = false;
    }

    if (distanceMeters >= alertDistanceMeters) {
      _hasPlayed = false;
      return;
    }

    if (!_hasPlayed && distanceMeters >= 1 && _audioPolicy.allowAlertTones) {
      _hasPlayed = true;
      unawaited(
        _player.play(AssetSource(AppConstants.upcomingSegmentSoundAsset)),
      );
    }
  }

  void reset() {
    _resetState();
  }

  Future<void> dispose() => _player.dispose();

  void _resetState() {
    _currentStationId = null;
    _hasPlayed = false;
  }

  Future<void> _configurePlayer() async {
    try {
      await _player.setAudioContext(navigationAudioContext);
    } catch (_) {
      // best effort
    }
  }
}
