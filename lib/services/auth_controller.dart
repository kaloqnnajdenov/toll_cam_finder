import 'package:flutter/foundation.dart';

/// Lightweight controller that tracks the authenticated user state.
///
/// This implementation intentionally avoids any actual authentication logic
/// so the real flows can be plugged in later.
class AuthController extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _currentEmail;
  String? _pendingEmail;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentEmail => _currentEmail;
  String? get pendingEmail => _pendingEmail;

  /// Placeholder login flow. Replace with real implementation.
  Future<void> logIn({required String email, required String password}) async {
    _currentEmail = email;
    _isLoggedIn = true;
    _pendingEmail = null;
    notifyListeners();
  }

  /// Placeholder account creation hook. Replace with real implementation.
  Future<void> register({required String email}) async {
    _pendingEmail = email;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> logOut() async {
    _isLoggedIn = false;
    _currentEmail = null;
    notifyListeners();
  }
}
