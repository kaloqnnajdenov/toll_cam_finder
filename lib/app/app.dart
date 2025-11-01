import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'app_routes.dart';
import 'app_theme.dart';
import 'localization/app_localizations.dart';

class TollCamApp extends StatefulWidget {
  const TollCamApp({super.key});

  @override
  State<TollCamApp> createState() => _TollCamAppState();
}

class _TollCamAppState extends State<TollCamApp> with WidgetsBindingObserver {
  bool _wakelockActive = false;
  Timer? _wakelockLogTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_updateWakelock(WidgetsBinding.instance.lifecycleState));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWakelockLogging();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    unawaited(_updateWakelock(state));
  }

  Future<void> _updateWakelock(AppLifecycleState? state) async {
    final shouldEnable = state == null || state == AppLifecycleState.resumed;

    if (shouldEnable) {
      await _enableWakelock();
    } else {
      await _disableWakelock();
    }
  }

  Future<void> _enableWakelock() async {
    if (_wakelockActive) {
      return;
    }

    await WakelockPlus.enable();
    _wakelockActive = true;
    _startWakelockLogging();
  }

  Future<void> _disableWakelock() async {
    if (!_wakelockActive) {
      return;
    }

    await WakelockPlus.disable();
    _wakelockActive = false;
    _stopWakelockLogging();
  }

  void _startWakelockLogging() {
    _wakelockLogTimer?.cancel();
    _wakelockLogTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => debugPrint('WAKELOCK'));
  }

  void _stopWakelockLogging() {
    _wakelockLogTimer?.cancel();
    _wakelockLogTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageController, ThemeController>(
      builder: (context, languageController, themeController, _) {
        final appLocalizations = AppLocalizations(languageController.locale);
        return MaterialApp(
          title: appLocalizations.appTitle,
          theme: buildAppTheme(isDarkMode: themeController.isDarkMode),
          initialRoute: AppRoutes.map,
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: false,
          locale: languageController.locale,
          supportedLocales: languageController.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizationsDelegate(),
          ],
        );
      },
    );
  }
}
