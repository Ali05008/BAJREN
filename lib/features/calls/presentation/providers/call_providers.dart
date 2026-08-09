import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/call_repository_impl.dart';
import '../../data/signaling/firebase_signaling_service.dart';
import '../../data/signaling/in_memory_signaling_service.dart';
import '../../data/signaling/signaling_session.dart';
import '../../data/webrtc/default_ice_server_provider.dart';
import '../../data/webrtc/ice_config.dart';
import '../../data/webrtc/secure_ice_server_provider.dart';
import '../../data/webrtc/webrtc_call_engine.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/services/call_engine.dart';
import '../../domain/services/ice_server_provider.dart';
import '../../domain/services/signaling_service.dart';
import '../../../../core/di/firebase_ready.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const _forceFirebaseSignaling = bool.fromEnvironment(
  'USE_FIREBASE_SIGNALING',
  defaultValue: false,
);

final iceConfigProvider = Provider<IceConfig>((ref) {
  return IceConfig.fromEnvironment();
});

final turnAuthTokenProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    return ref.read(authRepositoryProvider).getIdToken();
  };
});

final iceServerProvider = Provider<IceServerProvider>((ref) {
  final config = ref.watch(iceConfigProvider);
  if (config.turnCredentialsUrl != null &&
      config.turnCredentialsUrl!.isNotEmpty) {
    final p = SecureIceServerProvider(
      config: config,
      authTokenProvider: ref.watch(turnAuthTokenProvider),
    );
    ref.onDispose(p.dispose);
    return p;
  }
  return DefaultIceServerProvider(config: config);
});

final signalingServiceProvider = Provider<SignalingService>((ref) {
  final firebaseReady = ref.watch(firebaseReadyProvider);
  final useFirebase = firebaseReady || _forceFirebaseSignaling;

  if (useFirebase) {
    final svc = FirebaseSignalingService();
    ref.onDispose(svc.dispose);
    return svc;
  }
  final svc = InMemorySignalingService();
  ref.onDispose(svc.dispose);
  return svc;
});

final callEngineProvider = Provider<CallEngine>((ref) {
  final engine = WebRtcCallEngine(
    iceServerProvider: ref.watch(iceServerProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final callRepositoryProvider = Provider<CallRepository>((ref) {
  final repo = CallRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

final signalingSessionProvider = Provider<SignalingSession>((ref) {
  final session = SignalingSession(
    signaling: ref.watch(signalingServiceProvider),
    engine: ref.watch(callEngineProvider),
  );
  ref.onDispose(session.dispose);
  return session;
});

/// Starts SignalingSession when a user is authenticated.
final signalingBootstrapProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  final session = ref.watch(signalingSessionProvider);
  if (user == null) {
    await session.stop();
    return;
  }
  await session.start(user.uid);
});
