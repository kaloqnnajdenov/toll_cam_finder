import 'dart:ui';

/// Stores the application's current locale so that services without access to
/// [BuildContext] can retrieve the active language.
class AppLocale {
  AppLocale._();

  static Locale _current = const Locale('en');

  /// Returns the locale currently selected by the user.
  static Locale get current => _current;

  /// The BCP-47 language code for the active locale.
  static String get languageCode => _current.languageCode;

  /// Updates the globally stored locale.
  static void update(Locale locale) {
    _current = locale;
  }
}
