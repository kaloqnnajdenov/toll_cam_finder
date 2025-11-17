import 'package:shared_preferences/shared_preferences.dart';

class BackgroundLocationConsentService {
  const BackgroundLocationConsentService();

  static const String _preferenceKey = 'background_location_consent';

  Future<bool?> getConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preferenceKey);
  }

  Future<void> setConsent(bool allow) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, allow);
  }
}
