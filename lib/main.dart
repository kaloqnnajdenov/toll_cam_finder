import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/services/auth_controller.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/supabase_service.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialise();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AverageSpeedController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: const TollCamApp(),
    ),
  );
}
