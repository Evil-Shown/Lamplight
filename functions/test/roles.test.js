const { describe, it } = require("node:test");
const assert = require("node:assert");
const { pickRole, decideClaim } = require("../lib/util");

describe("decideClaim", () => {
  const staff = ["staff@x.com"];
  const admin = ["admin@x.com"];
  it("grants the listed role to verified emails", () => {
    assert.deepEqual(decideClaim("admin@x.com", true, false, staff, admin), { role: "admin", pendingVerification: false });
    assert.deepEqual(decideClaim("staff@x.com", true, false, staff, admin), { role: "staff", pendingVerification: false });
  });
  it("keeps listed but unverified emails as student and flags it", () => {
    assert.deepEqual(decideClaim("admin@x.com", false, false, staff, admin), { role: "student", pendingVerification: true });
    assert.deepEqual(decideClaim("staff@x.com", false, false, staff, admin), { role: "student", pendingVerification: true });
  });
  it("does not flag unlisted emails, verified or not", () => {
    assert.deepEqual(decideClaim("n@x.com", false, false, staff, admin), { role: "student", pendingVerification: false });
    assert.deepEqual(decideClaim("n@x.com", true, false, staff, admin), { role: "student", pendingVerification: false });
  });
  it("skips verification in the emulator", () => {
    assert.deepEqual(decideClaim("staff@x.com", false, true, staff, admin), { role: "staff", pendingVerification: false });
  });
});

describe("pickRole precedence", () => {
  const staff = ["Staff@x.com", " both@x.com "];
  const admin = ["admin@x.com", "both@x.com"];
  it("admin beats staff beats student", () => {
    assert.equal(pickRole("both@x.com", staff, admin), "admin");
    assert.equal(pickRole("admin@x.com", staff, admin), "admin");
    assert.equal(pickRole("staff@x.com", staff, admin), "staff");
    assert.equal(pickRole("nobody@x.com", staff, admin), "student");
  });
  it("is case/whitespace insensitive and tolerates bad lists", () => {
    assert.equal(pickRole("  STAFF@X.COM ", staff, undefined), "staff");
    assert.equal(pickRole("staff@x.com", "oops", null), "student");
    assert.equal(pickRole("", staff, admin), "student");
  });
});
