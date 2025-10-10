import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:toll_cam_finder/core/constants.dart';

/// Plays short audio cues associated with toll segments.
class SegmentAudioCues {
  SegmentAudioCues({SystemSoundType? upcomingSegmentSoundType})
      : _upcomingSegmentSoundType = upcomingSegmentSoundType ??
            AppConstants.upcomingSegmentCueSoundType;

  final SystemSoundType _upcomingSegmentSoundType;

  bool _disposed = false;

  /// Plays the notification sound that indicates the next segment is nearby.
  Future<void> playUpcomingSegmentCue() async {
    if (_disposed) return;
    try {
      await SystemSound.play(_upcomingSegmentSoundType);
    } catch (error, stackTrace) {
      debugPrint(
        'SegmentAudioCues: failed to play upcoming segment cue: $error\n$stackTrace',
      );
    }
  }

  /// No-op dispose to preserve the previous API shape.
  Future<void> dispose() async {
    _disposed = true;
  }
}
