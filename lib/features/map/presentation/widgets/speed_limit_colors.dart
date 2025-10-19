import 'package:flutter/material.dart';
import 'package:toll_cam_finder/core/app_colors.dart';

Color? resolveSpeedLimitColor(
  AppPalette palette,
  double? speedKph,
  double? limitKph,
) {
  final double? speed = _sanitizeSpeedValue(speedKph);
  final double? limit = _sanitizeSpeedValue(limitKph);
  if (speed == null || limit == null || limit <= 0) {
    return null;
  }

  final double ratio = speed / limit;
  if (ratio <= 0.8) {
    return palette.success;
  }
  if (ratio < 1.0) {
    return palette.warning;
  }
  return palette.danger;
}

double? _sanitizeSpeedValue(double? value) {
  if (value == null || !value.isFinite) return null;
  if (value < 0) return 0;
  return value;
}

