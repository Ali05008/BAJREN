class TurnCredentials {
  final String username;
  final String credential;
  final List<String> uris;
  final DateTime expiresAt;

  const TurnCredentials({
    required this.username,
    required this.credential,
    required this.uris,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isExpiringSoon =>
      expiresAt.difference(DateTime.now()).inSeconds < 60;

  /// Prefer turns:443 first, then other turns:, then turn:.
  List<String> get prioritizedUris {
    final turns443 = <String>[];
    final turnsOther = <String>[];
    final turnPlain = <String>[];
    for (final u in uris) {
      final lower = u.toLowerCase();
      if (lower.startsWith('turns:') && lower.contains(':443')) {
        turns443.add(u);
      } else if (lower.startsWith('turns:')) {
        turnsOther.add(u);
      } else {
        turnPlain.add(u);
      }
    }
    return [...turns443, ...turnsOther, ...turnPlain];
  }

  factory TurnCredentials.fromJson(
    Map<String, dynamic> json, {
    int defaultTtlSeconds = 3600,
  }) {
    final ttl = (json['ttl'] as num?)?.toInt() ?? defaultTtlSeconds;
    final uris = (json['uris'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        <String>[];

    return TurnCredentials(
      username: json['username'] as String? ?? '',
      credential: json['credential'] as String? ??
          json['password'] as String? ??
          '',
      uris: uris,
      expiresAt: DateTime.now().add(Duration(seconds: ttl)),
    );
  }

  List<Map<String, dynamic>> toIceServerMaps() {
    return prioritizedUris
        .map((uri) => <String, dynamic>{
              'urls': uri,
              'username': username,
              'credential': credential,
            })
        .toList();
  }
}
