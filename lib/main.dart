import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

import 'app/app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AverageSpeedController(),
      child: const TollCamApp(),
    ),
  );
}
