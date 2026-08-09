import '../entities/account_status.dart';
import '../entities/admin_dashboard_stats.dart';
import '../entities/admin_user_summary.dart';
import '../entities/audit_log_entry.dart';
import '../entities/moderation_report.dart';
import '../entities/user_role.dart';

/// All mutating methods must hit Backend (Callable Functions / Admin API).
/// The Flutter client never writes role/status directly to protected paths.
abstract class AdminRepository {
  Future<AdminDashboardStats> fetchDashboardStats();

  Future<List<AdminUserSummary>> searchUsers({
    String? query,
    AccountStatus? status,
    int limit = 50,
  });

  Future<AdminUserSummary?> getUser(String userId);

  Future<void> setAccountStatus({
    required String userId,
    required AccountStatus status,
    String? reason,
    DateTime? suspendedUntil,
  });

  Future<void> setUserRole({
    required String userId,
    required UserRole role,
  });

  Future<void> setVerified({
    required String userId,
    required bool verified,
  });

  Future<List<ModerationReport>> listReports({
    ReportStatus? status,
    int limit = 50,
  });

  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
  });

  Future<List<AuditLogEntry>> listAuditLogs({int limit = 100});
}
