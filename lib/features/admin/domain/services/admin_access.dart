import '../entities/admin_permission.dart';
import '../entities/user_role.dart';

/// Client-side gate for UI only. Real enforcement is Backend + Security Rules.
class AdminAccess {
  final UserRole role;
  final Set<AdminPermission> permissions;

  const AdminAccess({
    required this.role,
    required this.permissions,
  });

  factory AdminAccess.fromRole(UserRole role) {
    return AdminAccess(
      role: role,
      permissions: RolePermissionCatalog.forRole(role),
    );
  }

  bool get isStaff => role.rank >= UserRole.moderator.rank;

  bool can(AdminPermission permission) => permissions.contains(permission);
}
