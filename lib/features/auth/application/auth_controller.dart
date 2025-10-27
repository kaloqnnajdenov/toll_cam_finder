import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/supabase_config.dart';

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
      throw  AuthFailure(AppMessages.authenticationNotConfigured);
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
      throw  AuthFailure(AppMessages.unexpectedErrorSigningOut);
    }
  }

  Future<void> deleteAccount() async {
    if (_currentUserId == null) {
      throw AuthFailure(AppMessages.unableToDetermineLoggedInAccount);
    }

    if (_client == null) {
      _applySession(null);
      return;
    }

    final session = _client!.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw AuthFailure(AppMessages.unableToDetermineLoggedInAccount);
    }

    try {
      final response = await http.delete(
        Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'apikey': SupabaseConfig.supabaseAnonKey,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _client!.auth.signOut();
        _applySession(null);
        return;
      }

      String? message;
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final dynamic maybeMessage =
            body['msg'] ?? body['message'] ?? body['error_description'];
        if (maybeMessage is String && maybeMessage.isNotEmpty) {
          message = maybeMessage;
        }
      } catch (_) {
        // Ignore JSON parsing errors – we'll fall back to a generic message.
      }

      throw AuthFailure(message ?? AppMessages.unableToDeleteAccount);
    } on AuthFailure {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Delete account HTTP failed: $error\n$stackTrace');
      throw AuthFailure(AppMessages.unableToDeleteAccount);
    } catch (error, stackTrace) {
      debugPrint('Delete account failed: $error\n$stackTrace');
      throw AuthFailure(AppMessages.unableToDeleteAccount);
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