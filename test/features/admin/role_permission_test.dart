import 'package:bajren/features/admin/domain/entities/admin_permission.dart';
import 'package:bajren/features/admin/domain/entities/user_role.dart';
import 'package:bajren/features/admin/domain/services/admin_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('USER has no admin permissions', () {
    final access = AdminAccess.fromRole(UserRole.user);
    expect(access.isStaff, isFalse);
    expect(access.can(AdminPermission.viewUsers), isFalse);
  });

  test('MODERATOR can view reports but not manage roles', () {
    final access = AdminAccess.fromRole(UserRole.moderator);
    expect(access.isStaff, isTrue);
    expect(access.can(AdminPermission.viewReports), isTrue);
    expect(access.can(AdminPermission.manageRoles), isFalse);
  });

  test('SUPER_ADMIN has manageAdmins', () {
    final access = AdminAccess.fromRole(UserRole.superAdmin);
    expect(access.can(AdminPermission.manageAdmins), isTrue);
    expect(access.can(AdminPermission.deleteUser), isTrue);
  });

  test('role wire names round-trip', () {
    for (final r in UserRole.values) {
      expect(UserRoleX.fromWire(r.wireName), r);
    }
  });
}
