/**
 * BAJREN Admin Cloud Functions (2nd gen / v2 callable API).
 *
 * Privilege checks live HERE, not in the Flutter app. The client only hides
 * buttons for UX; every callable below independently re-verifies auth,
 * role, and the specific permission it needs before touching data.
 *
 * Scope: Admin feature only. Does not read or write anything under
 * `signaling/`, messaging, or the general user-facing status system.
 */
import * as admin from "firebase-admin";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import {
  ACCOUNT_STATUSES,
  REPORT_STATUSES,
  ROLE_RANK,
  isValidAccountStatus,
  isValidReportStatus,
  isValidRole,
  permissionForStatusChange,
  roleHasPermission,
} from "./permissions";
import type {
  AccountStatus,
  Permission,
  ReportStatus,
  Role,
} from "./permissions";

admin.initializeApp();
const db = admin.database();

// ---------------------------------------------------------------------------
// Auth / permission helpers
// ---------------------------------------------------------------------------

function roleOf(request: CallableRequest<unknown>): Role {
  const role = request.auth?.token?.role as string | undefined;
  return isValidRole(role) ? role : "USER";
}

function requireStaff(request: CallableRequest<unknown>): Role {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }
  const role = roleOf(request);
  if (role === "USER") {
    throw new HttpsError("permission-denied", "Staff only");
  }
  return role;
}

/** Requires staff AND the specific permission for this operation. */
function requirePermission(
  request: CallableRequest<unknown>,
  permission: Permission
): Role {
  const role = requireStaff(request);
  if (!roleHasPermission(role, permission)) {
    throw new HttpsError(
      "permission-denied",
      `Role ${role} lacks permission ${permission}`
    );
  }
  return role;
}

/** Blocks acting on your own account through these callables (avoid lockout). */
function assertNotSelf(request: CallableRequest<unknown>, targetUserId: string) {
  if (request.auth?.uid === targetUserId) {
    throw new HttpsError(
      "failed-precondition",
      "You cannot perform this action on your own account"
    );
  }
}

/** Blocks acting on a peer-or-higher-ranked account (e.g. ADMIN cannot ban ADMIN/SUPER_ADMIN). */
function assertCanActOnTarget(callerRole: Role, targetRole: Role) {
  if (ROLE_RANK[targetRole] >= ROLE_RANK[callerRole]) {
    throw new HttpsError(
      "permission-denied",
      "Cannot act on an account with an equal or higher role"
    );
  }
}

function requireNonEmptyString(value: unknown, field: string): string {
  const str = typeof value === "string" ? value.trim() : "";
  if (!str) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return str;
}

function nowIso(): string {
  return new Date().toISOString();
}

// ---------------------------------------------------------------------------
// Audit log — server-writes only (client `.write` is `false` in rules)
// ---------------------------------------------------------------------------

async function writeAudit(params: {
  actorId: string;
  actorRole: Role;
  action: string;
  targetUserId?: string | null;
  metadata?: Record<string, unknown>;
  result: "SUCCESS" | "FAILURE";
}) {
  await db.ref("audit_logs").push({
    actorId: params.actorId,
    action: params.action,
    targetUserId: params.targetUserId ?? null,
    metadata: {
      ...(params.metadata ?? {}),
      actorRole: params.actorRole,
      result: params.result,
    },
    createdAt: nowIso(),
  });
}

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

async function getRole(userId: string): Promise<Role> {
  const snap = await db.ref(`admin_roles/${userId}`).once("value");
  const val = snap.val();
  return isValidRole(val) ? val : "USER";
}

async function getStatus(userId: string): Promise<AccountStatus> {
  const snap = await db.ref(`users/${userId}/status`).once("value");
  const val = snap.val();
  return isValidAccountStatus(val) ? val : "ACTIVE";
}

