import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/firebase_ready.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/email_link_deep_link_handler.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/calls/presentation/providers/call_providers.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

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

  if (firebaseReady) {
    final handler = EmailLinkDeepLinkHandler(
      navigatorKey: navigatorKey,
      messengerKey: messengerKey,
    );
    await handler.start();
  }
}

class BajrenApp extends ConsumerWidget {
  const BajrenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    ref.watch(signalingBootstrapProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      title: 'BAJREN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: authAsync.when(
        data: (user) => user == null ? const LoginScreen() : const AppShell(),
        loading: () => const SplashScreen(),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Auth error: $e')),
        ),
      ),
    );
  }
}
