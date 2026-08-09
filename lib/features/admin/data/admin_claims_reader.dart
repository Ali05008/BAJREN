import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entities/admin_permission.dart';
import '../domain/entities/user_role.dart';
import '../domain/services/admin_access.dart';

/// Reads role from Firebase Auth custom claims (set only by Admin SDK).
class AdminClaimsReader {
  AdminClaimsReader({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Force refresh after an admin changes your role server-side.
  Future<AdminAccess> readAccess({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AdminAccess.fromRole(UserRole.user);
    }
    final token = await user.getIdTokenResult(forceRefresh);
    final claims = token.claims ?? {};
    final role = UserRoleX.fromWire(claims['role'] as String?);
    final extra = <AdminPermission>{};
    final rawPerms = claims['permissions'];
    if (rawPerms is List) {
      for (final p in rawPerms) {
        final parsed = AdminPermissionX.fromWire(p.toString());
        if (parsed != null) extra.add(parsed);
      }
    }
    final base = RolePermissionCatalog.forRole(role);
    return AdminAccess(role: role, permissions: {...base, ...extra});
  }
}
