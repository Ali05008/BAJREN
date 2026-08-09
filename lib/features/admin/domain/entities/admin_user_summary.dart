import 'package:equatable/equatable.dart';

import 'account_status.dart';
import 'user_role.dart';

/// Safe fields only — never passwords, OTP, secrets.
class AdminUserSummary extends Equatable {
  final String userId;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final String? phoneMasked;
  final String? emailMasked;
  final AccountStatus status;
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final DateTime? suspendedUntil;
  final String? statusReason;

  const AdminUserSummary({
    required this.userId,
    this.username,
    this.displayName,
    this.photoUrl,
    this.phoneMasked,
    this.emailMasked,
    required this.status,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
    this.suspendedUntil,
    this.statusReason,
  });

  @override
  List<Object?> get props => [userId, status, role, isVerified];
}
