/// Provides ICE server configuration (STUN + TURN) for WebRTC.
/// TURN credentials must never be hardcoded — fetch short-lived ones from a secure backend.
abstract class IceServerProvider {
  Future<List<Map<String, dynamic>>> getIceServers();
  Future<void> invalidateCache();
}
