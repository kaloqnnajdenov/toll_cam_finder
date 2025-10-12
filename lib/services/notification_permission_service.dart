import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class NotificationPermissionService {
  const NotificationPermissionService();

  static const MethodChannel _channel = MethodChannel(
    'com.example.toll_cam_finder/notifications',
  );

  Future<bool> ensurePermissionGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final bool? alreadyEnabled =
          await _channel.invokeMethod<bool>('areNotificationsEnabled');
      if (alreadyEnabled ?? true) {
        return true;
      }

      final bool? granted =
          await _channel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final bool? enabled =
          await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return enabled ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('openNotificationSettings');
    } on PlatformException {
      // Ignored: opening settings is a best-effort operation.
    }
  }
}
