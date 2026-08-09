# BAJREN – First real two-device call (from phone + GitHub)

This guide is written so you can configure everything and test a call **without a local computer**, using GitHub Actions to build the APK.

---

## Status honesty

- Code supports: Firebase Auth, Realtime Database signaling, WebRTC, TURN credential fetch.
- A **real two-device call is not claimed successful** until you complete the steps below on two phones.
- Until Firebase + TURN are configured, the app runs in **demo mode** (single device only).

---

## Part A – Firebase (one-time)

### 1. Create project
1. Open [Firebase Console](https://console.firebase.google.com) on your phone browser.
2. Create a project (e.g. `bajren-prod`).
3. Disable Google Analytics if you want fewer steps.

### 2. Authentication
1. Build → Authentication → Get started.
2. Enable **Anonymous**.
3. Enable **Email/Password**.

### 3. Realtime Database
1. Build → Realtime Database → Create database.
2. Choose a region close to your users.
3. Start in **locked mode**, then open **Rules** and paste the contents of `docs/firebase_database.rules.json` from this repo.
4. Publish rules.

### 4. Register Android app
1. Project settings → Add app → Android.
2. Package name: `com.bajren.bajren` (must match `applicationId` in the project).
3. Download `google-services.json`.
4. **Do not commit this file to public Git.** Store it privately (password manager / private drive).

### 5. Values you will need for the build
From Project settings → Your apps / General, note:
- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `storageBucket`

---

## Part B – TURN server (required for many mobile networks)

Without TURN, calls often fail on cellular (Symmetric NAT).

1. Deploy **coturn** (VPS) with TLS on port 443 if possible.
2. Use `use-auth-secret` (time-limited credentials).
3. Create a small backend endpoint:

```
GET https://api.YOURDOMAIN.com/v1/turn-credentials
Authorization: Bearer <Firebase ID token>
```

Response example:

```json
{
  "username": "1700000000:uid",
  "credential": "hmac-value",
  "ttl": 3600,
  "uris": [
    "turns:turn.YOURDOMAIN.com:443?transport=tcp",
    "turn:turn.YOURDOMAIN.com:3478?transport=udp"
  ]
}
```

4. Put the coturn secret **only on the server**, never in the app or GitHub client secrets as a long-lived client password.

Details: `docs/TURN_BACKEND.md`.

---

## Part C – Put the project on GitHub and build APK from the phone

1. Create a GitHub repository.
2. Upload this project (including `.github/workflows/ci.yml`).
3. Open the repo → **Actions** → run **BAJREN CI** (workflow_dispatch) or push to `main`.
4. When the job finishes, download artifact **`bajren-debug-apk`**.
5. Install the APK on **two phones**.

### Optional: pass Firebase defines in CI

If you build with dart-defines in Actions, store **non-password** values as GitHub Secrets, for example:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `TURN_CREDENTIALS_URL` (URL only)

Then extend the workflow build step:

```yaml
- run: |
    flutter build apk --debug \
      --dart-define=FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }} \
      --dart-define=FIREBASE_APP_ID=${{ secrets.FIREBASE_APP_ID }} \
      --dart-define=FIREBASE_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_MESSAGING_SENDER_ID }} \
      --dart-define=FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }} \
      --dart-define=FIREBASE_STORAGE_BUCKET=${{ secrets.FIREBASE_STORAGE_BUCKET }} \
      --dart-define=TURN_CREDENTIALS_URL=${{ secrets.TURN_CREDENTIALS_URL }}
```

Also place `google-services.json` via a secure step if required by the Android Google Services plugin (do not commit it to a public repo).

---

## Part D – First two-device call test

1. Phone A: open app → **Continue anonymously** (or register email).
2. Copy **uid** shown on the home screen.
3. Phone B: sign in the same way → copy its uid.
4. On A: enter B’s uid → Start Video Call.
5. On B: **Incoming call** → Accept.
6. Confirm:
   - Remote video/audio appears, or
   - Connection state becomes `connected`
7. If it fails on cellular, verify TURN endpoint returns credentials and that `TURN_CREDENTIALS_URL` was set at build/runtime.

---

## Local / CI verification (already required)

```bash
flutter pub get
flutter analyze
flutter test
```

GitHub Actions runs the same on every push.

---

## What “done” means for WebRTC phase

| Criterion | Owner |
|-----------|--------|
| Code + CI in repo | Repository |
| Firebase project + rules | You |
| TURN backend | You |
| Successful call A ↔ B on two phones | You (acceptance test) |

Until step “Successful call A ↔ B” is observed, treat the WebRTC phase as **implemented but not yet field-verified**.

---

## Admin foundation (Phase scaffold)

Already in repo:

- Roles: USER / MODERATOR / ADMIN / SUPER_ADMIN
- Permissions catalog + client `AdminAccess` (UI only)
- `AdminRepository` → Cloud Callable Functions (server enforces)
- RTDB rules: clients cannot write `role` / `status` / `admin_roles` / `audit_logs`
- `functions/src/index.ts` skeleton for claims + status changes

### Promote first SUPER_ADMIN (server only)

```bash
# On a trusted machine with service account
npx firebase functions:shell
# or a one-off Admin SDK script:
# auth.setCustomUserClaims(uid, { role: 'SUPER_ADMIN' })
# db.ref('admin_roles/'+uid).set('SUPER_ADMIN')
```

Never implement “become admin” inside the mobile app.
