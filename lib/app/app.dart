import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'app_routes.dart';
import 'app_theme.dart';
import 'localization/app_localizations.dart';

class TollCamApp extends StatelessWidget {
  const TollCamApp({super.key});

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
