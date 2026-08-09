import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_status.dart';
import '../../domain/entities/admin_user_summary.dart';
import '../providers/admin_providers.dart';
import 'admin_user_detail_screen.dart';

/// Step 1 of the Admin Users section: search + list only.
/// Actions (ban/suspend/verify/role change) are a separate follow-up step.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _queryController = TextEditingController();
  AccountStatus? _statusFilter;

  bool _loading = false;
  String? _error;
  List<AdminUserSummary> _results = const [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _queryController.text.trim();
      final results = await ref.read(adminRepositoryProvider).searchUsers(
            query: query.isEmpty ? null : query,
            status: _statusFilter,
            limit: 50,
          );
      if (!mounted) return;
      setState(() {
        _results = results;
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
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    hintText: 'Search by username, name, or user ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _queryController.clear();
                              _search();
                            },
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AccountStatus?>(
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status filter',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<AccountStatus?>(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          ...AccountStatus.values.map(
                            (s) => DropdownMenuItem<AccountStatus?>(
                              value: s,
                              child: Text(s.wireName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _statusFilter = value);
                          _search();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loading ? null : _search,
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
              OutlinedButton(onPressed: _search, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No users found'));
    }
    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _UserTile(user: _results[index]),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AdminUserSummary user;

  static String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null
            ? Text(_initial(user.displayName ?? user.username ?? '?'))
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName ?? user.username ?? user.userId,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: Colors.blue),
          ],
        ],
      ),
      subtitle: Text(
        '@${user.username ?? '—'} · ${user.role.wireName}',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _StatusChip(status: user.status),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminUserDetailScreen(userId: user.userId),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AccountStatus status;

  Color _colorFor(AccountStatus status) {
    switch (status) {
      case AccountStatus.active:
        return Colors.green;
      case AccountStatus.disabled:
        return Colors.grey;
      case AccountStatus.suspended:
        return Colors.orange;
      case AccountStatus.banned:
        return Colors.red;
      case AccountStatus.deleted:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        status.wireName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
