/**
 * RTDB Security Rules — Admin field protection tests.
 *
 * Covers the 9 originally-required scenarios plus explicit statusReason/
 * suspendedUntil change+delete tests (13 core scenarios total): a normal
 * USER must NOT be able to change or delete role/status/statusReason/
 * suspendedUntil/isVerified/permissions, and must NOT be able to delete
 * the whole users/$uid node. Also confirms a normal field IS still
 * editable, and that a rules-disabled context (which is how the Admin SDK
 * behaves inside Cloud Functions — it bypasses RTDB rules entirely) can
 * still write those fields normally.
 *
 * Run with the Firebase Emulator Suite:
 *   cd tools/rules-tests
 *   npm install
 *   firebase emulators:exec --only database "npm test"
 *
 * (Requires the Firebase CLI + Java, and network access to install
 * dependencies — neither was available in the sandbox this was written
 * in, so this suite has NOT been executed yet. Please run it and report
 * back the results.)
 */
const fs = require("fs");
const path = require("path");
const assert = require("assert");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const RULES_PATH = path.join(__dirname, "..", "..", "docs", "firebase_database.rules.json");

let testEnv;

const OTHER_UID = "other-user-uid";
const UID = "test-user-uid";

const SEED_USER = {
  displayName: "Test User",
  username: "testuser",
  role: "USER",
  status: "ACTIVE",
  statusReason: null,
  suspendedUntil: null,
  isVerified: false,
  permissions: { extra: false },
};

before(async function () {
  this.timeout(20000);
  testEnv = await initializeTestEnvironment({
    projectId: "bajren-rules-test",
    database: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearDatabase();
  // Seed as a privileged (rules-bypassing) context — mirrors how the
  // Admin SDK inside Cloud Functions actually writes this data.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.database().ref(`users/${UID}`).set(SEED_USER);
    await context.database().ref(`admin_roles/${UID}`).set("USER");
  });
});

function userDb() {
  return testEnv.authenticatedContext(UID).database();
}

describe("users/$uid — protected admin fields", () => {
  it("1) USER cannot change own role", async () => {
    await assertFails(userDb().ref(`users/${UID}/role`).set("SUPER_ADMIN"));
  });

  it("2) USER cannot delete own role", async () => {
    await assertFails(userDb().ref(`users/${UID}/role`).remove());
  });

  it("3) USER cannot change own status", async () => {
    await assertFails(userDb().ref(`users/${UID}/status`).set("BANNED"));
  });

  it("4) USER cannot delete own status", async () => {
    await assertFails(userDb().ref(`users/${UID}/status`).remove());
  });

  it("5) USER cannot change own permissions", async () => {
    await assertFails(
      userDb().ref(`users/${UID}/permissions`).set({ extra: true })
    );
  });

  it("6) USER cannot delete own permissions", async () => {
    await assertFails(userDb().ref(`users/${UID}/permissions`).remove());
  });

  it("7) USER cannot change own isVerified", async () => {
    await assertFails(userDb().ref(`users/${UID}/isVerified`).set(true));
  });

  it("8) USER cannot delete own isVerified", async () => {
    await assertFails(userDb().ref(`users/${UID}/isVerified`).remove());
  });

  it("9) USER cannot delete the entire users/$uid node", async () => {
    await assertFails(userDb().ref(`users/${UID}`).remove());
  });

  // --- statusReason / suspendedUntil: change + delete, seeded with a REAL
  // admin-set value (not null). This matters: in Realtime Database, a field
  // whose value is null and a field that doesn't exist at all are the exact
  // same thing on disk — writing null to a path IS the same operation as
  // removing it. So "delete a field that is currently null" is a genuine
  // no-op (nothing on disk changes), and there is no data-level way to
  // distinguish or block it — it's mathematically identical to not writing
  // at all. The security-relevant case is deleting a field that actually
  // holds admin-set data, e.g. an active suspension's reason/expiry. That
  // case IS a real state change and IS blocked, tested below.

  it("10) USER cannot change own statusReason (currently set by admin)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref(`users/${UID}/statusReason`).set("Spam reports");
    });
    await assertFails(
      userDb().ref(`users/${UID}/statusReason`).set("I was framed")
    );
  });

  it("11) USER cannot delete own statusReason (currently set by admin, not null)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref(`users/${UID}/statusReason`).set("Spam reports");
    });
    await assertFails(userDb().ref(`users/${UID}/statusReason`).remove());
  });

  it("12) USER cannot change own suspendedUntil (currently set by admin)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref(`users/${UID}/suspendedUntil`).set("2026-12-31T00:00:00.000Z");
    });
    await assertFails(
      userDb().ref(`users/${UID}/suspendedUntil`).set("2026-01-01T00:00:00.000Z")
    );
  });

  it("13) USER cannot delete own suspendedUntil (currently set by admin, not null — this is the real attack: erasing a suspension expiry)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref(`users/${UID}/suspendedUntil`).set("2026-12-31T00:00:00.000Z");
    });
    await assertFails(userDb().ref(`users/${UID}/suspendedUntil`).remove());
  });

  it("documents: deleting an already-null statusReason is a no-op and is allowed (nothing on disk changes)", async () => {
    // SEED_USER already has statusReason: null. Deleting a field that is
    // already absent/null cannot be meaningfully "blocked" — see comment
    // above. This is a documentation test, not a vulnerability.
    await assertSucceeds(userDb().ref(`users/${UID}/statusReason`).remove());
  });

  // --- Positive controls ---

  it("USER CAN edit an allowed personal field", async () => {
    await assertSucceeds(
      userDb().ref(`users/${UID}/displayName`).set("New Name")
    );
  });

  it("USER CAN patch an allowed field via multi-path update without touching protected fields", async () => {
    await assertSucceeds(
      userDb().ref(`users/${UID}`).update({ displayName: "Patched Name", username: "patcheduser" })
    );
  });

  it("USER cannot smuggle role/status through a full-object update", async () => {
    await assertFails(
      userDb().ref(`users/${UID}`).update({ displayName: "X", role: "ADMIN" })
    );
  });

  it("USER cannot edit another user's profile at all", async () => {
    await assertFails(
      testEnv.authenticatedContext(OTHER_UID).database().ref(`users/${UID}/displayName`).set("Hacked")
    );
  });

  it("Backend/Admin SDK (rules bypassed) CAN still set role/status/isVerified normally", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref(`users/${UID}`).update({
        role: "MODERATOR",
        status: "SUSPENDED",
        isVerified: true,
      });
      const snap = await context.database().ref(`users/${UID}`).once("value");
      const val = snap.val();
      assert.strictEqual(val.role, "MODERATOR");
      assert.strictEqual(val.status, "SUSPENDED");
      assert.strictEqual(val.isVerified, true);
    });
  });
});
