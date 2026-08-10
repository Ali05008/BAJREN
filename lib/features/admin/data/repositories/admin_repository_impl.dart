import 'package:cloud_functions/cloud_functions.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/account_status.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_user_summary.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/moderation_report.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/admin_repository.dart';

/// Calls HTTPS Callable Functions. All privilege checks happen server-side.
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({
    FirebaseFunctions? functions,
    Logger? logger,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final FirebaseFunctions _functions;
  final Logger _log;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final raw = result.data;
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {};
    } on FirebaseFunctionsException catch (e) {
      _log.w('Admin callable $name failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  @override
  Future<AdminDashboardStats> fetchDashboardStats() async {
    final data = await _call('adminGetDashboardStats', {});
    return AdminDashboardStats(
      totalUsers: (data['totalUsers'] as num?)?.toInt() ?? 0,
      activeUsers: (data['activeUsers'] as num?)?.toInt() ?? 0,
      disabledUsers: (data['disabledUsers'] as num?)?.toInt() ?? 0,
      suspendedUsers: (data['suspendedUsers'] as num?)?.toInt() ?? 0,
      bannedUsers: (data['bannedUsers'] as num?)?.toInt() ?? 0,
      verifiedUsers: (data['verifiedUsers'] as num?)?.toInt() ?? 0,
      openReports: (data['openReports'] as num?)?.toInt() ?? 0,
      reportsInReview: (data['reportsInReview'] as num?)?.toInt() ?? 0,
      closedReports: (data['closedReports'] as num?)?.toInt() ?? 0,
      extras: Map<String, int>.from(
        (data['extras'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ) ??
            {},
      ),
    );
  }

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String? query,
    AccountStatus? status,
    int limit = 50,
  }) async {
    final data = await _call('adminSearchUsers', {
      if (query != null) 'query': query,
      if (status != null) 'status': status.wireName,
      'limit': limit,
    });
    final list = (data['users'] as List?) ?? [];
    return list
        .map((e) => _parseUser(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<AdminUserSummary?> getUser(String userId) async {
    final data = await _call('adminGetUser', {'userId': userId});
    final user = data['user'];
    if (user is! Map) return null;
    return _parseUser(Map<String, dynamic>.from(user));
  }

  @override
  Future<void> setAccountStatus({
    required String userId,
    required AccountStatus status,
    String? reason,
    DateTime? suspendedUntil,
  }) async {
    await _call('adminSetAccountStatus', {
      'userId': userId,
      'status': status.wireName,
      if (reason != null) 'reason': reason,
      if (suspendedUntil != null)
        'suspendedUntil': suspendedUntil.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> setUserRole({
    required String userId,
    required UserRole role,
  }) async {
    await _call('adminSetUserRole', {
      'userId': userId,
      'role': role.wireName,
    });
  }

  @override
  Future<void> setVerified({
    required String userId,
    required bool verified,
  }) async {
    await _call('adminSetVerified', {
      'userId': userId,
      'verified': verified,
    });
  }

  @override
  Future<List<ModerationReport>> listReports({
    ReportStatus? status,
    int limit = 50,
  }) async {
    final data = await _call('adminListReports', {
      if (status != null) 'status': status.name,
      'limit': limit,
    });
    final list = (data['reports'] as List?) ?? [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ModerationReport(
        id: m['id'] as String? ?? '',
        reporterId: m['reporterId'] as String? ?? '',
        reportedUserId: m['reportedUserId'] as String?,
        reportedContentId: m['reportedContentId'] as String?,
        reason: m['reason'] as String? ?? '',
        description: m['description'] as String?,
        callId: m['callId'] as String?,
        status: ReportStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => ReportStatus.open,
        ),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        resolvedAt: m['resolvedAt'] != null
            ? DateTime.tryParse(m['resolvedAt'] as String)
            : null,
        resolverId: m['resolverId'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    await _call('adminUpdateReportStatus', {
      'reportId': reportId,
      'status': status.name,
    });
  }

  @override
  Future<List<AuditLogEntry>> listAuditLogs({int limit = 100}) async {
    final data = await _call('adminListAuditLogs', {'limit': limit});
    final list = (data['logs'] as List?) ?? [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return AuditLogEntry(
        id: m['id'] as String? ?? '',
        actorId: m['actorId'] as String? ?? '',
        action: m['action'] as String? ?? '',
        targetUserId: m['targetUserId'] as String?,
        metadata: Map<String, dynamic>.from(
          (m['metadata'] as Map?) ?? {},
        ),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  AdminUserSummary _parseUser(Map<String, dynamic> m) {
    return AdminUserSummary(
      userId: m['userId'] as String? ?? m['uid'] as String? ?? '',
      username: m['username'] as String?,
      displayName: m['displayName'] as String?,
      photoUrl: m['photoUrl'] as String?,
      phoneMasked: m['phoneMasked'] as String?,
      emailMasked: m['emailMasked'] as String?,
      status: AccountStatusX.fromWire(m['status'] as String?),
      role: UserRoleX.fromWire(m['role'] as String?),
      isVerified: m['isVerified'] as bool? ?? false,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: m['updatedAt'] != null
          ? DateTime.tryParse(m['updatedAt'] as String)
          : null,
      lastSeenAt: m['lastSeenAt'] != null
          ? DateTime.tryParse(m['lastSeenAt'] as String)
          : null,
      suspendedUntil: m['suspendedUntil'] != null
          ? DateTime.tryParse(m['suspendedUntil'] as String)
          : null,
      statusReason: m['statusReason'] as String?,
    );
  }
}
