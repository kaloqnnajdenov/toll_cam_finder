import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

class UpcomingSegmentCueService {
  UpcomingSegmentCueService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _segmentId;
  bool _hasPlayed = false;

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

    if (distance >= 1 && !_hasPlayed) {
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
}
