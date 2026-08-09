import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options loaded from compile-time defines (no secrets in git).
///
/// Generate real values with FlutterFire CLI into a **gitignored** file, or pass:
///   --dart-define=FIREBASE_API_KEY=...
///   --dart-define=FIREBASE_APP_ID=...
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
///   --dart-define=FIREBASE_PROJECT_ID=...
///   --dart-define=FIREBASE_STORAGE_BUCKET=...
///
/// For Android, prefer google-services.json (gitignored) via the native plugin.
/// This Dart options object is still required for Firebase.initializeApp().
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket:
        String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: ''),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket:
        String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.bajren.bajren',
    ),
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: ''),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket:
        String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
  );

  static bool get isConfigured {
    final o = currentPlatform;
    return o.apiKey.isNotEmpty &&
        o.appId.isNotEmpty &&
        o.projectId.isNotEmpty &&
        o.messagingSenderId.isNotEmpty;
  }
}
