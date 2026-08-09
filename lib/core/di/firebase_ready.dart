import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Firebase.initializeApp succeeded. Overridden in main().
final firebaseReadyProvider = Provider<bool>((ref) => false);
