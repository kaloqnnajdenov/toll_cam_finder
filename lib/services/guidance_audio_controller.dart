import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class GuidanceAudioPolicy {
  const GuidanceAudioPolicy({
    required this.allowSpeech,
    required this.allowAlertTones,
    required this.allowBoundaryTones,
  });

  final bool allowSpeech;
  final bool allowAlertTones;
  final bool allowBoundaryTones;

  bool canPlayTone({required bool isBoundary}) {
    return isBoundary ? allowBoundaryTones : allowAlertTones;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuidanceAudioPolicy &&
        other.allowSpeech == allowSpeech &&
        other.allowAlertTones == allowAlertTones &&
        other.allowBoundaryTones == allowBoundaryTones;
  }

  @override
  int get hashCode => Object.hash(
        allowSpeech,
        allowAlertTones,
        allowBoundaryTones,
      );
}

enum GuidanceAudioMode {
  muteForeground,
  muteBackground,
  absoluteMute,
}

class GuidanceAudioController extends ChangeNotifier {
  GuidanceAudioController() {
    unawaited(_loadSavedMode());
  }

  static const String _preferenceKey = 'guidance_audio_mode';

  static const GuidanceAudioPolicy _fullAccessPolicy = GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );

  static const GuidanceAudioPolicy _mutedWithBoundaryPolicy = GuidanceAudioPolicy(
    allowSpeech: false,
    allowAlertTones: false,
    allowBoundaryTones: true,
  );

  static const GuidanceAudioPolicy _absoluteMutePolicy = GuidanceAudioPolicy(
    allowSpeech: false,
    allowAlertTones: false,
    allowBoundaryTones: false,
  );

  GuidanceAudioMode _mode = GuidanceAudioMode.muteForeground;

  GuidanceAudioMode get mode => _mode;

  GuidanceAudioPolicy policyFor(AppLifecycleState? lifecycleState) {
    final AppLifecycleState effectiveState =
        lifecycleState ?? AppLifecycleState.resumed;
    final bool isForeground = effectiveState == AppLifecycleState.resumed;

    switch (_mode) {
      case GuidanceAudioMode.muteForeground:
        return isForeground ? _mutedWithBoundaryPolicy : _fullAccessPolicy;
      case GuidanceAudioMode.muteBackground:
        return isForeground ? _fullAccessPolicy : _mutedWithBoundaryPolicy;
      case GuidanceAudioMode.absoluteMute:
        return _absoluteMutePolicy;
    }
  }

  void setMode(GuidanceAudioMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    unawaited(_persistMode());
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_preferenceKey);
    if (saved == null) {
      return;
    }

    for (final option in GuidanceAudioMode.values) {
      if (option.name == saved) {
        if (_mode != option) {
          _mode = option;
          notifyListeners();
        }
        return;
      }
    }
  }

  Future<void> _persistMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, _mode.name);
  }
}
