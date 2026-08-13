import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_permission.dart';
import '../../domain/entities/admin_user_summary.dart';
import '../../domain/entities/user_role.dart';
import '../providers/admin_providers.dart';

/// Lists current staff (role != USER) with quick promote/demote actions.
/// Reuses the same adminSearchUsers + setUserRole calls already backing
/// AdminUserDetailScreen's "Change role" action — this screen just filters
/// the results down to staff and surfaces the action inline.
class AdminAdminsScreen extends ConsumerStatefulWidget {
  const AdminAdminsScreen({super.key});

  @override
  ConsumerState<AdminAdminsScreen> createState() => _AdminAdminsScreenState();
}

class _AdminAdminsScreenState extends ConsumerState<AdminAdminsScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<AdminUserSummary> _staff = const [];

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
      final results = await ref
          .read(adminRepositoryProvider)
          .searchUsers(limit: 200);
      if (!mounted) return;
      setState(() {
        _staff = results.where((u) => u.role != UserRole.user).toList()
          ..sort((a, b) => b.role.rank.compareTo(a.role.rank));
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

  Future<void> _changeRole(AdminUserSummary user, UserRole newRole) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserRole(userId: user.userId, role: newRole);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحديث الرتبة: $e')),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(adminAccessProvider);
    final canManage =
        accessAsync.asData?.value.can(AdminPermission.manageRoles) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأدمنز'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(canManage),
    );
  }

  Widget _buildBody(bool canManage) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('تعذّر تحميل القائمة: $_error'));
    }
    if (_staff.isEmpty) {
      return const Center(child: Text('لا يوجد أدمنز حاليًا.'));
    }
    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView.separated(
            itemCount: _staff.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = _staff[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          (user.displayName ?? user.username ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                        )
                      : null,
                ),
                title: Text(user.displayName ?? user.username ?? user.userId),
                subtitle: Text(user.role.wireName),
                trailing: canManage
                    ? PopupMenuButton<UserRole>(
                        onSelected: (role) => _changeRole(user, role),
                        itemBuilder: (context) => UserRole.values
                            .map(
                              (r) => PopupMenuItem(
                                value: r,
                                enabled: r != user.role,
                                child: Text(
                                  r == UserRole.user
                                      ? 'تنزيل إلى مستخدم عادي'
                                      : 'تعيين كـ ${r.wireName}',
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
