import 'package:flutter/material.dart';

import '../app/localization/app_localizations.dart';
import '../core/app_messages.dart';

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
  LanguageController() {
    AppMessages.updateLocale(_locale);
  }

  static const List<LanguageOption> _languageOptions = [
    LanguageOption(
      locale: Locale('en'),
      label: 'English',
      available: true,
    ),
    LanguageOption(
      locale: Locale('es'),
      label: 'Español',
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
  }
}
