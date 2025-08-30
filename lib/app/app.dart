import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class TollCamApp extends StatelessWidget {
  const TollCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TollCam',
      theme: buildAppTheme(),
      initialRoute: AppRoutes.map,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