function mapUserRecord(userId: string, node: Record<string, unknown> | null, role: Role) {
  const n = node ?? {};
  return {
    userId,
    username: n.username ?? null,
    displayName: n.displayName ?? null,
    photoUrl: n.photoUrl ?? null,
    phoneMasked: n.phoneMasked ?? null,
    emailMasked: n.emailMasked ?? null,
    status: isValidAccountStatus(n.status) ? n.status : "ACTIVE",
    role,
    isVerified: n.isVerified === true,
    createdAt: n.createdAt ?? null,
    updatedAt: n.updatedAt ?? null,
    lastSeenAt: n.lastSeenAt ?? null,
    suspendedUntil: n.suspendedUntil ?? null,
    statusReason: n.statusReason ?? null,
  };
}

// ---------------------------------------------------------------------------
// 1. Dashboard stats
// ---------------------------------------------------------------------------

export const adminGetDashboardStats = onCall(async (request) => {
  requirePermission(request, "VIEW_ANALYTICS");

  const [usersSnap, reportsSnap] = await Promise.all([
    db.ref("users").once("value"),
    db.ref("reports").once("value"),
  ]);

  const stats = {
    totalUsers: 0,
    activeUsers: 0,
    disabledUsers: 0,
    suspendedUsers: 0,
    bannedUsers: 0,
    verifiedUsers: 0,
    openReports: 0,
    reportsInReview: 0,
    closedReports: 0,
    extras: {} as Record<string, number>,
  };

  usersSnap.forEach((child) => {
    stats.totalUsers += 1;
    const rawStatus = child.child("status").val();
    const status: AccountStatus = isValidAccountStatus(rawStatus) ? rawStatus : "ACTIVE";
    if (status === "DISABLED") stats.disabledUsers += 1;
    else if (status === "SUSPENDED") stats.suspendedUsers += 1;
    else if (status === "BANNED") stats.bannedUsers += 1;
    else if (status === "ACTIVE") stats.activeUsers += 1;
    // DELETED counts toward totalUsers only.
    if (child.child("isVerified").val() === true) stats.verifiedUsers += 1;
    return false;
  });

  reportsSnap.forEach((child) => {
    const rawStatus = child.child("status").val();
    const status: ReportStatus = isValidReportStatus(rawStatus) ? rawStatus : "open";
    if (status === "open") stats.openReports += 1;
    else if (status === "inReview") stats.reportsInReview += 1;
    else stats.closedReports += 1;
    return false;
  });

  return stats;
});

// ---------------------------------------------------------------------------
// 2. Search users
// ---------------------------------------------------------------------------

export const adminSearchUsers = onCall(async (request) => {
  requirePermission(request, "VIEW_USERS");
  const data = (request.data ?? {}) as Record<string, unknown>;

  const rawQuery = typeof data.query === "string" ? data.query.trim().toLowerCase() : "";
  const status = isValidAccountStatus(data.status) ? (data.status as AccountStatus) : null;
  const limit = Math.min(Math.max(Number(data.limit) || 50, 1), 200);

  const [usersSnap, rolesSnap] = await Promise.all([
    db.ref("users").once("value"),
    db.ref("admin_roles").once("value"),
  ]);
  const roles = (rolesSnap.val() ?? {}) as Record<string, string>;

  const results: ReturnType<typeof mapUserRecord>[] = [];
  usersSnap.forEach((child) => {
    const userId = child.key as string;
    const node = child.val() as Record<string, unknown>;
    const role = isValidRole(roles[userId]) ? (roles[userId] as Role) : "USER";
    const record = mapUserRecord(userId, node, role);

    if (status && record.status !== status) return false;
    if (rawQuery) {
      const haystack = `${record.username ?? ""} ${record.displayName ?? ""}`.toLowerCase();
      const matchesText = haystack.includes(rawQuery);
      const matchesUserId = userId.toLowerCase().includes(rawQuery);
      if (!matchesText && !matchesUserId) return false;
    }
    results.push(record);
    return false;
  });

  return { users: results.slice(0, limit) };
});

// ---------------------------------------------------------------------------
// 3. Get single user
// ---------------------------------------------------------------------------

