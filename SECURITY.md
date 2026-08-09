# Security Notes – Phase 1 + TURN

- No API keys or TURN passwords are committed.
- TURN credentials are short-lived and fetched at runtime over HTTPS.
- `TURN_CREDENTIALS_URL` may be passed via `--dart-define` (URL only).
- coturn `static-auth-secret` and TLS keys live only on the server / secret manager.
- Signaling must be authenticated once a real backend is connected.
- Media uses DTLS-SRTP (WebRTC).
- Diagnostics never log IP addresses, ports, or credential values.
