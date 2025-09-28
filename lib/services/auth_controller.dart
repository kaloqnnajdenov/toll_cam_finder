import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthResult {
  const AuthResult.success()
      : success = true,
        message = null;
  const AuthResult.failure(this.message) : success = false;

  final bool success;
  final String? message;
}

class AuthController extends ChangeNotifier {
  AuthController() {
    _initialise();
  }

  Session? _session;
  bool _available = false;
  GoTrueClient? _authClient;
  StreamSubscription<AuthState>? _authSubscription;

  bool get isAvailable => _available;
  bool get isAuthenticated => _session != null;
  User? get user => _session?.user;

  void _initialise() {
    _available = SupabaseService.isReady;
    if (!_available) {
      notifyListeners();
      return;
    }

    _authClient = SupabaseService.client?.auth;
    _session = _authClient?.currentSession;
    _authSubscription = _authClient?.onAuthStateChange.listen((event) {
      _session = event.session;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!_available || _authClient == null) {
      return const AuthResult.failure('Authentication is not configured.');
    }

    try {
      await _authClient!.signInWithPassword(email: email, password: password);
      return const AuthResult.success();
    } on AuthException catch (err) {
      return AuthResult.failure(err.message);
    } catch (err) {
      return AuthResult.failure('Unexpected error: $err');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    if (!_available || _authClient == null) {
      return const AuthResult.failure('Authentication is not configured.');
    }

    try {
      await _authClient!.signUp(email: email, password: password);
      return const AuthResult.success();
    } on AuthException catch (err) {
      return AuthResult.failure(err.message);
    } catch (err) {
      return AuthResult.failure('Unexpected error: $err');
    }
  }

  Future<AuthResult> signOut() async {
    if (!_available || _authClient == null) {
      return const AuthResult.failure('Authentication is not configured.');
    }

    try {
      await _authClient!.signOut();
      return const AuthResult.success();
    } on AuthException catch (err) {
      return AuthResult.failure(err.message);
    } catch (err) {
      return AuthResult.failure('Unexpected error: $err');
    }
  }
}
