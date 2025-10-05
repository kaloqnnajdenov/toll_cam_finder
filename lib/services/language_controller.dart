import 'package:flutter/material.dart';

class LanguageOption {
  const LanguageOption({
    required this.locale,
    required this.label,
    this.available = true,
  });

  final Locale locale;
  final String label;
  final bool available;
}

class LanguageController extends ChangeNotifier {
  LanguageController();

  static const List<LanguageOption> _languageOptions = [
    LanguageOption(
      locale: Locale('en'),
      label: 'English',
      available: true,
    ),
    LanguageOption(
      locale: Locale('es'),
      label: 'Español',
      available: false,
    ),
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  List<LanguageOption> get languageOptions => _languageOptions;

  List<Locale> get supportedLocales => _languageOptions
      .where((option) => option.available)
      .map((option) => option.locale)
      .toList();

  LanguageOption get currentOption => _languageOptions.firstWhere(
        (option) => option.locale == _locale,
        orElse: () => _languageOptions.first,
      );

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
    notifyListeners();
  }
}
