# BAJREN Admin Architecture

## Principles

1. **Never trust the client** for role or privilege changes.
2. Roles live in **Firebase Auth Custom Claims** (`role`: USER | MODERATOR | ADMIN | SUPER_ADMIN) set only via Admin SDK / Cloud Functions.
3. Optional mirror at `admin_roles/{uid}` for Security Rules (written only by Functions).
4. Flutter may hide UI, but **all mutations** go through Callable Functions that re-check claims.
5. Passwords, OTP, TURN secrets, API keys are never exposed to Admin clients.

## Data paths

| Path | Client write | Client read |
|------|--------------|-------------|
| `users/{uid}` profile fields | own non-privileged fields only | self or staff |
| `users/{uid}/role\|status` | **denied** | staff / self limited |
| `admin_roles/{uid}` | **denied** | admin+ |
| `reports/{id}` | create as reporter | reporter or staff |
| `audit_logs` | **denied** | admin+ |
| `admin_stats` | **denied** | staff |

## Callable Functions (server)

- `adminGetDashboardStats`
- `adminSearchUsers`
- `adminGetUser`
- `adminSetAccountStatus`
- `adminSetUserRole` (SUPER_ADMIN only for promoting admins)
- `adminSetVerified`
- `adminListReports` / `adminUpdateReportStatus`
- `adminListAuditLogs`

Each function: verify auth → load claims → check permission → mutate with Admin SDK → write audit log.

## Account status

| Status | Meaning |
|--------|---------|
| ACTIVE | Normal |
| DISABLED | Blocked (user or admin) |
| SUSPENDED | Temporary until timestamp |
| BANNED | Permanent until unban |
| DELETED | Soft delete |

## Admin app structure (Flutter feature)

`lib/features/admin/` — domain + data + presentation shell.  
Future: separate Web Admin app can reuse the same Callable API.
