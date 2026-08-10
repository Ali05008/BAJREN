import 'package:cloud_functions/cloud_functions.dart';

import '../../admin/domain/entities/moderation_report.dart';

/// Submits user-generated reports via the `submitReport` Cloud Function.
/// The server sets `reporterId` from the authenticated caller — it can
/// never be forged by the client. RTDB rules deny direct writes to
/// `reports/` entirely; this callable is the only way to create one.
class ReportRepository {
  ReportRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Throws [FirebaseFunctionsException] on failure (e.g. `already-exists`
  /// for a recent duplicate report, `invalid-argument` for bad input).
  Future<String?> submitReport({
    required String targetUserId,
    required ReportReason reason,
    String? description,
    String? callId,
  }) async {
    final result = await _functions.httpsCallable('submitReport').call<dynamic>({
      'targetUserId': targetUserId,
      'reason': reason.wireName,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (callId != null && callId.trim().isNotEmpty) 'callId': callId,
    });
    final data = result.data;
    if (data is Map && data['reportId'] is String) {
      return data['reportId'] as String;
    }
    return null;
  }
}
