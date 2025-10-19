import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toll_cam_finder/app/app.dart';
import 'package:toll_cam_finder/core/supabase_config.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'package:toll_cam_finder/splash/toll_signal_splash.dart';

Future<SupabaseClient?> initializeApp() async {
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

  return supabaseClient;
}

class TollSignalBootstrap extends StatefulWidget {
  const TollSignalBootstrap({super.key});

  @override
  State<TollSignalBootstrap> createState() => _TollSignalBootstrapState();
}

class _TollSignalBootstrapState extends State<TollSignalBootstrap> {
  SupabaseClient? _supabaseClient;
  bool _isReady = false;
  bool _isInitializing = false;

  Future<void> _handleReady() async {
    if (_isInitializing || _isReady) {
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    try {
      final client = await initializeApp();

      if (!mounted) {
        return;
      }

      setState(() {
        _supabaseClient = client;
        _isReady = true;
        _isInitializing = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize TollSignal: $error\n$stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return MaterialApp(
        title: 'TollSignal',
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: TollSignalSplash(
          title: 'TollSignal',
          tagline: "Know what's ahead.",
          onReady: _handleReady,
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AverageSpeedController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(client: _supabaseClient),
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
    );
  }
}
