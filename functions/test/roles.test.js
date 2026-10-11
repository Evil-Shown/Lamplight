const { describe, it } = require("node:test");
const assert = require("node:assert");
const { pickRole } = require("../lib/util");

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
