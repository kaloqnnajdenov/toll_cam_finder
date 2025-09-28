import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_secrets.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialised = false;

  static Future<void> initialise() async {
    if (_initialised) {
      return;
    }

    final url = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: AppSecrets.supabaseUrl,
    );
    final anonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: AppSecrets.supabaseAnonKey,
    );

    final isPlaceholder = url.isEmpty ||
        anonKey.isEmpty ||
        url == 'YOUR_SUPABASE_URL' ||
        anonKey == 'YOUR_SUPABASE_ANON_KEY';

    if (isPlaceholder) {
      debugPrint('Supabase credentials missing - authentication disabled.');
      return;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialised = true;
    } catch (error, stackTrace) {
      debugPrint('Supabase initialization failed: $error');
      debugPrint('$stackTrace');
      _initialised = false;
    }
  }

  static bool get isReady => _initialised;

  static SupabaseClient? get client =>
      _initialised ? Supabase.instance.client : null;
}
