import 'package:audioplayers/audioplayers.dart';

/// Audio context used for short navigation cues.
///
/// It requests transient focus that allows other apps (for example music
/// players) to keep playing at a reduced volume while Toll Cam Finder delivers
/// guidance.
final AudioContext navigationAudioContext = AudioContext(
  android: const AudioContextAndroid(
    contentType: AndroidContentType.speech,
    usageType: AndroidUsageType.assistanceNavigationGuidance,
    audioFocus: AndroidAudioFocus.gainTransientMayDuck,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
    options: <AVAudioSessionOptions>{
      AVAudioSessionOptions.mixWithOthers,
      AVAudioSessionOptions.duckOthers,
      AVAudioSessionOptions.interruptSpokenAudioAndMixWithOthers,
    },
  ),
);
