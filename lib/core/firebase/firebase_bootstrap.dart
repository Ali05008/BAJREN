import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import 'firebase_options.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Initializes Firebase when options are present.
/// Returns true if Firebase is ready for Auth + Realtime Database.
Future<bool> bootstrapFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return true;
  }

  if (!DefaultFirebaseOptions.isConfigured) {
    _log.w(
      'Firebase options not configured. '
      'Using local/demo mode (InMemory signaling). '
      'Pass FIREBASE_* dart-defines or add platform config files.',
    );
    return false;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _log.i('Firebase initialized');
    return true;
  } catch (e, st) {
    _log.e('Firebase.initializeApp failed', error: e, stackTrace: st);
    return false;
  }
}
