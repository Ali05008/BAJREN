import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import '../../domain/services/ice_server_provider.dart';

class PeerConnectionFactory {
  PeerConnectionFactory({
    required IceServerProvider iceServerProvider,
    Logger? logger,
  })  : _ice = iceServerProvider,
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final IceServerProvider _ice;
  final Logger _log;

  static const _extras = <String, dynamic>{
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
  };

  Future<RTCPeerConnection> create({Map<String, dynamic>? extra}) async {
    final iceServers = await _ice.getIceServers();
    final config = <String, dynamic>{
      'iceServers': iceServers,
      ..._extras,
      if (extra != null) ...extra,
    };
    _log.d('PeerConnection iceServer groups: ${iceServers.length}');
    return createPeerConnection(config);
  }
}
