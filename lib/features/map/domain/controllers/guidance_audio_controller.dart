import 'dart:async';

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
  fullGuidance,
  muteForeground,
  muteBackground,
  absoluteMute,
}

class GuidanceAudioController extends ChangeNotifier {
  GuidanceAudioController() {
    _lastEffectiveMode = _deriveEffectiveMode(_mode);
    unawaited(_loadSavedMode());
  }

  static const String _preferenceKey = 'guidance_audio_mode';
  static const String _preferenceUserSetKey = 'guidance_audio_mode_user_set';

  static const GuidanceAudioPolicy _fullAccessPolicy = GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );

  static const GuidanceAudioPolicy _absoluteMutePolicy = GuidanceAudioPolicy(
    allowSpeech: false,
    allowAlertTones: false,
    allowBoundaryTones: false,
  );

  GuidanceAudioMode _mode = GuidanceAudioMode.fullGuidance;
  bool _modeSetByUser = false;
  bool _preferencesLoaded = false;
  bool _backgroundAudioAllowed = false;
  bool _notificationsAllowed = true;
  late GuidanceAudioMode _lastEffectiveMode;

  GuidanceAudioMode get mode => _mode;
  GuidanceAudioMode get effectiveMode => _deriveEffectiveMode(_mode);

  void updatePermissions({
    required bool backgroundAudioAllowed,
    required bool notificationsAllowed,
  }) {
    final bool permissionsChanged =
        _backgroundAudioAllowed != backgroundAudioAllowed ||
            _notificationsAllowed != notificationsAllowed;

    _backgroundAudioAllowed = backgroundAudioAllowed;
    _notificationsAllowed = notificationsAllowed;

    bool modeAdjusted = false;
    if (_preferencesLoaded) {
      modeAdjusted = _maybeApplyAutomaticMode();
    }
    final bool effectiveChanged = _updateEffectiveModeSnapshot();

    if (modeAdjusted || effectiveChanged || permissionsChanged) {
      notifyListeners();
    }
  }

  GuidanceAudioPolicy policyFor(AppLifecycleState? lifecycleState) {
    final GuidanceAudioMode modeForPolicy = _deriveEffectiveMode(_mode);
    final AppLifecycleState effectiveState =
        lifecycleState ?? AppLifecycleState.resumed;
    final bool isForeground = effectiveState == AppLifecycleState.resumed;

    switch (modeForPolicy) {
      case GuidanceAudioMode.fullGuidance:
        return _fullAccessPolicy;
      case GuidanceAudioMode.muteForeground:
        return isForeground ? _absoluteMutePolicy : _fullAccessPolicy;
      case GuidanceAudioMode.muteBackground:
        return isForeground ? _fullAccessPolicy : _absoluteMutePolicy;
      case GuidanceAudioMode.absoluteMute:
        return _absoluteMutePolicy;
    }
  }

  void setMode(GuidanceAudioMode mode, {bool fromUser = true}) {
    final bool modeChanged = _mode != mode;
    final bool userFlagChanged = fromUser && !_modeSetByUser;

    if (modeChanged) {
      _mode = mode;
    }
    if (fromUser) {
      _modeSetByUser = true;
    }

    final bool effectiveChanged = _updateEffectiveModeSnapshot();
    if (modeChanged || userFlagChanged || effectiveChanged) {
      notifyListeners();
    }
    if (_preferencesLoaded && (modeChanged || userFlagChanged)) {
      unawaited(_persistMode());
    } else if (fromUser && (modeChanged || userFlagChanged)) {
      unawaited(_persistMode(force: true));
    }
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (_modeSetByUser) {
      _preferencesLoaded = true;
      _updateEffectiveModeSnapshot();
      return;
    }
    final String? previous = prefs.getString(_preferenceKey);
    final bool? previousWasUserSet =
        prefs.getBool(_preferenceUserSetKey);
    GuidanceAudioMode? loadedMode;
    if (previous != null) {
      for (final option in GuidanceAudioMode.values) {
        if (option.name == previous) {
          loadedMode = option;
          break;
        }
      }
    }

    final bool modeChanged = loadedMode != null && _mode != loadedMode;
    if (loadedMode != null) {
      _mode = loadedMode;
    }

    if (previousWasUserSet != null) {
      _modeSetByUser = previousWasUserSet;
    } else if (loadedMode != null &&
        loadedMode != GuidanceAudioMode.muteBackground) {
      _modeSetByUser = true;
    }

    _preferencesLoaded = true;
    final bool autoAdjusted = _maybeApplyAutomaticMode();
    final bool effectiveChanged = _updateEffectiveModeSnapshot();
    final bool shouldPersistUserFlag =
        previousWasUserSet == null && loadedMode != null;

    if (modeChanged || effectiveChanged || autoAdjusted) {
      notifyListeners();
    }
    if (shouldPersistUserFlag) {
      unawaited(_persistMode());
    }
  }

  Future<void> _persistMode({bool force = false}) async {
    if (!force && !_preferencesLoaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, _mode.name);
    await prefs.setBool(_preferenceUserSetKey, _modeSetByUser);
  }

  bool _maybeApplyAutomaticMode() {
    if (_modeSetByUser) {
      return false;
    }
    final GuidanceAudioMode target = _bestPermittedMode();
    if (target == _mode) {
      return false;
    }
    _mode = target;
    unawaited(_persistMode());
    return true;
  }

  GuidanceAudioMode _bestPermittedMode() {
    return _canUseBackgroundAudio
        ? GuidanceAudioMode.fullGuidance
        : GuidanceAudioMode.muteBackground;
  }

  GuidanceAudioMode _deriveEffectiveMode(GuidanceAudioMode requested) {
    if (!_canUseBackgroundAudio &&
        (requested == GuidanceAudioMode.fullGuidance ||
            requested == GuidanceAudioMode.muteForeground)) {
      return GuidanceAudioMode.muteBackground;
    }
    return requested;
  }

  bool get _canUseBackgroundAudio =>
      _backgroundAudioAllowed && _notificationsAllowed;

  bool _updateEffectiveModeSnapshot() {
    final GuidanceAudioMode currentEffective = _deriveEffectiveMode(_mode);
    if (currentEffective == _lastEffectiveMode) {
      return false;
    }
    _lastEffectiveMode = currentEffective;
    return true;
  }
}
