import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let notificationChannelName = "com.kalka.toll_cam_finder/notifications"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      configureNotificationChannel(with: controller)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureNotificationChannel(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: notificationChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "areNotificationsEnabled":
        self?.areNotificationsEnabled(result: result)
      case "requestPermission":
        self?.requestNotificationPermission(result: result)
      case "openNotificationSettings":
        self?.openNotificationSettings(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func areNotificationsEnabled(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let enabled: Bool
      switch settings.authorizationStatus {
      case .authorized, .provisional, .ephemeral:
        enabled = true
      default:
        enabled = false
      }

      DispatchQueue.main.async {
        result(enabled)
      }
    }
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }

  private func openNotificationSettings(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(nil)
        return
      }
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      result(nil)
    }
  }
}
