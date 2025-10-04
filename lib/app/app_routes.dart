import 'package:flutter/material.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/profile_page.dart';
import '../presentation/pages/auth/sign_up_page.dart';
import '../presentation/pages/create_segment_page.dart';
import '../presentation/pages/map_page.dart';
import '../presentation/pages/segments_page.dart';

class AppRoutes {
  static const String map = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String profile = '/profile';
  static const String segments = '/segments';
  static const String localSegments = '/segments/local';
  static const String createSegment = '/segments/create';

  static Map<String, WidgetBuilder> get routes => {
    map: (_) => const MapPage(),
    login: (_) => const LoginPage(),
    signUp: (_) => const SignUpPage(),
    profile: (_) => const ProfilePage(),
    segments: (_) => const SegmentsPage(),
    localSegments: (_) => const LocalSegmentsPage(),
    createSegment: (_) => const CreateSegmentPage(),
  };
}
