import 'package:flutter/material.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/profile_page.dart';
import '../presentation/pages/auth/sign_up_page.dart';
import '../presentation/pages/map_page.dart';

class AppRoutes {
  static const String map = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
        map: (_) => const MapPage(),
        login: (_) => const LoginPage(),
        signUp: (_) => const SignUpPage(),
        profile: (_) => const ProfilePage(),
      };
}
