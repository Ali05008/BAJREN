import 'package:bajren/features/calls/data/webrtc/default_ice_server_provider.dart';
import 'package:bajren/features/calls/data/webrtc/ice_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DefaultIceServerProvider returns STUN only', () async {
    final p = DefaultIceServerProvider(config: const IceConfig());
    final servers = await p.getIceServers();
    expect(servers, hasLength(1));
    final urls = servers.first['urls'] as List;
    expect(urls, isNotEmpty);
    expect(urls.first.toString(), startsWith('stun:'));
    expect(servers.first.containsKey('username'), isFalse);
  });

  test('IceConfig.fromEnvironment has null TURN url by default', () {
    final c = IceConfig.fromEnvironment();
    expect(c.turnCredentialsUrl, isNull);
  });
}
