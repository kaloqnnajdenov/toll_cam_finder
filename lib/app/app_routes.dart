import 'package:flutter/material.dart';
import '../presentation/pages/map_page.dart';

class AppRoutes {
  static const String map = '/';

  static Map<String, WidgetBuilder> get routes => {
        map: (_) => const MapPage(),
      };
}
