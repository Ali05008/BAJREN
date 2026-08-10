import 'package:bajren/features/admin/domain/entities/account_status.dart';
import 'package:bajren/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:bajren/features/admin/domain/entities/admin_user_summary.dart';
import 'package:bajren/features/admin/domain/entities/audit_log_entry.dart';
import 'package:bajren/features/admin/domain/entities/moderation_report.dart';
import 'package:bajren/features/admin/domain/entities/user_role.dart';
import 'package:bajren/features/admin/domain/repositories/admin_repository.dart';
import 'package:bajren/features/admin/domain/services/admin_access.dart';
import 'package:bajren/features/admin/presentation/providers/admin_providers.dart';
import 'package:bajren/features/admin/presentation/screens/admin_report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminRepository implements AdminRepository {
  String? lastUpdatedReportId;
  ReportStatus? lastUpdatedStatus;
  bool throwOnUpdate = false;

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    if (throwOnUpdate) {
      throw Exception('permission-denied: Role MODERATOR lacks permission MANAGE_REPORTS');
    }
    lastUpdatedReportId = reportId;
    lastUpdatedStatus = status;
  }

  @override
  Future<List<ModerationReport>> listReports({
    ReportStatus? status,
    int limit = 50,
  }) =>
      throw UnimplementedError();

  @override
  Future<AdminDashboardStats> fetchDashboardStats() =>
      throw UnimplementedError();

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String? query,
    AccountStatus? status,
    int limit = 50,
  }) =>
      throw UnimplementedError();

  @override
  Future<AdminUserSummary?> getUser(String userId) =>
      throw UnimplementedError();

  @override
  Future<void> setAccountStatus({
    required String userId,
    required AccountStatus status,
    String? reason,
    DateTime? suspendedUntil,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setUserRole({
    required String userId,
    required UserRole role,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setVerified({required String userId, required bool verified}) =>
      throw UnimplementedError();

  @override
  Future<List<AuditLogEntry>> listAuditLogs({int limit = 100}) =>
      throw UnimplementedError();
}

final _report = ModerationReport(
  id: 'report-42',
  reporterId: 'reporter-uid',
  reportedUserId: 'target-uid',
  reason: 'THREATS',
  description: 'Threatened to find me in real life.',
  callId: 'call-789',
  status: ReportStatus.open,
  createdAt: DateTime(2026, 2, 1),
);

Widget _wrap({
  required AdminRepository repository,
  required UserRole role,
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repository),
      adminAccessProvider.overrideWith(
        (ref) async => AdminAccess.fromRole(role),
      ),
    ],
    child: MaterialApp(home: AdminReportDetailScreen(report: _report)),
  );
}

void main() {
  testWidgets('shows all report fields including callId', (tester) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeAdminRepository(), role: UserRole.admin),
    );
    await tester.pumpAndSettle();

    expect(find.text('تهديد'), findsOneWidget); // THREATS reason label
    expect(find.text('Threatened to find me in real life.'), findsOneWidget);
    expect(find.text('reporter-uid'), findsOneWidget);
    expect(find.text('target-uid'), findsOneWidget);
    expect(find.text('call-789'), findsOneWidget);
  });

  testWidgets('ADMIN (has MANAGE_REPORTS) sees status-change actions', (tester) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeAdminRepository(), role: UserRole.admin),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsOneWidget);
    expect(find.textContaining('Mark'), findsWidgets);
  });

  testWidgets('MODERATOR (no MANAGE_REPORTS) sees no status-change actions', (tester) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeAdminRepository(), role: UserRole.moderator),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsNothing);
    expect(
      find.text('Your role cannot change report status.'),
      findsOneWidget,
    );
  });

  testWidgets('confirming a status change calls updateReportStatus with the new status',
      (tester) async {
    final repo = _FakeAdminRepository();
    await tester.pumpWidget(_wrap(repository: repo, role: UserRole.admin));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Mark inReview'));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear.
    expect(find.text('Confirm'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdatedReportId, 'report-42');
    expect(repo.lastUpdatedStatus, ReportStatus.inReview);
    expect(find.text('Status updated to inReview'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation dialog does not call updateReportStatus',
      (tester) async {
    final repo = _FakeAdminRepository();
    await tester.pumpWidget(_wrap(repository: repo, role: UserRole.admin));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Mark closed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdatedStatus, isNull);
  });

  testWidgets('backend rejection shows a clear error message', (tester) async {
    final repo = _FakeAdminRepository()..throwOnUpdate = true;
    await tester.pumpWidget(_wrap(repository: repo, role: UserRole.admin));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Mark closed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed:'), findsOneWidget);
  });
}
