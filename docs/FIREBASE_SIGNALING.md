# Firebase Signaling – Production

## Path

```
signaling/{toUserId}/{pushId} = {
  callId, type, payload, fromUserId, toUserId, timestamp
}
```

## Client

- `FirebaseSignalingService` requires `FirebaseAuth.currentUser`.
- `fromUserId` is forced to `auth.uid` on send.
- Inbox messages are deleted after processing.
- Mismatched `toUserId` / self-messages are dropped.

## Security rules

Deploy `docs/firebase_database.rules.json` to Firebase Realtime Database.

## Message types

offer | answer | iceCandidate | hangup | reject | renegotiate

## Reconnect

Call `connect(uid)` again after auth restore or app resume.
The engine keeps media; only signaling is re-bound.
