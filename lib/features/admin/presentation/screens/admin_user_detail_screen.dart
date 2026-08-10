import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_status.dart';
import '../../domain/entities/admin_permission.dart';
import '../../domain/entities/admin_user_summary.dart';
import '../../domain/entities/user_role.dart';
import '../providers/admin_providers.dart';

/// User detail view with admin actions (status/role/verify changes).
/// Backend enforces every permission independently — this UI only hides
/// buttons the caller's role can't use, for UX.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _loading = true;
  bool _busy = false;
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

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Done')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _changeStatus(AccountStatus target) async {
    final reasonController = TextEditingController();
    DateTime? suspendedUntil;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Set status to ${target.wireName}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              if (target == AccountStatus.suspended) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    suspendedUntil == null
                        ? 'Suspended until: not set'
                        : 'Suspended until: ${suspendedUntil!.toIso8601String().split('T').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => suspendedUntil = picked);
                    }
                  },
                ),
              ],
            ],
          ),
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
      ),
    );

    if (confirmed != true) return;

    await _runAction(() => ref.read(adminRepositoryProvider).setAccountStatus(
          userId: widget.userId,
          status: target,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
          suspendedUntil: suspendedUntil,
        ));
  }

  Future<void> _toggleVerified(bool verified) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(verified ? 'Verify this user?' : 'Remove verification?'),
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

    await _runAction(() => ref
        .read(adminRepositoryProvider)
        .setVerified(userId: widget.userId, verified: verified));
  }

  Future<void> _changeRole() async {
    UserRole? selected = _user?.role;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Change role'),
          content: DropdownButtonFormField<UserRole>(
            initialValue: selected,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: UserRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.wireName)))
                .toList(),
            onChanged: (v) => setDialogState(() => selected = v),
          ),
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
      ),
    );
    if (confirmed != true || selected == null) return;

    await _runAction(() => ref
        .read(adminRepositoryProvider)
        .setUserRole(userId: widget.userId, role: selected!));
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
        _buildActions(user),
      ],
    );
  }

  Widget _buildActions(AdminUserSummary user) {
    final accessAsync = ref.watch(adminAccessProvider);
    return accessAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (access) {
        final buttons = <Widget>[];

        if (user.isVerified) {
          if (access.can(AdminPermission.revokeVerification)) {
            buttons.add(_actionChip(
              'Unverify',
              Icons.remove_circle_outline,
              () => _toggleVerified(false),
            ));
          }
        } else {
          if (access.can(AdminPermission.verifyUser)) {
            buttons.add(_actionChip(
              'Verify',
              Icons.verified_outlined,
              () => _toggleVerified(true),
            ));
          }
        }

        if (user.status != AccountStatus.active &&
            access.can(AdminPermission.restoreUser)) {
          buttons.add(_actionChip(
            'Activate',
            Icons.check_circle_outline,
            () => _changeStatus(AccountStatus.active),
          ));
        }
        if (user.status != AccountStatus.suspended &&
            access.can(AdminPermission.suspendUser)) {
          buttons.add(_actionChip(
            'Suspend',
            Icons.pause_circle_outline,
            () => _changeStatus(AccountStatus.suspended),
          ));
        }
        if (user.status != AccountStatus.disabled &&
            access.can(AdminPermission.disableUser)) {
          buttons.add(_actionChip(
            'Disable',
            Icons.block_outlined,
            () => _changeStatus(AccountStatus.disabled),
          ));
        }
        if (user.status == AccountStatus.banned) {
          if (access.can(AdminPermission.unbanUser)) {
            buttons.add(_actionChip(
              'Unban',
              Icons.check_circle_outline,
              () => _changeStatus(AccountStatus.active),
            ));
          }
        } else if (access.can(AdminPermission.banUser)) {
          buttons.add(_actionChip(
            'Ban',
            Icons.gavel_outlined,
            () => _changeStatus(AccountStatus.banned),
            destructive: true,
          ));
        }
        if (user.status != AccountStatus.deleted &&
            access.can(AdminPermission.deleteUser)) {
          buttons.add(_actionChip(
            'Delete',
            Icons.delete_outline,
            () => _changeStatus(AccountStatus.deleted),
            destructive: true,
          ));
        }
        if (access.can(AdminPermission.manageRoles)) {
          buttons.add(_actionChip(
            'Change role',
            Icons.badge_outlined,
            _changeRole,
          ));
        }

        if (buttons.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No admin actions available for your role on this account.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

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
                  children: buttons,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionChip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: destructive ? Colors.red : null,
      ),
      label: Text(label, style: destructive ? const TextStyle(color: Colors.red) : null),
      onPressed: _busy ? null : onTap,
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
