import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AverageSpeedController(),
      child: const TollCamApp(),
    ),
  );
}
