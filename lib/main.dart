import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

import 'app/app.dart';
import 'services/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AverageSpeedController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),
      ],
      child: const TollCamApp(),
    ),
  );
}
