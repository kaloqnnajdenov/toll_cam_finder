import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_colors.dart';

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.success,
    onSecondary: Colors.white,
    tertiary: AppColors.warning,
    onTertiary: AppColors.background,
    error: AppColors.danger,
    onError: Colors.white,
    background: AppColors.background,
    onBackground: AppColors.onDark,
    surface: AppColors.surface,
    onSurface: AppColors.onDark,
    surfaceTint: Colors.transparent,
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,
  );

  final floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.surface.withOpacity(0.7),
    foregroundColor: AppColors.onDark,
    elevation: 0,
    highlightElevation: 0,
    shape: const CircleBorder(
      side: BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.onDark,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: floatingActionButtonTheme,
    dividerColor: AppColors.divider,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.toastBackground,
      contentTextStyle: TextStyle(color: AppColors.onDark),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
