import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../contacts/presentation/providers/contacts_providers.dart';

/// The Home tab: a real welcome/dashboard screen, distinct from the calls
/// screen. Kept intentionally light in this batch — this is the shell
/// entry point that later phases (Chat previews, notifications digest,
/// etc.) will build on without needing a rewrite.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final contactsAsync = ref.watch(contactsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BAJREN'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contactsListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبًا 👋',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName ?? user?.uid ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            contactsAsync.when(
              data: (contacts) => _SummaryCard(
                icon: Icons.contacts_outlined,
                label: 'جهات الاتصال',
                value: '${contacts.length}',
              ),
              loading: () => const _SummaryCard(
                icon: Icons.contacts_outlined,
                label: 'جهات الاتصال',
                value: '—',
              ),
              error: (_, __) => const _SummaryCard(
                icon: Icons.contacts_outlined,
                label: 'جهات الاتصال',
                value: '—',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
