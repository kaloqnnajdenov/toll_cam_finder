import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
