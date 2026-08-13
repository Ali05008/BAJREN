import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// "عام" (General) settings. Two different kinds of rows on purpose:
///   - App version / build number: REAL data, read from the installed
///     package via package_info_plus.
///   - Language / Theme: display-only for now. The app is single-language
///     (Arabic, hardcoded strings — the old l10n scaffolding was removed
///     as unused dead code) and follows the system light/dark setting
///     with no manual override wired up yet. Wiring a real switch for
///     either needs an app-wide settings/locale provider, which is a
///     bigger change than this batch.
class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = _info == null
        ? '...'
        : '${_info!.version} (${_info!.buildNumber})';

    return Scaffold(
      appBar: AppBar(title: const Text('عام')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('اللغة'),
            subtitle: const Text('العربية'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context, 'اللغة'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('المظهر'),
            subtitle: const Text('حسب إعدادات الجهاز'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context, 'المظهر'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('إصدار التطبيق'),
            subtitle: Text(version),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('معرّف الحزمة'),
            subtitle: Text(_info?.packageName ?? '...'),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label — قريبًا')));
  }
}
