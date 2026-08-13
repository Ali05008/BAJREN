import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/firebase_privacy_repository.dart';
import '../../domain/privacy_repository.dart';

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return FirebasePrivacyRepository();
});

final allowContactByProvider = StreamProvider<ContactPermission>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  final repo = ref.watch(privacyRepositoryProvider);
  return repo.watchAllowContactBy(user.uid);
});
