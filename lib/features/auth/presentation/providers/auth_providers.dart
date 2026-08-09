import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/firebase_ready.dart';
import '../../data/demo_auth_repository.dart';
import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseReady = ref.watch(firebaseReadyProvider);
  if (firebaseReady) {
    return FirebaseAuthRepository();
  }
  final demo = DemoAuthRepository();
  ref.onDispose(demo.dispose);
  return demo;
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull ??
      ref.watch(authRepositoryProvider).currentUser;
});
