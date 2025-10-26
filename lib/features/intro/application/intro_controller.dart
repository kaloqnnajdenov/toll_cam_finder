import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroController extends ChangeNotifier {
  static const _hasSeenIntroKey = 'has_seen_intro';

  bool _hasLoaded = false;
  bool _hasSeenIntro = false;

  IntroController() {
    _loadPreference();
  }

  bool get isLoading => !_hasLoaded;
  bool get shouldShowIntro => _hasLoaded && !_hasSeenIntro;

  Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenIntroKey, true);
    _hasSeenIntro = true;
    notifyListeners();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenIntro = prefs.getBool(_hasSeenIntroKey) ?? false;
    _hasLoaded = true;
    notifyListeners();
  }
}
