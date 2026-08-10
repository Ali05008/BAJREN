import 'package:bajren/features/admin/domain/entities/account_status.dart';
import 'package:bajren/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:bajren/features/admin/domain/entities/admin_user_summary.dart';
import 'package:bajren/features/admin/domain/entities/audit_log_entry.dart';
import 'package:bajren/features/admin/domain/entities/moderation_report.dart';
import 'package:bajren/features/admin/domain/entities/user_role.dart';
import 'package:bajren/features/admin/domain/repositories/admin_repository.dart';
import 'package:bajren/features/admin/domain/services/admin_access.dart';
import 'package:bajren/features/admin/presentation/providers/admin_providers.dart';
import 'package:bajren/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake — only listReports/updateReportStatus matter for this
/// screen; everything else throws if accidentally called.
class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({this.reports = const [], this.throwOnList = false});

  final List<ModerationReport> reports;
  final bool throwOnList;
  ReportStatus? lastUpdatedStatus;

  @override
  Future<List<ModerationReport>> listReports({
    ReportStatus? status,
    int limit = 50,
  }) async {
    if (throwOnList) {
      throw Exception('backend unavailable');
    }
    if (status == null) return reports;
    return reports.where((r) => r.status == status).toList();
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    lastUpdatedStatus = status;
  }

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

ModerationReport _report({
  String id = 'r1',
  ReportStatus status = ReportStatus.open,
  String reason = 'HARASSMENT_ABUSE',
}) {
  return ModerationReport(
    id: id,
    reporterId: 'reporter-uid',
    reportedUserId: 'target-uid',
    reason: reason,
    description: 'Kept sending abusive messages.',
    callId: 'call-123',
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap({
  required AdminRepository repository,
  UserRole role = UserRole.admin,
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repository),
      adminAccessProvider.overrideWith(
        (ref) async => AdminAccess.fromRole(role),
      ),
    ],
    child: const MaterialApp(home: AdminReportsScreen()),
  );
}

void main() {
  testWidgets('shows a loading indicator while fetching reports', (tester) async {
    final repo = _FakeAdminRepository(reports: [_report()]);
    await tester.pumpWidget(_wrap(repository: repo));
    // Before settling, the loading state should be visible.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows report reason label and status once loaded', (tester) async {
    final repo = _FakeAdminRepository(reports: [_report()]);
    await tester.pumpWidget(_wrap(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('إساءة أو مضايقة'), findsOneWidget);
    expect(find.textContaining('reporter-uid'), findsOneWidget);
    expect(find.text('open'), findsWidgets);
  });

  testWidgets('shows empty state when there are no reports', (tester) async {
    final repo = _FakeAdminRepository(reports: const []);
    await tester.pumpWidget(_wrap(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No reports'), findsOneWidget);
  });

  testWidgets('shows an error state with a retry button on failure', (tester) async {
    final repo = _FakeAdminRepository(throwOnList: true);
    await tester.pumpWidget(_wrap(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('local search filters the already-loaded reports', (tester) async {
    final repo = _FakeAdminRepository(
      reports: [
        _report(id: 'r1', reason: 'HARASSMENT_ABUSE'),
        _report(id: 'r2', reason: 'FRAUD_SCAM'),
      ],
    );
    await tester.pumpWidget(_wrap(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('إساءة أو مضايقة'), findsOneWidget);
    expect(find.text('احتيال أو خداع'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'FRAUD');
    await tester.pumpAndSettle();

    expect(find.text('احتيال أو خداع'), findsOneWidget);
    expect(find.text('إساءة أو مضايقة'), findsNothing);
  });

  testWidgets('renders correctly regardless of role (the shell tile gates access, not this screen)',
      (tester) async {
    final repo = _FakeAdminRepository(reports: [_report()]);
    await tester.pumpWidget(_wrap(repository: repo, role: UserRole.moderator));
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsOneWidget);
  });
}
