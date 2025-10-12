import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../services/language_controller.dart';
import 'app_routes.dart';
import 'app_theme.dart';
import 'localization/app_localizations.dart';
import 'lifecycle_observer.dart';

class TollCamApp extends StatelessWidget {
  const TollCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageController>(
      builder: (context, languageController, _) {
        final appLocalizations = AppLocalizations(languageController.locale);
        return LifecycleObserver(
          child: MaterialApp(
            title: appLocalizations.appTitle,
            theme: buildAppTheme(),
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
          ),
        );
      },
    );
  }
}
