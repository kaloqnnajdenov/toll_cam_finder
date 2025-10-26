import 'package:flutter/material.dart';
import 'package:toll_cam_finder/features/auth/presentation/pages/login_page.dart';
import 'package:toll_cam_finder/features/auth/presentation/pages/profile_page.dart';
import 'package:toll_cam_finder/features/auth/presentation/pages/sign_up_page.dart';
import 'package:toll_cam_finder/app/loading_page.dart';
import 'package:toll_cam_finder/features/intro/presentation/pages/intro_page.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map_page.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/segments_only_page.dart';
import 'package:toll_cam_finder/features/segments/presentation/pages/create_segment_page.dart';
import 'package:toll_cam_finder/features/segments/presentation/pages/segments_page.dart';


class AppRoutes {
  static const String loading = '/loading';
  static const String intro = '/intro';
  static const String map = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String profile = '/profile';
  static const String segments = '/segments';
  static const String localSegments = '/segments/local';
  static const String createSegment = '/segments/create';
  static const String segmentsOnly = '/segments-only';

  static Map<String, WidgetBuilder> get routes => {
    loading: (_) => const LoadingPage(),
    intro: (_) => const IntroPage(),
    map: (_) => const MapPage(),
    login: (_) => const LoginPage(),
    signUp: (_) => const SignUpPage(),
    profile: (_) => const ProfilePage(),
    segments: (_) => const SegmentsPage(),
    localSegments: (_) => const LocalSegmentsPage(),
    createSegment: (_) => const CreateSegmentPage(),
    segmentsOnly: (_) => const SegmentsOnlyPage(),
  };
}
