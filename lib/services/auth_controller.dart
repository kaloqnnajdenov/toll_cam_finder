import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_messages.dart';

/// Simple wrapper around Supabase authentication that exposes the user state to
/// the widget tree. Errors are surfaced via [AuthFailure] so the UI can display
/// friendly messages without crashing the app.
class AuthController extends ChangeNotifier {
  AuthController({SupabaseClient? client}) : _client = client {
    if (_client != null) {
      _applySession(_client!.auth.currentSession);
      _authSubscription = _client!.auth.onAuthStateChange.listen((
        AuthState authState,
      ) {
        _applySession(authState.session);
      });
    }
  }

  final SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoggedIn = false;
  String? _currentEmail;
  String? _pendingEmail;
  String? _currentUserId;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentEmail => _currentEmail;
  String? get pendingEmail => _pendingEmail;
  String? get currentUserId => _currentUserId;
  bool get isConfigured => _client != null;
  SupabaseClient? get client => _client;
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Placeholder login flow. Replace with real implementation.
  Future<void> logIn({required String email, required String password}) async {
    if (_client == null) {
      throw AuthFailure(AppMessages.authenticationNotConfigured);
    }

    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = response.session;
      if (session != null) {
        _applySession(session);
      } else {
        _isLoggedIn = false;
        _currentEmail = null;
        _pendingEmail = response.user?.email ?? email;
        notifyListeners();
      }
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (error, stackTrace) {
      debugPrint('Login failed: $error\n$stackTrace');
      throw AuthFailure(AppMessages.unexpectedErrorSigningIn);
    }
  }

  /// Placeholder account creation hook. Replace with real implementation.
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (_client == null) {
      throw AuthFailure(AppMessages.authenticationNotConfigured);
    }

    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data:
            fullName != null && fullName.isNotEmpty ? {'full_name': fullName} : null,
      );

      final session = response.session;
      if (session != null) {
        _applySession(session);
      } else {
        _isLoggedIn = false;
        _currentEmail = null;
        _pendingEmail = response.user?.email ?? email;
        notifyListeners();
      }
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (error, stackTrace) {
      debugPrint('Sign-up failed: $error\n$stackTrace');
      throw AuthFailure(AppMessages.unexpectedErrorCreatingAccount);
    }
  }

  Future<void> logOut() async {
    if (_client == null) {
      _applySession(null);
      return;
    }

    try {
      await _client!.auth.signOut();
      _applySession(null);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (error, stackTrace) {
      debugPrint('Sign-out failed: $error\n$stackTrace');
      throw AuthFailure(AppMessages.unexpectedErrorSigningOut);
    }
  }

  void _applySession(Session? session) {
    final user = session?.user;
    _currentEmail = user?.email;
    _currentUserId = user?.id;
    _isLoggedIn = user != null;
    if (user != null) {
      _pendingEmail = null;
    }
    if (user == null) {
      _currentUserId = null;
    }
    notifyListeners();
  }
}


/// Friendly wrapper for authentication-related errors.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}