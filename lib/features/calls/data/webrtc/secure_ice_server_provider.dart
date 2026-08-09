import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../domain/services/ice_server_provider.dart';
import 'ice_config.dart';
import 'turn_credentials.dart';

/// Fetches short-lived TURN credentials from a secure backend.
/// Never logs credential values. Memory-only cache.
class SecureIceServerProvider implements IceServerProvider {
  SecureIceServerProvider({
    required IceConfig config,
    Future<String?> Function()? authTokenProvider,
    http.Client? httpClient,
    Logger? logger,
  })  : _config = config,
        _authTokenProvider = authTokenProvider,
        _http = httpClient ?? http.Client(),
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final IceConfig _config;
  final Future<String?> Function()? _authTokenProvider;
  final http.Client _http;
  final Logger _log;

  TurnCredentials? _cachedTurn;
  Future<TurnCredentials?>? _ongoingFetch;

  @override
  Future<List<Map<String, dynamic>>> getIceServers() async {
    final servers = <Map<String, dynamic>>[];

    if (_config.stunUrls.isNotEmpty) {
      servers.add({'urls': List<String>.from(_config.stunUrls)});
    }

    final turn = await _getValidTurnCredentials();
    if (turn != null && turn.uris.isNotEmpty) {
      servers.addAll(turn.toIceServerMaps());
      _log.d('ICE: STUN + ${turn.uris.length} TURN URI(s)');
    } else {
      _log.d('ICE: STUN only');
    }

    return servers;
  }

  @override
  Future<void> invalidateCache() async {
    _cachedTurn = null;
    _ongoingFetch = null;
  }

  Future<TurnCredentials?> _getValidTurnCredentials() async {
    final url = _config.turnCredentialsUrl;
    if (url == null || url.isEmpty) return null;

    final cached = _cachedTurn;
    if (cached != null && !cached.isExpired && !cached.isExpiringSoon) {
      return cached;
    }

    if (_ongoingFetch != null) return _ongoingFetch;

    _ongoingFetch = _fetchTurnCredentials(url);
    try {
      final result = await _ongoingFetch;
      if (result != null) _cachedTurn = result;
      return result;
    } finally {
      _ongoingFetch = null;
    }
  }

  Future<TurnCredentials?> _fetchTurnCredentials(String url) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final token = await _authTokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _http
          .get(Uri.parse(url), headers: headers)
          .timeout(_config.requestTimeout);

      if (response.statusCode != 200) {
        _log.w('TURN credentials HTTP ${response.statusCode}');
        return _cachedTurn;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final creds = TurnCredentials.fromJson(
        json,
        defaultTtlSeconds: _config.turnCacheSeconds,
      );

      if (creds.username.isEmpty ||
          creds.credential.isEmpty ||
          creds.uris.isEmpty) {
        _log.w('TURN credentials response incomplete');
        return _cachedTurn;
      }

      _log.i(
        'TURN credentials OK (TTL ~'
        '${creds.expiresAt.difference(DateTime.now()).inSeconds}s)',
      );
      return creds;
    } on TimeoutException {
      _log.w('TURN credentials timeout');
      return _cachedTurn;
    } catch (e, st) {
      _log.e('TURN credentials fetch failed', error: e, stackTrace: st);
      return _cachedTurn;
    }
  }

  void dispose() {
    _http.close();
  }
}
