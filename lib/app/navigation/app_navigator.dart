import 'package:flutter/widgets.dart';

import '../app_routes.dart';

/// Provides a global navigator key so services can interact with the
/// navigation stack when the app is restored from the background.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Ensures the map route is visible when the app is resumed from the
  /// background via a notification tap.
  static void bringToForeground() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil(AppRoutes.map, (route) => false);
  }
}
