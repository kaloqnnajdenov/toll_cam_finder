import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/services/background_notification_service.dart';

class LifecycleObserver extends StatefulWidget {
  const LifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  State<LifecycleObserver> createState() => _LifecycleObserverState();
}

class _LifecycleObserverState extends State<LifecycleObserver>
    with WidgetsBindingObserver {
  BackgroundNotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationService ??=
        Provider.of<BackgroundNotificationService>(context, listen: false);
    _notificationService?.cancelActiveNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService?.cancelActiveNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _notificationService?.showActiveNotification();
        break;
      case AppLifecycleState.resumed:
        _notificationService?.cancelActiveNotification();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
