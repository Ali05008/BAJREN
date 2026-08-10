import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_dashboard_stats.dart';
import '../providers/admin_providers.dart';

/// Dashboard section: read-only aggregate stats from adminGetDashboardStats.
/// Requires the VIEW_ANALYTICS permission on the backend (ADMIN+); a
/// MODERATOR opening this screen will simply see a permission-denied error.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  AdminDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await ref.read(adminRepositoryProvider).fetchDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
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
    final stats = _stats;
    if (stats == null) {
      return const Center(child: Text('No data'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Users', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Total users',
                value: stats.totalUsers,
                icon: Icons.people_outline,
                color: Colors.blue,
              ),
              _StatCard(
                label: 'Active',
                value: stats.activeUsers,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              _StatCard(
                label: 'Suspended',
                value: stats.suspendedUsers,
                icon: Icons.pause_circle_outline,
                color: Colors.orange,
              ),
              _StatCard(
                label: 'Banned',
                value: stats.bannedUsers,
                icon: Icons.gavel_outlined,
                color: Colors.red,
              ),
              _StatCard(
                label: 'Disabled',
                value: stats.disabledUsers,
                icon: Icons.block_outlined,
                color: Colors.grey,
              ),
              _StatCard(
                label: 'Verified',
                value: stats.verifiedUsers,
                icon: Icons.verified_outlined,
                color: Colors.lightBlue,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Open',
                value: stats.openReports,
                icon: Icons.flag_outlined,
                color: Colors.red,
              ),
              _StatCard(
                label: 'In review',
                value: stats.reportsInReview,
                icon: Icons.hourglass_empty,
                color: Colors.orange,
              ),
              _StatCard(
                label: 'Closed',
                value: stats.closedReports,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ],
          ),
          if (stats.extras.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Other', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats.extras.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key),
                                Text(
                                  '${e.value}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
