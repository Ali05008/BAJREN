/// Backend-authoritative roles. Never set from the client alone.
enum UserRole {
  user,
  moderator,
  admin,
  superAdmin,
}

extension UserRoleX on UserRole {
  String get wireName {
    switch (this) {
      case UserRole.user:
        return 'USER';
      case UserRole.moderator:
        return 'MODERATOR';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
    }
  }

  static UserRole fromWire(String? value) {
    switch ((value ?? 'USER').toUpperCase()) {
      case 'MODERATOR':
        return UserRole.moderator;
      case 'ADMIN':
        return UserRole.admin;
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }

  int get rank {
    switch (this) {
      case UserRole.user:
        return 0;
      case UserRole.moderator:
        return 1;
      case UserRole.admin:
        return 2;
      case UserRole.superAdmin:
        return 3;
    }
  }
}
