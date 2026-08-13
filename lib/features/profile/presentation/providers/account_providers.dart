import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Live profile (username, email, displayName) for the signed-in user.
/// Emits nothing meaningful while signed out — the Account screen is only
/// reachable while signed in, so callers can assume a non-null uid.
final accountProfileProvider = StreamProvider<AccountProfile?>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(accountRepositoryProvider).watchProfile(uid);
});
