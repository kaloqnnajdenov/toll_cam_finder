package com.kalka.toll_cam_finder

import android.app.Activity
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.systemchannels.PlatformChannel
import io.flutter.plugin.platform.PlatformPlugin

/**
 * Wraps Flutter's [PlatformPlugin] so we can filter deprecated system chrome calls on Android 15+.
 *
 * Android 15 marks Window#setStatusBarColor, setNavigationBarColor and setNavigationBarDividerColor
 * as deprecated. We can't change the engine implementation directly, so we intercept the platform
 * channel messages and strip the color fields before they reach the default plugin on API 35+.
 */
class EdgeToEdgePlatformPlugin(
    activity: Activity,
    platformChannel: PlatformChannel,
    delegate: PlatformPlugin.PlatformPluginDelegate?,
) : PlatformPlugin(activity, platformChannel, delegate) {

    init {
        installSanitizingHandler()
    }

    private fun installSanitizingHandler() {
        runCatching {
            val channelField = PlatformPlugin::class.java.getDeclaredField("platformChannel")
            val handlerField = PlatformPlugin::class.java.getDeclaredField("mPlatformMessageHandler")
            channelField.isAccessible = true
            handlerField.isAccessible = true
            val channel = channelField.get(this) as PlatformChannel
            val handler =
                handlerField.get(this) as PlatformChannel.PlatformMessageHandler

            channel.setPlatformMessageHandler(
                SanitizingMessageHandler(handler),
            )
        }.onFailure {
            Log.w(TAG, "Falling back to the default PlatformPlugin handler", it)
        }
    }

    private class SanitizingMessageHandler(
        private val delegate: PlatformChannel.PlatformMessageHandler,
    ) : PlatformChannel.PlatformMessageHandler {

        override fun playSystemSound(soundType: PlatformChannel.SoundType) {
            delegate.playSystemSound(soundType)
        }

        override fun vibrateHapticFeedback(feedbackType: PlatformChannel.HapticFeedbackType) {
            delegate.vibrateHapticFeedback(feedbackType)
        }

        override fun setPreferredOrientations(androidOrientation: Int) {
            delegate.setPreferredOrientations(androidOrientation)
        }

        override fun setApplicationSwitcherDescription(
            description: PlatformChannel.AppSwitcherDescription,
        ) {
            delegate.setApplicationSwitcherDescription(description)
        }

        override fun showSystemOverlays(overlays: List<PlatformChannel.SystemUiOverlay>) {
            delegate.showSystemOverlays(overlays)
        }

        override fun showSystemUiMode(mode: PlatformChannel.SystemUiMode) {
            delegate.showSystemUiMode(mode)
        }

        override fun setSystemUiChangeListener() {
            delegate.setSystemUiChangeListener()
        }

        override fun restoreSystemUiOverlays() {
            delegate.restoreSystemUiOverlays()
        }

        override fun setSystemUiOverlayStyle(
            systemUiOverlayStyle: PlatformChannel.SystemChromeStyle,
        ) {
            delegate.setSystemUiOverlayStyle(sanitize(systemUiOverlayStyle))
        }

        override fun setFrameworkHandlesBack(frameworkHandlesBack: Boolean) {
            delegate.setFrameworkHandlesBack(frameworkHandlesBack)
        }

        override fun popSystemNavigator() {
            delegate.popSystemNavigator()
        }

        override fun getClipboardData(
            format: PlatformChannel.ClipboardContentFormat?,
        ): CharSequence? = delegate.getClipboardData(format)

        override fun setClipboardData(text: String) {
            delegate.setClipboardData(text)
        }

        override fun clipboardHasStrings(): Boolean = delegate.clipboardHasStrings()

        override fun share(text: String) {
            delegate.share(text)
        }

        private fun sanitize(
            style: PlatformChannel.SystemChromeStyle,
        ): PlatformChannel.SystemChromeStyle {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) {
                return style
            }
            if (style.statusBarColor == null &&
                style.systemNavigationBarColor == null &&
                style.systemNavigationBarDividerColor == null) {
                return style
            }
            return PlatformChannel.SystemChromeStyle(
                /* statusBarColor = */ null,
                /* statusBarIconBrightness = */ style.statusBarIconBrightness,
                /* systemStatusBarContrastEnforced = */ style.systemStatusBarContrastEnforced,
                /* systemNavigationBarColor = */ null,
                /* systemNavigationBarIconBrightness = */ style.systemNavigationBarIconBrightness,
                /* systemNavigationBarDividerColor = */ null,
                /* systemNavigationBarContrastEnforced = */ style.systemNavigationBarContrastEnforced,
            )
        }
    }

    companion object {
        private const val TAG = "EdgeToEdgePlatform"
    }
}
