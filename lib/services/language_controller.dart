import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/localization/app_localizations.dart';
import '../core/app_messages.dart';

class LanguageOption {
  const LanguageOption({
    required this.locale,
    required this.languageCode,
    this.available = true,
  });

  final Locale locale;
  final String languageCode;
  final bool available;

  String get label {
    switch (languageCode) {
      case 'bg':
        return AppMessages.languageLabelBulgarian;
      case 'en':
      default:
        return AppMessages.languageLabelEnglish;
    }
  }
}

class LanguageController extends ChangeNotifier {
  LanguageController() {
    AppMessages.updateLocale(_locale);
    unawaited(_loadSavedLocale());
  }

  static const String _languagePreferenceKey = 'preferred_language_code';

  static const List<LanguageOption> _languageOptions = [
    LanguageOption(
      locale: Locale('en'),
      languageCode: 'en',
      available: true,
    ),
    LanguageOption(
      locale: Locale('bg'),
      languageCode: 'bg',
      available: true,
    ),
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  List<LanguageOption> get languageOptions => _languageOptions;

  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  LanguageOption get currentOption => _languageOptions.firstWhere(
        (option) => option.locale == _locale,
        orElse: () => _languageOptions.first,
      );

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languagePreferenceKey);
    if (savedCode == null) {
      return;
    }

    for (final option in _languageOptions) {
      if (option.available && option.languageCode == savedCode) {
        if (_locale != option.locale) {
          _locale = option.locale;
          AppMessages.updateLocale(_locale);
          notifyListeners();
        }
        break;
      }
    }
  }

  void setLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }
    final isSupported = _languageOptions.any(
      (option) => option.available && option.locale == locale,
    );
    if (!isSupported) {
      return;
    }

    _locale = locale;
    AppMessages.updateLocale(_locale);
    notifyListeners();
    unawaited(_persistLocale());
  }

  Future<void> _persistLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, _locale.languageCode);
  }
}
