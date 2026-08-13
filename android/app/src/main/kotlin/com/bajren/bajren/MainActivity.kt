package com.bajren.bajren

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Call Privacy: exposes Android's official FLAG_SECURE window flag to
/// Flutter over a MethodChannel. FLAG_SECURE is applied to the whole
/// Activity window (Android has no API to protect just a region of the
/// screen), so the Flutter side is responsible for only calling
/// "enableSecure" while the active-call screen is on top, and
/// "disableSecure" the moment it's left — see
/// lib/core/security/screen_capture_guard.dart.
///
/// With the flag set, the system blocks screenshots, blocks screen
/// recording, and blacks out this window in the recent-apps switcher and
/// in any other app's screen-share/cast output — covering video feeds,
/// remote/local camera previews, and any profile images shown on the
/// call screen, per Android's own guarantee for this flag.
class MainActivity : FlutterActivity() {
    private val channelName = "com.bajren.bajren/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecure" -> {
                        runOnUiThread {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    "disableSecure" -> {
                        runOnUiThread {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
