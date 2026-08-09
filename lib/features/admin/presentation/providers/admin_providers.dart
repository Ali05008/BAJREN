import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/firebase_ready.dart';
import '../../data/admin_claims_reader.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/services/admin_access.dart';

final adminClaimsReaderProvider = Provider<AdminClaimsReader>((ref) {
  return AdminClaimsReader();
});

final adminAccessProvider = FutureProvider<AdminAccess>((ref) async {
  final firebaseReady = ref.watch(firebaseReadyProvider);
  if (!firebaseReady) {
    return AdminAccess.fromRole(UserRole.user);
  }
  return ref.watch(adminClaimsReaderProvider).readAccess(forceRefresh: true);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl();
});
