import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_permission.dart';
import '../../domain/entities/user_role.dart';
import '../providers/admin_providers.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

/// Shell for future Admin dashboard sections.
/// Visibility is UX only — backend enforces permissions.
class AdminShellScreen extends ConsumerWidget {
  const AdminShellScreen({super.key});

  static const sections = [
    'Dashboard',
    'Users',
    'Reports',
    'Moderation',
    'Verification',
    'Storage',
    'Terms & Policies',
    'Admins',
    'Audit Logs',
    'Analytics',
    'Settings',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(adminAccessProvider);

    return accessAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (access) {
        if (!access.isStaff) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin')),
            body: const Center(
              child: Text('Access denied. Staff role required.'),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('Admin (${access.role.wireName})'),
          ),
          body: ListView(
            children: [
              ListTile(
                title: const Text('Permissions (claim-backed)'),
                subtitle: Text(
                  access.permissions.map((p) => p.wireName).join(', '),
                ),
              ),
              const Divider(),
              ...sections.map(
                (s) => ListTile(
                  title: Text(s),
                  subtitle: const Text('Section scaffold — wire to AdminRepository'),
                  onTap: () {
                    if (s == 'Dashboard') {
                      if (!access.can(AdminPermission.viewAnalytics)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Missing VIEW_ANALYTICS')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                      return;
                    }
                    if (s == 'Users') {
                      if (!access.can(AdminPermission.viewUsers)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Missing VIEW_USERS')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen(),
                        ),
                      );
                      return;
                    }
                    if (s == 'Reports') {
                      if (!access.can(AdminPermission.viewReports)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Missing VIEW_REPORTS')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminReportsScreen(),
                        ),
                      );
                      return;
                    }
                    if (s == 'Audit Logs') {
                      if (!access.can(AdminPermission.viewAuditLogs)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Missing VIEW_AUDIT_LOGS')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminAuditLogsScreen(),
                        ),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$s — backend API ready')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
