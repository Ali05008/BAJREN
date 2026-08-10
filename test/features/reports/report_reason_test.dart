import 'package:bajren/features/admin/domain/entities/moderation_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report reason wire names round-trip', () {
    for (final r in ReportReason.values) {
      expect(ReportReasonX.fromWire(r.wireName), r);
    }
  });

  test('report reason wire names match backend REPORT_REASONS exactly', () {
    // Mirrors functions/src/permissions.ts REPORT_REASONS — if this list
    // ever changes, the backend validator must be updated too.
    const expected = {
      'HARASSMENT_ABUSE',
      'INAPPROPRIATE_CONTENT',
      'IMPERSONATION',
      'FRAUD_SCAM',
      'THREATS',
      'OTHER',
    };
    final actual = ReportReason.values.map((r) => r.wireName).toSet();
    expect(actual, expected);
  });

  test('unknown wire value does not match any reason', () {
    expect(ReportReasonX.fromWire('NOT_A_REAL_REASON'), isNull);
    expect(ReportReasonX.fromWire(null), isNull);
  });

  test('every reason has a non-empty Arabic label', () {
    for (final r in ReportReason.values) {
      expect(r.label, isNotEmpty);
    }
  });

  test('ModerationReport carries an optional description', () {
    final withDescription = ModerationReport(
      id: 'r1',
      reporterId: 'reporter-uid',
      reportedUserId: 'target-uid',
      reason: 'HARASSMENT_ABUSE',
      description: 'Kept sending abusive messages during the call.',
      status: ReportStatus.open,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(withDescription.description, isNotNull);

    final withoutDescription = ModerationReport(
      id: 'r2',
      reporterId: 'reporter-uid',
      reportedUserId: 'target-uid',
      reason: 'OTHER',
      status: ReportStatus.open,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(withoutDescription.description, isNull);
  });
}
