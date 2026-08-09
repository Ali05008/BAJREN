import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/di/firebase_ready.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/calls/presentation/providers/call_providers.dart';
import 'features/calls/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await bootstrapFirebase();

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const BajrenApp(),
    ),
  );
}

class BajrenApp extends ConsumerWidget {
  const BajrenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    // Keep signaling session in sync with auth
    ref.watch(signalingBootstrapProvider);

    return MaterialApp(
      title: 'BAJREN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: authAsync.when(
        data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Auth error: $e')),
        ),
      ),
    );
  }
}