export const adminGetUser = onCall(async (request) => {
  requirePermission(request, "VIEW_USER_DETAILS");
  const data = (request.data ?? {}) as Record<string, unknown>;
  const userId = requireNonEmptyString(data.userId, "userId");

  const [userSnap, role] = await Promise.all([
    db.ref(`users/${userId}`).once("value"),
    getRole(userId),
  ]);
  if (!userSnap.exists()) {
    return { user: null };
  }
  return { user: mapUserRecord(userId, userSnap.val(), role) };
});

// ---------------------------------------------------------------------------
// 4. Set account status
// ---------------------------------------------------------------------------

export const adminSetAccountStatus = onCall(async (request) => {
  const data = (request.data ?? {}) as Record<string, unknown>;
  const userId = requireNonEmptyString(data.userId, "userId");
  const status = data.status;
  const reason = data.reason ? String(data.reason) : null;
  const suspendedUntil = data.suspendedUntil ? String(data.suspendedUntil) : null;

  if (!isValidAccountStatus(status)) {
    throw new HttpsError(
      "invalid-argument",
      `status must be one of: ${ACCOUNT_STATUSES.join(", ")}`
    );
  }

  assertNotSelf(request, userId);
  const callerRole = requireStaff(request);
  const [targetRole, currentStatus] = await Promise.all([
    getRole(userId),
    getStatus(userId),
  ]);
  assertCanActOnTarget(callerRole, targetRole);

  const neededPermission = permissionForStatusChange(status, currentStatus);
  if (!roleHasPermission(callerRole, neededPermission)) {
    throw new HttpsError(
      "permission-denied",
      `Role ${callerRole} lacks permission ${neededPermission}`
    );
  }

  const updates: Record<string, unknown> = {
    [`users/${userId}/status`]: status,
    [`users/${userId}/statusReason`]: reason,
    [`users/${userId}/suspendedUntil`]: status === "SUSPENDED" ? suspendedUntil : null,
    [`users/${userId}/updatedAt`]: nowIso(),
  };
  await db.ref().update(updates);

  // Real enforcement: a blocked account cannot authenticate at all.
  const shouldDisableAuth = status === "DISABLED" || status === "SUSPENDED" || status === "BANNED" || status === "DELETED";
  await admin.auth().updateUser(userId, { disabled: shouldDisableAuth });

  await writeAudit({
    actorId: request.auth!.uid,
    actorRole: callerRole,
    action: "SET_ACCOUNT_STATUS",
    targetUserId: userId,
    metadata: { previousStatus: currentStatus, newStatus: status, reason, suspendedUntil },
    result: "SUCCESS",
  });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// 5. Set user role
// ---------------------------------------------------------------------------

export const adminSetUserRole = onCall(async (request) => {
  const callerRole = requirePermission(request, "MANAGE_ROLES");
  const data = (request.data ?? {}) as Record<string, unknown>;
  const userId = requireNonEmptyString(data.userId, "userId");
  const newRole = data.role;

  if (!isValidRole(newRole)) {
    throw new HttpsError("invalid-argument", "role is invalid");
  }
  assertNotSelf(request, userId);

  const targetRole = await getRole(userId);
  assertCanActOnTarget(callerRole, targetRole);

  // Promoting someone TO SUPER_ADMIN is the most sensitive op: extra gate.
  if (newRole === "SUPER_ADMIN" && !roleHasPermission(callerRole, "MANAGE_ADMINS")) {
    throw new HttpsError(
      "permission-denied",
      "Only SUPER_ADMIN can grant SUPER_ADMIN"
    );
  }

  // setCustomUserClaims REPLACES the entire claims object — merge, don't clobber,
  // so any other claims (e.g. a per-user "permissions" override) survive a role change.
  const targetUserRecord = await admin.auth().getUser(userId);
  const existingClaims = targetUserRecord.customClaims ?? {};
  await admin.auth().setCustomUserClaims(userId, { ...existingClaims, role: newRole });

  await db.ref().update({
    [`admin_roles/${userId}`]: newRole,
    [`users/${userId}/role`]: newRole,
    [`users/${userId}/updatedAt`]: nowIso(),
  });

  await writeAudit({
    actorId: request.auth!.uid,
    actorRole: callerRole,
    action: "SET_USER_ROLE",
    targetUserId: userId,
    metadata: { previousRole: targetRole, newRole },
    result: "SUCCESS",
  });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// 6. Set verified
// ---------------------------------------------------------------------------

export const adminSetVerified = onCall(async (request) => {
  const data = (request.data ?? {}) as Record<string, unknown>;
  const userId = requireNonEmptyString(data.userId, "userId");
  const verified = data.verified === true;
  const permission: Permission = verified ? "VERIFY_USER" : "REVOKE_VERIFICATION";
  const callerRole = requirePermission(request, permission);

  assertNotSelf(request, userId);
  const targetRole = await getRole(userId);
  assertCanActOnTarget(callerRole, targetRole);

  await db.ref(`users/${userId}`).update({
    isVerified: verified,
    updatedAt: nowIso(),
  });

  await writeAudit({
    actorId: request.auth!.uid,
    actorRole: callerRole,
    action: verified ? "VERIFY_USER" : "REVOKE_VERIFICATION",
    targetUserId: userId,
    metadata: { verified },
    result: "SUCCESS",
  });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// 7. List reports
// ---------------------------------------------------------------------------

export const adminListReports = onCall(async (request) => {
  requirePermission(request, "VIEW_REPORTS");
  const data = (request.data ?? {}) as Record<string, unknown>;

  const status = isValidReportStatus(data.status) ? (data.status as ReportStatus) : null;
  const limit = Math.min(Math.max(Number(data.limit) || 50, 1), 200);

  const snap = await db.ref("reports").once("value");
  const reports: Record<string, unknown>[] = [];
  snap.forEach((child) => {
    const val = child.val() as Record<string, unknown>;
    const reportStatus = isValidReportStatus(val.status) ? val.status : "open";
    if (status && reportStatus !== status) return false;
    reports.push({ id: child.key, ...val, status: reportStatus });
    return false;
  });

  reports.sort((a, b) => String(b.createdAt ?? "").localeCompare(String(a.createdAt ?? "")));

  return { reports: reports.slice(0, limit) };
});

// ---------------------------------------------------------------------------
// 8. Update report status
// ---------------------------------------------------------------------------

export const adminUpdateReportStatus = onCall(async (request) => {
  const callerRole = requirePermission(request, "MANAGE_REPORTS");
  const data = (request.data ?? {}) as Record<string, unknown>;
  const reportId = requireNonEmptyString(data.reportId, "reportId");
  const status = data.status;

  if (!isValidReportStatus(status)) {
    throw new HttpsError(
      "invalid-argument",
      `status must be one of: ${REPORT_STATUSES.join(", ")}`
    );
  }

  const reportRef = db.ref(`reports/${reportId}`);
  const snap = await reportRef.once("value");
  if (!snap.exists()) {
    throw new HttpsError("not-found", "Report not found");
  }

  const updates: Record<string, unknown> = { status };
  if (status !== "open") {
    updates.resolvedAt = nowIso();
    updates.resolverId = request.auth!.uid;
  } else {
    updates.resolvedAt = null;
    updates.resolverId = null;
  }
  await reportRef.update(updates);

  await writeAudit({
    actorId: request.auth!.uid,
    actorRole: callerRole,
    action: "UPDATE_REPORT_STATUS",
    targetUserId: (snap.val() as Record<string, unknown>)?.reportedUserId as string | undefined,
    metadata: { reportId, newStatus: status },
    result: "SUCCESS",
  });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// 9. List audit logs
// ---------------------------------------------------------------------------

export const adminListAuditLogs = onCall(async (request) => {
  requirePermission(request, "VIEW_AUDIT_LOGS");
  const data = (request.data ?? {}) as Record<string, unknown>;
  const limit = Math.min(Math.max(Number(data.limit) || 100, 1), 500);

  const snap = await db.ref("audit_logs").orderByKey().limitToLast(limit).once("value");
  const logs: Record<string, unknown>[] = [];
  snap.forEach((child) => {
    logs.push({ id: child.key, ...(child.val() as Record<string, unknown>) });
    return false;
  });
  logs.reverse(); // most recent first

  return { logs };
});
