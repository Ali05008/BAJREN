import '../../domain/services/ice_server_provider.dart';
import 'ice_config.dart';

/// STUN-only. Safe for demo and CI. No secrets, no network.
class DefaultIceServerProvider implements IceServerProvider {
  DefaultIceServerProvider({IceConfig? config})
      : _config = config ?? const IceConfig();

  final IceConfig _config;

  @override
  Future<List<Map<String, dynamic>>> getIceServers() async {
    return [
      {'urls': List<String>.from(_config.stunUrls)},
    ];
  }

  @override
  Future<void> invalidateCache() async {}
}
