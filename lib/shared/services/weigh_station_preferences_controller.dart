import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeighStationPreferencesController extends ChangeNotifier {
  WeighStationPreferencesController() {
    unawaited(_loadPreference());
  }

  static const String _preferenceKey = 'show_weigh_stations_on_map';

  bool? _showWeighStations;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  bool get hasPreference => _showWeighStations != null;

  bool get shouldShowWeighStations => _showWeighStations ?? true;

  bool? get showWeighStationsPreference => _showWeighStations;

  Future<void> setShowWeighStations(bool value) async {
    _showWeighStations = value;
    _isLoaded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, value);
  }

  Future<void> clearPreference() async {
    _showWeighStations = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferenceKey);
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_preferenceKey)) {
      _showWeighStations = prefs.getBool(_preferenceKey);
    }
    _isLoaded = true;
    notifyListeners();
  }
}
