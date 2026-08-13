import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Talks to the native FLAG_SECURE toggle exposed by MainActivity.kt.
/// iOS has no equivalent API to block screenshots/recording outright —
/// Apple only lets apps *detect* a screenshot/recording after the fact —
/// so calls on iOS are silently no-ops here rather than pretending to
/// protect something they can't.
class ScreenCaptureGuardService {
  ScreenCaptureGuardService._();
  static const _channel = MethodChannel('com.bajren.bajren/security');

  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecure');
    } on PlatformException {
      // Best-effort: a failure here shouldn't block the call from
      // proceeding, just means capture protection didn't apply.
    }
  }

  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecure');
    } on PlatformException {
      // Ignore — see enable().
    }
  }
}

/// Wrap any screen with this to block screenshots/screen recording of it
/// on Android (via FLAG_SECURE) for exactly as long as it's on screen.
/// The flag is enabled in [initState] and cleared in [dispose], so
/// leaving this screen (call ended, back button, app backgrounded while
/// on it — dispose still fires when the route is popped) always restores
/// normal capture behavior for the rest of the app.
class ScreenCaptureGuard extends StatefulWidget {
  const ScreenCaptureGuard({super.key, required this.child});

  final Widget child;

  @override
  State<ScreenCaptureGuard> createState() => _ScreenCaptureGuardState();
}

class _ScreenCaptureGuardState extends State<ScreenCaptureGuard> {
  @override
  void initState() {
    super.initState();
    ScreenCaptureGuardService.enable();
  }

  @override
  void dispose() {
    ScreenCaptureGuardService.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
