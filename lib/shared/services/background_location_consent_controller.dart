import 'package:flutter/foundation.dart';

import 'background_location_consent_service.dart';

class BackgroundLocationConsentController extends ChangeNotifier {
  BackgroundLocationConsentController({
    BackgroundLocationConsentService? service,
  }) : _service = service ?? const BackgroundLocationConsentService();

  final BackgroundLocationConsentService _service;
  bool? _allowed;
  bool _isLoaded = false;
  bool _isLoading = false;

  bool? get allowed => _allowed;
  bool get isLoaded => _isLoaded;

  Future<void> ensureLoaded() async {
    if (_isLoaded || _isLoading) {
      return;
    }
    _isLoading = true;
    final consent = await _service.getConsent();
    _allowed = consent;
    _isLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setAllowed(bool allow) async {
    _allowed = allow;
    _isLoaded = true;
    notifyListeners();
    await _service.setConsent(allow);
  }
}
