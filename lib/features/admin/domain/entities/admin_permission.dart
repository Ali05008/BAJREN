import 'user_role.dart';

/// Fine-grained permissions. Enforced on Backend / Security Rules / Admin SDK.
enum AdminPermission {
  viewUsers,
  viewUserDetails,
  disableUser,
  restoreUser,
  suspendUser,
  banUser,
  unbanUser,
  deleteUser,
  viewReports,
  manageReports,
  viewMedia,
  removeMedia,
  verifyUser,
  revokeVerification,
  manageRoles,
  manageAdmins,
  viewAuditLogs,
  manageTerms,
  manageStorage,
  viewAnalytics,
  manageSettings,
}

extension AdminPermissionX on AdminPermission {
  String get wireName {
    switch (this) {
      case AdminPermission.viewUsers:
        return 'VIEW_USERS';
      case AdminPermission.viewUserDetails:
        return 'VIEW_USER_DETAILS';
      case AdminPermission.disableUser:
        return 'DISABLE_USER';
      case AdminPermission.restoreUser:
        return 'RESTORE_USER';
      case AdminPermission.suspendUser:
        return 'SUSPEND_USER';
      case AdminPermission.banUser:
        return 'BAN_USER';
      case AdminPermission.unbanUser:
        return 'UNBAN_USER';
      case AdminPermission.deleteUser:
        return 'DELETE_USER';
      case AdminPermission.viewReports:
        return 'VIEW_REPORTS';
      case AdminPermission.manageReports:
        return 'MANAGE_REPORTS';
      case AdminPermission.viewMedia:
        return 'VIEW_MEDIA';
      case AdminPermission.removeMedia:
        return 'REMOVE_MEDIA';
      case AdminPermission.verifyUser:
        return 'VERIFY_USER';
      case AdminPermission.revokeVerification:
        return 'REVOKE_VERIFICATION';
      case AdminPermission.manageRoles:
        return 'MANAGE_ROLES';
      case AdminPermission.manageAdmins:
        return 'MANAGE_ADMINS';
      case AdminPermission.viewAuditLogs:
        return 'VIEW_AUDIT_LOGS';
      case AdminPermission.manageTerms:
        return 'MANAGE_TERMS';
      case AdminPermission.manageStorage:
        return 'MANAGE_STORAGE';
      case AdminPermission.viewAnalytics:
        return 'VIEW_ANALYTICS';
      case AdminPermission.manageSettings:
        return 'MANAGE_SETTINGS';
    }
  }

  static AdminPermission? fromWire(String value) {
    for (final p in AdminPermission.values) {
      if (p.wireName == value) return p;
    }
    return null;
  }
}

/// Default permission sets per role (Backend must mirror this).
class RolePermissionCatalog {
  static const Map<UserRole, Set<AdminPermission>> defaults = {
    UserRole.user: {},
    UserRole.moderator: {
      AdminPermission.viewUsers,
      AdminPermission.viewUserDetails,
      AdminPermission.viewReports,
      AdminPermission.manageReports,
      AdminPermission.viewMedia,
      AdminPermission.removeMedia,
      AdminPermission.suspendUser,
    },
    UserRole.admin: {
      AdminPermission.viewUsers,
      AdminPermission.viewUserDetails,
      AdminPermission.disableUser,
      AdminPermission.restoreUser,
      AdminPermission.suspendUser,
      AdminPermission.banUser,
      AdminPermission.unbanUser,
      AdminPermission.viewReports,
      AdminPermission.manageReports,
      AdminPermission.viewMedia,
      AdminPermission.removeMedia,
      AdminPermission.verifyUser,
      AdminPermission.revokeVerification,
      AdminPermission.viewAuditLogs,
      AdminPermission.viewAnalytics,
      AdminPermission.manageTerms,
      AdminPermission.manageStorage,
    },
    UserRole.superAdmin: {
      // all
      AdminPermission.viewUsers,
      AdminPermission.viewUserDetails,
      AdminPermission.disableUser,
      AdminPermission.restoreUser,
      AdminPermission.suspendUser,
      AdminPermission.banUser,
      AdminPermission.unbanUser,
      AdminPermission.deleteUser,
      AdminPermission.viewReports,
      AdminPermission.manageReports,
      AdminPermission.viewMedia,
      AdminPermission.removeMedia,
      AdminPermission.verifyUser,
      AdminPermission.revokeVerification,
      AdminPermission.manageRoles,
      AdminPermission.manageAdmins,
      AdminPermission.viewAuditLogs,
      AdminPermission.manageTerms,
      AdminPermission.manageStorage,
      AdminPermission.viewAnalytics,
      AdminPermission.manageSettings,
    },
  };

  static Set<AdminPermission> forRole(UserRole role) =>
      Set.unmodifiable(defaults[role] ?? {});
}
