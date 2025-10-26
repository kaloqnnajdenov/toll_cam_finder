import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/loading_page.dart';
import 'package:toll_cam_finder/features/intro/application/intro_controller.dart';
import 'package:toll_cam_finder/features/intro/presentation/pages/intro_page.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map_page.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'app_routes.dart';
import 'app_theme.dart';
import 'localization/app_localizations.dart';

class TollCamApp extends StatelessWidget {
  const TollCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<LanguageController, ThemeController, IntroController>(
      builder: (
        context,
        languageController,
        themeController,
        introController,
        _,
      ) {
        final appLocalizations = AppLocalizations(languageController.locale);
        final Widget home;

        if (introController.isLoading) {
          home = const LoadingPage();
        } else if (introController.shouldShowIntro) {
          home = const IntroPage();
        } else {
          home = const MapPage();
        }
        return MaterialApp(
          title: appLocalizations.appTitle,
          theme: buildAppTheme(isDarkMode: themeController.isDarkMode),
          home: home,
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
