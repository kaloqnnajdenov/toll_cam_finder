import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toll_cam_finder/core/supabase_config.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

import 'app/app.dart';
import 'services/auth_controller.dart';
import 'services/language_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseClient? supabaseClient;

  if (SupabaseConfig.isConfigured) {
    final supabase = await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    supabaseClient = supabase.client;
  } else {
    debugPrint(
      'Supabase credentials missing. Authentication features are disabled.',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AverageSpeedController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(client: supabaseClient),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageController(),
        ),
      ],
      child: const TollCamApp(),
    ),
  );
}
