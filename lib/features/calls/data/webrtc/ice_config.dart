class IceConfig {
  final List<String> stunUrls;
  final String? turnCredentialsUrl;
  final int turnCacheSeconds;
  final Duration requestTimeout;

  const IceConfig({
    this.stunUrls = const [
      'stun:stun.l.google.com:19302',
      'stun:stun1.l.google.com:19302',
      'stun:stun2.l.google.com:19302',
    ],
    this.turnCredentialsUrl,
    this.turnCacheSeconds = 300,
    this.requestTimeout = const Duration(seconds: 8),
  });

  factory IceConfig.fromEnvironment() {
    const turnUrl = String.fromEnvironment('TURN_CREDENTIALS_URL', defaultValue: '');
    return IceConfig(turnCredentialsUrl: turnUrl.isEmpty ? null : turnUrl);
  }
}
