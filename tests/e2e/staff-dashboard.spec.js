// Smoke tests for the Lamplight staff dashboard (admin-web).
//
// Credentials come from environment variables. Never put passwords in this file.
//   STAFF_EMAIL / STAFF_PASSWORD    a staff account
//   ADMIN_EMAIL / ADMIN_PASSWORD    an admin account (optional)
//   STUDENT_EMAIL / STUDENT_PASSWORD a student account (optional)
//
// PowerShell example:
//   $env:STAFF_EMAIL="staff@lamplight.test"; $env:STAFF_PASSWORD="..."; npm test
const { test, expect } = require("@playwright/test");

const staffPages = ["overview", "reservations", "bookings", "waitlist", "verify", "books", "seats"];

async function signIn(page, email, password) {
  await page.goto("/#/overview");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
}

test.describe("signed out", () => {
  test("login page shows the staff sign-in form", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Lamplight Staff" })).toBeVisible();
    await expect(page.getByLabel("Email")).toBeVisible();
    await expect(page.getByLabel("Password")).toBeVisible();
    await expect(page.getByRole("button", { name: "Sign in" })).toBeVisible();
  });

  test("wrong password shows an error and stays on login", async ({ page }) => {
    await signIn(page, "nobody@lamplight.test", "not-the-password");
    await expect(page.getByRole("alert")).toContainText(/Incorrect email or password|Couldn't sign in/);
    await expect(page.getByRole("heading", { name: "Lamplight Staff" })).toBeVisible();
  });
});

test.describe("staff account", () => {
  test.skip(!process.env.STAFF_EMAIL || !process.env.STAFF_PASSWORD, "Set STAFF_EMAIL and STAFF_PASSWORD");

  test("signs in and sees the operations navigation", async ({ page }) => {
    await signIn(page, process.env.STAFF_EMAIL, process.env.STAFF_PASSWORD);
    await expect(page.getByRole("navigation", { name: "Main" })).toBeVisible({ timeout: 30_000 });
    await expect(page.locator('a[data-path="overview"]')).toBeVisible();
    await expect(page.locator('a[data-path="reservations"]')).toBeVisible();
  });

  for (const path of staffPages) {
    test(`opens the ${path} page without an error`, async ({ page }) => {
      await signIn(page, process.env.STAFF_EMAIL, process.env.STAFF_PASSWORD);
      await page.waitForSelector('a[data-path="overview"]', { timeout: 30_000 });
      await page.goto(`/#/${path}`);
      await expect(page.locator("main, #main").first()).toBeVisible();
      await expect(page.getByText(/Something went wrong|could not load|permission/i)).toHaveCount(0);
      await page.screenshot({ path: `screenshots/${path}.png`, fullPage: true });
    });
  }

  test("staff account does not see the admin-only Staff page", async ({ page }) => {
    await signIn(page, process.env.STAFF_EMAIL, process.env.STAFF_PASSWORD);
    await page.waitForSelector('a[data-path="overview"]', { timeout: 30_000 });
    await expect(page.locator('a[data-path="staff"]')).toHaveCount(0);
  });
});

test.describe("student account is refused", () => {
  test.skip(!process.env.STUDENT_EMAIL || !process.env.STUDENT_PASSWORD, "Set STUDENT_EMAIL and STUDENT_PASSWORD");

  test("student gets the no-access message and is signed out", async ({ page }) => {
    await signIn(page, process.env.STUDENT_EMAIL, process.env.STUDENT_PASSWORD);
    await expect(page.getByRole("alert")).toContainText(/doesn't have library staff access/, { timeout: 30_000 });
    await expect(page.getByRole("heading", { name: "Lamplight Staff" })).toBeVisible();
  });
});
