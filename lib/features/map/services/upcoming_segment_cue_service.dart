import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/shared/audio/navigation_audio_context.dart';

class UpcomingSegmentCueService {
  UpcomingSegmentCueService({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    unawaited(_configurePlayer());
  }

  final AudioPlayer _player;
  String? _segmentId;
  bool _hasPlayed = false;
  GuidanceAudioPolicy _audioPolicy = const GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );

  void updateAudioPolicy(GuidanceAudioPolicy policy) {
    if (_audioPolicy == policy) {
      return;
    }
    final bool hadAlertAccess = _audioPolicy.allowAlertTones;
    _audioPolicy = policy;
    if (!policy.allowAlertTones && hadAlertAccess) {
      unawaited(_player.stop());
    }
  }

  void updateCue(SegmentDebugPath upcoming) {
    final String segmentId = upcoming.id;
    final double distance = upcoming.startDistanceMeters;

    if (_segmentId != segmentId) {
      _segmentId = segmentId;
      _hasPlayed = false;
    }

    if (distance >= 500) {
      _hasPlayed = false;
      return;
    }

    if (distance >= 1 && !_hasPlayed && _audioPolicy.allowAlertTones) {
      _hasPlayed = true;
      unawaited(
        _player.play(AssetSource(AppConstants.upcomingSegmentSoundAsset)),
      );
    }
  }

  void reset() {
    _segmentId = null;
    _hasPlayed = false;
  }

  Future<void> dispose() => _player.dispose();

  Future<void> _configurePlayer() async {
    try {
      await _player.setAudioContext(navigationAudioContext);
    } catch (_) {
      // Ignored: best-effort configuration.
    }
  }
}
