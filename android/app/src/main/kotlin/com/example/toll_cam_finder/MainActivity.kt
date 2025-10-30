package com.kalka.toll_cam_finder

import android.Manifest
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.net.Uri
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val NOTIFICATION_CHANNEL = "com.kalka.toll_cam_finder/notifications"
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001
        private const val FOREGROUND_CHANNEL_ID = "geolocator_channel_01"
        private const val FOREGROUND_NOTIFICATION_ID = 75415
        private const val ACTION_EXIT_APP = "com.kalka.toll_cam_finder.action.EXIT_APP"
    }

    private var pendingNotificationResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL,
        ).setMethodCallHandler(::handleMethodCall)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationAction(intent)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "areNotificationsEnabled" -> result.success(areNotificationsEnabled())
            "requestPermission" -> requestNotificationPermission(result)
            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(null)
            }
            "updateForegroundNotification" -> {
                updateForegroundNotification(
                    title = call.argument("title"),
                    text = call.argument("text"),
                    iconName = call.argument("iconName"),
                    iconType = call.argument("iconType"),
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun areNotificationsEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true
        }
        return NotificationManagerCompat.from(this).areNotificationsEnabled()
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        if (areNotificationsEnabled()) {
            result.success(true)
            return
        }

        if (pendingNotificationResult != null) {
            result.error(
                "PENDING_REQUEST",
                "Another notification permission request is still pending.",
                null,
            )
            return
        }

        pendingNotificationResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    private fun openNotificationSettings() {
        val intent = Intent().apply {
            action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
            startActivity(fallbackIntent)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != NOTIFICATION_PERMISSION_REQUEST_CODE) {
            return
        }

        val pendingResult = pendingNotificationResult
        pendingNotificationResult = null

        if (pendingResult == null) {
            return
        }

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        pendingResult.success(granted)
    }

    private fun updateForegroundNotification(
        title: String?,
        text: String?,
        iconName: String?,
        iconType: String?,
    ) {
        if (title.isNullOrBlank() || text.isNullOrBlank()) {
            return
        }

        val resolvedIconName = iconName ?: "ic_launcher"
        val resolvedIconType = iconType ?: "mipmap"
        val iconId = resources.getIdentifier(resolvedIconName, resolvedIconType, packageName)
        val smallIcon = if (iconId != 0) iconId else applicationInfo.icon

        val builder = NotificationCompat.Builder(applicationContext, FOREGROUND_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(smallIcon)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))

        createLaunchPendingIntent()?.let { builder.setContentIntent(it) }
        builder.addAction(
            smallIcon,
            getString(R.string.notification_exit_action),
            createExitPendingIntent(),
        )

        NotificationManagerCompat.from(applicationContext).notify(
            FOREGROUND_NOTIFICATION_ID,
            builder.build(),
        )
    }

    private fun createLaunchPendingIntent(): PendingIntent? {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        launchIntent.setPackage(null)
        launchIntent.flags =
            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }

        return PendingIntent.getActivity(this, 0, launchIntent, flags)
    }

    private fun createExitPendingIntent(): PendingIntent {
        val exitIntent = Intent(applicationContext, MainActivity::class.java).apply {
            action = ACTION_EXIT_APP
            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }

        return PendingIntent.getActivity(this, 1, exitIntent, flags)
    }

    private fun handleNotificationAction(intent: Intent?) {
        if (intent?.action != ACTION_EXIT_APP) {
            return
        }

        NotificationManagerCompat.from(this).cancel(FOREGROUND_NOTIFICATION_ID)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }

        // Ensure subsequent launches do not immediately re-trigger the exit action.
        intent.action = null
    }
}
