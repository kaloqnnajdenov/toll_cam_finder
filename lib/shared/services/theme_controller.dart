import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  void toggle() => setDarkMode(!isDarkMode);
}
