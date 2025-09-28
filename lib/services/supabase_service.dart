import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class SupabaseService {
  const SupabaseService._();

  static bool _initialized = false;
  static bool _isConfigured = false;

  static bool get isConfigured => _isConfigured;

  static SupabaseClient? get clientOrNull =>
      _isConfigured ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final url = SupabaseConfig.url;
    final anonKey = SupabaseConfig.anonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        'Supabase credentials are not configured. Authentication features '
        'will be disabled.',
      );
      _initialized = true;
      _isConfigured = false;
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authFlowType: AuthFlowType.pkce,
    );
    _initialized = true;
    _isConfigured = true;
  }
}
