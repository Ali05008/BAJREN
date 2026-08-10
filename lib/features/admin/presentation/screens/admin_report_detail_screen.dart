import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_permission.dart';
import '../../domain/entities/moderation_report.dart';
import '../providers/admin_providers.dart';

/// Shows one report's full details and lets staff with MANAGE_REPORTS
/// change its status. Backend independently re-checks the permission on
/// every call — this screen only hides buttons for UX.
class AdminReportDetailScreen extends ConsumerStatefulWidget {
  const AdminReportDetailScreen({super.key, required this.report});

  final ModerationReport report;

  @override
  ConsumerState<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState
    extends ConsumerState<AdminReportDetailScreen> {
  late ModerationReport _report;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _changeStatus(ReportStatus target) async {
    if (target == _report.status) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set report status to ${target.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).updateReportStatus(
            reportId: _report.id,
            status: target,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _report = ModerationReport(
          id: _report.id,
          reporterId: _report.reporterId,
          reportedUserId: _report.reportedUserId,
          reportedContentId: _report.reportedContentId,
          reason: _report.reason,
          description: _report.description,
          callId: _report.callId,
          status: target,
          createdAt: _report.createdAt,
          resolvedAt: _report.resolvedAt,
          resolverId: _report.resolverId,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${target.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Report',
            rows: [
              _row('Reason', ReportReasonX.fromWire(_report.reason)?.label ?? _report.reason),
              if (_report.description != null && _report.description!.isNotEmpty)
                _row('Description', _report.description!),
              _row('Status', _report.status.name),
              _row('Created', _report.createdAt.toIso8601String()),
              if (_report.resolvedAt != null)
                _row('Resolved', _report.resolvedAt!.toIso8601String()),
              if (_report.resolverId != null)
                _row('Resolved by', _report.resolverId!),
              if (_report.callId != null && _report.callId!.isNotEmpty)
                _row('Call ID', _report.callId!),
            ],
          ),
          _Section(
            title: 'People',
            rows: [
              _row('Reporter', _report.reporterId),
              _row('Reported user', _report.reportedUserId ?? '—'),
              if (_report.reportedContentId != null)
                _row('Reported content', _report.reportedContentId!),
            ],
          ),
          const SizedBox(height: 8),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final accessAsync = ref.watch(adminAccessProvider);
    return accessAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (access) {
        if (!access.can(AdminPermission.manageReports)) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Your role cannot change report status.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }
        final otherStatuses =
            ReportStatus.values.where((s) => s != _report.status).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actions', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: otherStatuses
                      .map(
                        (s) => ActionChip(
                          label: Text('Mark ${s.name}'),
                          onPressed: _busy ? null : () => _changeStatus(s),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static MapEntry<String, String> _row(String label, String value) =>
      MapEntry(label, value);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        r.key,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Text(r.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
