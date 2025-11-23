import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toll_cam_finder/shared/services/weigh_station_preferences_controller.dart';

class IntroFlowState {
  const IntroFlowState({
    required this.showIntro,
    required this.showWelcomeOverlay,
    required this.showWeighStationsPrompt,
    required this.introCompleted,
    required this.introFlowPresented,
    required this.termsAccepted,
  });

  final bool showIntro;
  final bool showWelcomeOverlay;
  final bool showWeighStationsPrompt;
  final bool? introCompleted;
  final bool introFlowPresented;
  final bool termsAccepted;

  IntroFlowState copyWith({
    bool? showIntro,
    bool? showWelcomeOverlay,
    bool? showWeighStationsPrompt,
    Object? introCompleted = _unsetIntroCompleted,
    bool? introFlowPresented,
    bool? termsAccepted,
  }) {
    return IntroFlowState(
      showIntro: showIntro ?? this.showIntro,
      showWelcomeOverlay: showWelcomeOverlay ?? this.showWelcomeOverlay,
      showWeighStationsPrompt:
          showWeighStationsPrompt ?? this.showWeighStationsPrompt,
      introCompleted: introCompleted == _unsetIntroCompleted
          ? this.introCompleted
          : introCompleted as bool?,
      introFlowPresented: introFlowPresented ?? this.introFlowPresented,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }
}

const _unsetIntroCompleted = Object();

class IntroFlowController extends ChangeNotifier {
  IntroFlowController({
    required Future<SharedPreferences> prefsFuture,
    required WeighStationPreferencesController
        weighStationPreferencesController,
  })  : _prefsFuture = prefsFuture,
        _weighStationPreferences = weighStationPreferencesController,
        _state = const IntroFlowState(
          showIntro: false,
          showWelcomeOverlay: false,
          showWeighStationsPrompt: false,
          introCompleted: null,
          introFlowPresented: true,
          termsAccepted: false,
        );

  static const String _introCompletedPreferenceKey = 'map_intro_completed';
  static const String _termsAcceptedPreferenceKey =
      'terms_and_conditions_accepted';

  final Future<SharedPreferences> _prefsFuture;
  final WeighStationPreferencesController _weighStationPreferences;

  IntroFlowState _state;

  IntroFlowState get state => _state;

  bool get introReady =>
      (state.introCompleted ?? false) && state.termsAccepted;

  Future<void> load() async {
    final prefs = await _prefsFuture;
    final completed = prefs.getBool(_introCompletedPreferenceKey) ?? false;
    final termsAccepted =
        prefs.getBool(_termsAcceptedPreferenceKey) ?? false;
    final bool introReady = completed && termsAccepted;

    _updateState(
      _state.copyWith(
        introCompleted: completed,
        introFlowPresented: introReady,
        termsAccepted: termsAccepted,
      ),
    );
    evaluateFlow();
  }

  void revealIntro() {
    _updateState(_state.copyWith(showIntro: true));
  }

  Future<bool> dismissIntro() async {
    if (!_state.termsAccepted) {
      return false;
    }
    final bool alreadyCompleted = _state.introCompleted == true;
    _updateState(
      _state.copyWith(
        showIntro: false,
        introCompleted: true,
        introFlowPresented: true,
      ),
    );
    if (!alreadyCompleted) {
      final prefs = await _prefsFuture;
      await prefs.setBool(_introCompletedPreferenceKey, true);
    }
    return !alreadyCompleted;
  }

  Future<void> setTermsAccepted(bool accepted) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_termsAcceptedPreferenceKey, accepted);
    _updateState(_state.copyWith(termsAccepted: accepted));
    evaluateFlow();
  }

  void dismissWelcomeOverlay() {
    _updateState(
      _state.copyWith(
        showWelcomeOverlay: false,
        showWeighStationsPrompt: true,
      ),
    );
  }

  Future<void> completeWeighStationsPrompt(
    bool enabled, {
    VoidCallback? onWeighStationsDisabled,
  }) async {
    _updateState(
      _state.copyWith(showWeighStationsPrompt: false),
    );
    await _weighStationPreferences.setShowWeighStations(enabled);
    evaluateFlow(onWeighStationsDisabled: onWeighStationsDisabled);
  }

  void evaluateFlow({VoidCallback? onWeighStationsDisabled}) {
    if (!_weighStationPreferences.isLoaded) {
      return;
    }

    final bool hasPreference =
        _weighStationPreferences.hasPreference;
    final bool shouldShowWeighStations =
        _weighStationPreferences.shouldShowWeighStations;

    bool showWelcome = _state.showWelcomeOverlay;
    bool showPrompt = _state.showWeighStationsPrompt;
    bool showIntro = _state.showIntro;
    bool introFlowPresented = _state.introFlowPresented;

    if (!hasPreference) {
      if (!showPrompt) {
        showWelcome = true;
      }
      showIntro = false;
    } else {
      if (!shouldShowWeighStations) {
        onWeighStationsDisabled?.call();
      }
      showWelcome = false;
      showPrompt = false;
      if (!introFlowPresented) {
        showIntro = true;
        introFlowPresented = true;
      }
    }

    _updateState(
      _state.copyWith(
        showWelcomeOverlay: showWelcome,
        showWeighStationsPrompt: showPrompt,
        showIntro: showIntro,
        introFlowPresented: introFlowPresented,
      ),
    );
  }

  void _updateState(IntroFlowState next, {bool notify = true}) {
    _state = next;
    if (notify) {
      notifyListeners();
    }
  }
}
