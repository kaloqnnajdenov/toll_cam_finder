import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toll_cam_finder/app/app.dart';
import 'package:toll_cam_finder/core/supabase_config.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/segments_only_mode_controller.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'package:toll_cam_finder/shared/audio/navigation_audio_context.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayer.global.setAudioContext(navigationAudioContext);

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
          create: (_) => SegmentsOnlyModeController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(client: supabaseClient),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageController(),
        ),
        ChangeNotifierProvider(
          create: (_) => GuidanceAudioController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeController(),
        ),
      ],
      child: const TollCamApp(),
    ),
  );
}
