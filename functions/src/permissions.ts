/**
 * BAJREN Admin — Role & Permission matrix.
 *
 * This MUST stay in sync with:
 *   lib/features/admin/domain/entities/admin_permission.dart (RolePermissionCatalog)
 *
 * The Dart copy is for UI gating ONLY (hiding buttons). This file is the
 * real, enforced authority — every privileged callable in index.ts checks
 * against this matrix before doing anything.
 */

export type Role = "USER" | "MODERATOR" | "ADMIN" | "SUPER_ADMIN";

export const ROLES: readonly Role[] = ["USER", "MODERATOR", "ADMIN", "SUPER_ADMIN"];

export const ROLE_RANK: Record<Role, number> = {
  USER: 0,
  MODERATOR: 1,
  ADMIN: 2,
  SUPER_ADMIN: 3,
};

export function isValidRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as string[]).includes(value);
}

export type Permission =
  | "VIEW_USERS"
  | "VIEW_USER_DETAILS"
  | "DISABLE_USER"
  | "RESTORE_USER"
  | "SUSPEND_USER"
  | "BAN_USER"
  | "UNBAN_USER"
  | "DELETE_USER"
  | "VIEW_REPORTS"
  | "MANAGE_REPORTS"
  | "VIEW_MEDIA"
  | "REMOVE_MEDIA"
  | "VERIFY_USER"
  | "REVOKE_VERIFICATION"
  | "MANAGE_ROLES"
  | "MANAGE_ADMINS"
  | "VIEW_AUDIT_LOGS"
  | "MANAGE_TERMS"
  | "MANAGE_STORAGE"
  | "VIEW_ANALYTICS"
  | "MANAGE_SETTINGS";

// Account statuses — single source of truth for validation.
export const ACCOUNT_STATUSES = [
  "ACTIVE",
  "DISABLED",
  "SUSPENDED",
  "BANNED",
  "DELETED",
] as const;
export type AccountStatus = (typeof ACCOUNT_STATUSES)[number];

export function isValidAccountStatus(value: unknown): value is AccountStatus {
  return (
    typeof value === "string" &&
    (ACCOUNT_STATUSES as readonly string[]).includes(value)
  );
}

// Report statuses — must match lib/.../moderation_report.dart `ReportStatus.name`.
export const REPORT_STATUSES = ["open", "inReview", "closed"] as const;
export type ReportStatus = (typeof REPORT_STATUSES)[number];

export function isValidReportStatus(value: unknown): value is ReportStatus {
  return (
    typeof value === "string" &&
    (REPORT_STATUSES as readonly string[]).includes(value)
  );
}

// Mirrors RolePermissionCatalog.defaults exactly (see admin_permission.dart).
const MODERATOR_PERMISSIONS: Permission[] = [
  "VIEW_USERS",
  "VIEW_USER_DETAILS",
  "VIEW_REPORTS",
  "MANAGE_REPORTS",
  "VIEW_MEDIA",
  "REMOVE_MEDIA",
  "SUSPEND_USER",
];

const ADMIN_PERMISSIONS: Permission[] = [
  "VIEW_USERS",
  "VIEW_USER_DETAILS",
  "DISABLE_USER",
  "RESTORE_USER",
  "SUSPEND_USER",
  "BAN_USER",
  "UNBAN_USER",
  "VIEW_REPORTS",
  "MANAGE_REPORTS",
  "VIEW_MEDIA",
  "REMOVE_MEDIA",
  "VERIFY_USER",
  "REVOKE_VERIFICATION",
  "VIEW_AUDIT_LOGS",
  "VIEW_ANALYTICS",
  "MANAGE_TERMS",
  "MANAGE_STORAGE",
];

const SUPER_ADMIN_PERMISSIONS: Permission[] = [
  "VIEW_USERS",
  "VIEW_USER_DETAILS",
  "DISABLE_USER",
  "RESTORE_USER",
  "SUSPEND_USER",
  "BAN_USER",
  "UNBAN_USER",
  "DELETE_USER",
  "VIEW_REPORTS",
  "MANAGE_REPORTS",
  "VIEW_MEDIA",
  "REMOVE_MEDIA",
  "VERIFY_USER",
  "REVOKE_VERIFICATION",
  "MANAGE_ROLES",
  "MANAGE_ADMINS",
  "VIEW_AUDIT_LOGS",
  "MANAGE_TERMS",
  "MANAGE_STORAGE",
  "VIEW_ANALYTICS",
  "MANAGE_SETTINGS",
];

export const ROLE_PERMISSIONS: Record<Role, ReadonlySet<Permission>> = {
  USER: new Set<Permission>([]),
  MODERATOR: new Set(MODERATOR_PERMISSIONS),
  ADMIN: new Set(ADMIN_PERMISSIONS),
  SUPER_ADMIN: new Set(SUPER_ADMIN_PERMISSIONS),
};

export function roleHasPermission(role: Role, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role].has(permission);
}

/**
 * Which permission is required to move a user INTO `target` status.
 * `currentStatus` disambiguates ACTIVE-from-BANNED (needs UNBAN_USER)
 * vs ACTIVE-from-anything-else (needs RESTORE_USER).
 */
export function permissionForStatusChange(
  target: AccountStatus,
  currentStatus: AccountStatus
): Permission {
  switch (target) {
    case "ACTIVE":
      return currentStatus === "BANNED" ? "UNBAN_USER" : "RESTORE_USER";
    case "DISABLED":
      return "DISABLE_USER";
    case "SUSPENDED":
      return "SUSPEND_USER";
    case "BANNED":
      return "BAN_USER";
    case "DELETED":
      return "DELETE_USER";
  }
}
