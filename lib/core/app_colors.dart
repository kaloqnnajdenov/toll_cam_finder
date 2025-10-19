import 'package:flutter/material.dart';

/// Theme extension that exposes the Toll Cam Finder color palette for both the
/// dark and light experiences.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.secondaryText,
    required this.divider,
    required this.unavailable,
    required this.mapScrim,
    required this.toastBackground,
  });

  final Brightness brightness;
  final Color primary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color secondaryText;
  final Color divider;
  final Color unavailable;
  final Color mapScrim;
  final Color toastBackground;

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF3B82F6),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    background: Color(0xFF0B1220),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFF8FAFC),
    secondaryText: Color(0xFF94A3B8),
    divider: Color(0xFF334155),
    unavailable: Color(0xFF64748B),
    mapScrim: Color(0x800B1220),
    toastBackground: Color(0xE6111827),
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF3B82F6),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    secondaryText: Color(0xFF475569),
    divider: Color(0xFFD0D8E4),
    unavailable: Color(0xFF94A3B8),
    mapScrim: Color(0xCCF8FAFC),
    toastBackground: Color(0xF2FFFFFF),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? primary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? secondaryText,
    Color? divider,
    Color? unavailable,
    Color? mapScrim,
    Color? toastBackground,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
      unavailable: unavailable ?? this.unavailable,
      mapScrim: mapScrim ?? this.mapScrim,
      toastBackground: toastBackground ?? this.toastBackground,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      unavailable: Color.lerp(unavailable, other.unavailable, t)!,
      mapScrim: Color.lerp(mapScrim, other.mapScrim, t)!,
      toastBackground: Color.lerp(toastBackground, other.toastBackground, t)!,
    );
  }
}

class AppColors {
  AppColors._();

  static const AppPalette dark = AppPalette.dark;
  static const AppPalette light = AppPalette.light;

  static AppPalette of(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>();
    return palette ?? dark;
  }
}
