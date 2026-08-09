# TURN Credentials Backend

## Endpoint

```
GET /v1/turn-credentials
Authorization: Bearer <Firebase ID token>
```

## Response 200

```json
{
  "username": "<unix_timestamp:uid>",
  "credential": "<hmac-sha1>",
  "ttl": 3600,
  "uris": [
    "turns:turn.example.com:443?transport=tcp",
    "turn:turn.example.com:3478?transport=udp",
    "turn:turn.example.com:3478?transport=tcp"
  ]
}
```

## Rules

- Verify Firebase ID token on the server.
- Issue short-lived TURN REST credentials (coturn `use-auth-secret`).
- Never embed TURN passwords in the Flutter app or GitHub.
- Client sets only: `--dart-define=TURN_CREDENTIALS_URL=https://api.example.com/v1/turn-credentials`

## Flutter

`SecureIceServerProvider` calls this endpoint when the define is set.
