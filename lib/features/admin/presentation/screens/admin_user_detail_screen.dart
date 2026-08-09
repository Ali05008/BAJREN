import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_status.dart';
import '../../domain/entities/admin_user_summary.dart';
import '../../domain/entities/user_role.dart';
import '../providers/admin_providers.dart';

/// Read-only user detail view. Admin actions (status/role/verify changes)
/// are a separate follow-up step — this screen only displays data for now.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _loading = true;
  String? _error;
  AdminUserSummary? _user;

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
      final user = await ref.read(adminRepositoryProvider).getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
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
        title: Text(_user?.displayName ?? _user?.username ?? 'User'),
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
    final user = _user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 36)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Identity',
          rows: [
            _row('User ID', user.userId),
            _row('Username', user.username ?? '—'),
            _row('Display name', user.displayName ?? '—'),
            _row('Email', user.emailMasked ?? '—'),
            _row('Phone', user.phoneMasked ?? '—'),
          ],
        ),
        _Section(
          title: 'Role & Status',
          rows: [
            _row('Role', user.role.wireName),
            _row('Status', user.status.wireName),
            _row('Verified', user.isVerified ? 'Yes' : 'No'),
            if (user.statusReason != null)
              _row('Status reason', user.statusReason!),
            if (user.suspendedUntil != null)
              _row('Suspended until', user.suspendedUntil!.toIso8601String()),
          ],
        ),
        _Section(
          title: 'Timestamps',
          rows: [
            _row('Created', user.createdAt.toIso8601String()),
            if (user.updatedAt != null)
              _row('Updated', user.updatedAt!.toIso8601String()),
            if (user.lastSeenAt != null)
              _row('Last seen', user.lastSeenAt!.toIso8601String()),
          ],
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Actions (suspend, ban, verify, change role) are coming in the '
              'next step.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
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
                      width: 130,
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
