import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundNotificationService {
  BackgroundNotificationService()
      : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const int _notificationId = 1001;
  static const String _channelId = 'toll_app_background_channel';
  static const String _channelName = 'Toll App Background Activity';

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initializationSettings);

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            DarwinFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showActiveNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifies that the Toll app is running in the background.',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _notificationId,
      'Toll Cam Finder',
      'The Toll App is active',
      notificationDetails,
    );
  }

  Future<void> cancelActiveNotification() async {
    await _plugin.cancel(_notificationId);
  }
}
