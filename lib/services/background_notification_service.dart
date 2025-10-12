import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundNotificationService {
  BackgroundNotificationService()
      : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const int _notificationId = 1001;
  static const String _channelId = 'toll_app_background_channel';
  static const String _channelName = 'Toll App Background Activity';
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription:
        'Notifies that the Toll app is running in the background.',
    importance: Importance.high,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  bool _isNotificationVisible = false;
  String _lastStatusMessage = 'The Toll App is active';

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
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showActiveNotification({String? body}) async {
    final String message = body ?? _lastStatusMessage;
    _lastStatusMessage = message;

    await _plugin.show(
      _notificationId,
      'Toll Cam Finder',
      message,
      _notificationDetails,
    );
    _isNotificationVisible = true;
  }

  Future<void> cancelActiveNotification() async {
    _isNotificationVisible = false;
    await _plugin.cancel(_notificationId);
  }

  Future<void> updateStatus(String body, {String? title}) async {
    _lastStatusMessage = body;
    if (!_isNotificationVisible) {
      return;
    }

    await _plugin.show(
      _notificationId,
      title ?? 'Toll Cam Finder',
      body,
      _notificationDetails,
    );
  }
}
