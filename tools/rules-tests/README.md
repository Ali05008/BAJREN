# RTDB Security Rules Tests

Verifies the 9 required protections on `users/$uid` (see `rtdb.rules.test.js`):
a normal user cannot change or delete `role`, `status`, `statusReason`,
`suspendedUntil`, `isVerified`, or `permissions`, and cannot delete the
whole `users/$uid` node — while still being able to edit their own
allowed fields, and while the Admin SDK (Cloud Functions) is unaffected.

## Requirements

- Node 20
- Firebase CLI (`npm install -g firebase-tools`)
- Java (required by the Realtime Database emulator)

## Run

```bash
cd tools/rules-tests
npm install
cd ../..
firebase emulators:exec --only database --project bajren-rules-test "npm --prefix tools/rules-tests test"
```

A `firebase.json` pointing at `docs/firebase_database.rules.json` already
exists at the repo root, so no extra emulator config is needed.

This also runs automatically in CI (`.github/workflows/ci.yml`, job
`rules-tests`) on every push/PR.

## Status

Not executed yet in this delivery — written and ready, but not yet run
end-to-end against a live emulator. Please confirm the first CI run (or
a local run) passes and let me know if any scenario fails.
