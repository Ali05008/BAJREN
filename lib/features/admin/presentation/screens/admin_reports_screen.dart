import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/moderation_report.dart';
import '../providers/admin_providers.dart';
import 'admin_report_detail_screen.dart';

/// Reports list. Backend (`adminListReports`) only supports filtering by
/// status + limit — there is no server-side text search over reports, so
/// the search box filters locally over the page of reports already loaded.
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final _queryController = TextEditingController();
  ReportStatus? _statusFilter;

  bool _loading = true;
  String? _error;
  List<ModerationReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await ref.read(adminRepositoryProvider).listReports(
            status: _statusFilter,
            limit: 100,
          );
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ModerationReport> get _filtered {
    final q = _queryController.text.trim().toLowerCase();
    if (q.isEmpty) return _reports;
    return _reports.where((r) {
      final haystack = [
        r.reporterId,
        r.reportedUserId ?? '',
        r.reason,
        ReportReasonX.fromWire(r.reason)?.label ?? '',
        r.description ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    hintText: 'Search reporter, user, reason, description',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(_queryController.clear),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ReportStatus?>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status filter',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<ReportStatus?>(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          ...ReportStatus.values.map(
                            (s) => DropdownMenuItem<ReportStatus?>(
                              value: s,
                              child: Text(s.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _statusFilter = value);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final filtered = _filtered;
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports'));
    }
    if (filtered.isEmpty) {
      return const Center(child: Text('No reports match your search'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _ReportTile(
          report: filtered[index],
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminReportDetailScreen(report: filtered[index]),
              ),
            );
            _load();
          },
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.onTap});

  final ModerationReport report;
  final VoidCallback onTap;

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return Colors.red;
      case ReportStatus.inReview:
        return Colors.orange;
      case ReportStatus.closed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasonLabel = ReportReasonX.fromWire(report.reason)?.label ?? report.reason;
    final color = _statusColor(report.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(31),
        child: Icon(Icons.flag_outlined, color: color, size: 20),
      ),
      title: Text(reasonLabel, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'Reporter: ${report.reporterId}\nTarget: ${report.reportedUserId ?? '—'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(102)),
            ),
            child: Text(
              report.status.name,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.createdAt.toIso8601String().split('T').first,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
