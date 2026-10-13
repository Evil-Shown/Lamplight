// Runs against the deployed staff dashboard by default.
// Override with BASE_URL=http://localhost:5000 for a local server.
const { defineConfig } = require("@playwright/test");

module.exports = defineConfig({
  testDir: ".",
  timeout: 60_000,
  retries: 0,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: process.env.BASE_URL || "https://sliit-quick-book.web.app",
    // Uses the Edge already installed on Windows, so no browser download is needed.
    channel: "msedge",
    headless: true,
    screenshot: "on",
    trace: "retain-on-failure",
  },
});
