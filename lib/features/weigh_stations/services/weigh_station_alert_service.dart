import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/shared/audio/navigation_audio_context.dart';

class WeighStationAlertService {
  WeighStationAlertService({AudioPlayer? player, FlutterTts? tts})
      : _player = player ?? AudioPlayer(),
        _tts = tts ?? FlutterTts() {
    unawaited(_configurePlayer());
    unawaited(_tts.awaitSpeakCompletion(true));
    unawaited(_configureTextToSpeech());
  }

  final AudioPlayer _player;
  final FlutterTts _tts;
  String? _currentStationId;
  bool _hasPlayed = false;
  bool _hasSpoken = false;
  bool _useBulgarianVoice = false;
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
    final bool hadSpeech = _audioPolicy.allowSpeech;
    _audioPolicy = policy;
    if (hadAlert && !policy.allowAlertTones) {
      unawaited(_player.stop());
    }
    if (hadSpeech && !policy.allowSpeech) {
      unawaited(_tts.stop());
      if (_useBulgarianVoice) {
        unawaited(_player.stop());
      }
    }
  }

  void updateLanguage(String languageCode) {
    final bool useBulgarian = languageCode.toLowerCase() == 'bg';
    if (_useBulgarianVoice == useBulgarian) {
      return;
    }
    _useBulgarianVoice = useBulgarian;
  }

  void updateDistance({
    required String? stationId,
    required double? distanceMeters,
    required String approachMessage,
  }) {
    if (stationId == null || distanceMeters == null) {
      _resetState();
      return;
    }

    if (_currentStationId != stationId) {
      _currentStationId = stationId;
      _hasPlayed = false;
      _hasSpoken = false;
    }

    if (distanceMeters >= alertDistanceMeters) {
      _hasPlayed = false;
      _hasSpoken = false;
      return;
    }

    final bool isCloseEnough = distanceMeters >= 1;

    if (_useBulgarianVoice) {
      if (!_hasSpoken && isCloseEnough && _audioPolicy.allowSpeech) {
        _hasSpoken = true;
        unawaited(
          _playVoiceAsset(AppConstants.approachingWeighControlVoiceAsset),
        );
      }
      return;
    }

    if (!_hasPlayed && isCloseEnough && _audioPolicy.allowAlertTones) {
      _hasPlayed = true;
      unawaited(
        _player.play(AssetSource(AppConstants.upcomingSegmentSoundAsset)),
      );
    }

    if (!_hasSpoken && isCloseEnough && _audioPolicy.allowSpeech) {
      _hasSpoken = true;
      unawaited(_speak(approachMessage));
    }
  }

  void reset() {
    _resetState();
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _player.dispose();
  }

  void _resetState() {
    _currentStationId = null;
    _hasPlayed = false;
    _hasSpoken = false;
  }

  Future<void> _configurePlayer() async {
    try {
      await _player.setAudioContext(navigationAudioContext);
    } catch (_) {
      // best effort
    }
  }

  Future<void> _configureTextToSpeech() async {
    try {
      await Future<void>.value();
    } catch (_) {
      // best effort
    }

    try {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    } catch (_) {
      // best effort
    }
  }

  Future<void> _playVoiceAsset(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // best effort
    }
  }

  Future<void> _speak(String message) async {
    if (message.trim().isEmpty) {
      return;
    }
    try {
      await _tts.speak(message);
    } catch (_) {
      // best effort
    }
  }
}
