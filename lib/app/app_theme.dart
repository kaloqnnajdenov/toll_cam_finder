import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_colors.dart';

ThemeData buildAppTheme({required bool isDarkMode}) {
  final AppPalette palette = isDarkMode ? AppColors.dark : AppColors.light;

  final ColorScheme colorScheme = isDarkMode
      ? ColorScheme.dark(
          primary: palette.primary,
          onPrimary: Colors.white,
          secondary: palette.success,
          onSecondary: Colors.white,
          tertiary: palette.warning,
          onTertiary: palette.onSurface,
          error: palette.danger,
          onError: Colors.white,
          background: palette.background,
          onBackground: palette.onSurface,
          surface: palette.surface,
          onSurface: palette.onSurface,
          surfaceTint: Colors.transparent,
          outline: palette.divider,
          outlineVariant: palette.divider,
        )
      : ColorScheme.light(
          primary: palette.primary,
          onPrimary: Colors.white,
          secondary: palette.success,
          onSecondary: Colors.white,
          tertiary: palette.warning,
          onTertiary: palette.onSurface,
          error: palette.danger,
          onError: Colors.white,
          background: palette.background,
          onBackground: palette.onSurface,
          surface: palette.surface,
          onSurface: palette.onSurface,
          surfaceTint: Colors.transparent,
          outline: palette.divider,
          outlineVariant: palette.divider,
        );

  final floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor:
        palette.surface.withOpacity(isDarkMode ? 0.7 : 0.9),
    foregroundColor: palette.onSurface,
    elevation: 0,
    highlightElevation: 0,
    shape: CircleBorder(
      side: BorderSide(color: palette.divider.withOpacity(isDarkMode ? 1 : 0.6), width: 1),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: palette.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: floatingActionButtonTheme,
    dividerColor: palette.divider,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.toastBackground,
      contentTextStyle: TextStyle(color: palette.onSurface),
      actionTextColor: palette.primary,
      behavior: SnackBarBehavior.floating,
    ),
    extensions: <ThemeExtension<dynamic>>[palette],
  );
}
