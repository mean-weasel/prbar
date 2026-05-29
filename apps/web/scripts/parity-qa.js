import { chromium } from "@playwright/test";
import { spawn } from "node:child_process";
import { mkdir, rm, writeFile } from "node:fs/promises";
import net from "node:net";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const appDir = resolve(__dirname, "..");
const artifactDir = resolve(appDir, ".qa", "latest");
const screenshotDir = resolve(artifactDir, "screenshots");

const viewports = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const profile = {
  availability: "Open to proof-driven launches",
  handle: "@maya.rchen",
  initials: "MC",
  link: "prbar.dev/maya.rchen",
  name: "Maya R. Chen",
  note: "Builds shipped products with selected GitHub proof.",
  title: "AI-native product engineer",
};

const publishedWorkflow = {
  published: true,
  shareFeedback: "Copied Builder Proof link",
  sources: {
    "maya/sideproject-radar": { attached: true, hidden: false, mode: "included" },
    "maya/radar-ios": { attached: true, hidden: true, mode: "included" },
    "client/stealth-onboarding": { attached: true, hidden: true, mode: "redacted" },
    "maya/experiments": { attached: false, hidden: false, mode: "excluded" },
  },
};

const baseStorage = {
  "prbar-profile": profile,
  "prbar-proof-workflow": publishedWorkflow,
  "prbar-review-map-collapsed": "true",
};

const scenarios = [
  {
    id: "home",
    route: "/home",
    state: "visitor",
    storage: {},
    expectedText: "PRBar is a proof resume",
    mockupMapping: "mockups/web #/home: landing hero, proof resume positioning, and card doorway.",
  },
  {
    id: "builder-proof-owner",
    route: "/profile",
    state: "owner-published",
    storage: { ...baseStorage, "prbar-session": { isAuthenticated: true, githubConnected: true } },
    expectedText: "OWNER VIEW",
    mockupMapping: "mockups/web #/profile owner state: published Builder Proof with owner controls, card, receipt, app proof, timeline, and share rail.",
  },
  {
    id: "builder-proof-prospect",
    route: "/profile",
    state: "signed-out-prospect-published",
    storage: { ...baseStorage, "prbar-session": { isAuthenticated: false, githubConnected: false } },
    expectedText: "Want proof like this?",
    mockupMapping: "mockups/web #/profile signed-out state: public Builder Proof plus prospect CTA and no owner controls.",
  },
  {
    id: "sources-privacy-connected",
    route: "/repos",
    state: "owner-connected",
    storage: { ...baseStorage, "prbar-session": { isAuthenticated: true, githubConnected: true } },
    expectedText: "Sources & Privacy",
    mockupMapping: "mockups/web #/repos: connected source table, include/redact/exclude controls, privacy counts, publish state.",
  },
  {
    id: "alias-card",
    route: "/card",
    state: "owner-published-alias",
    storage: { ...baseStorage, "prbar-session": { isAuthenticated: true, githubConnected: true } },
    expectedText: "SHORT VERSION",
    mockupMapping: "mockups/web #/card archived/direct alias: fused into Builder Proof card section.",
  },
  {
    id: "alias-receipt",
    route: "/receipt",
    state: "owner-published-alias",
    storage: { ...baseStorage, "prbar-session": { isAuthenticated: true, githubConnected: true } },
    expectedText: "SideProject Radar v2.1",
    mockupMapping: "mockups/web #/receipt archived/direct alias: fused into Builder Proof receipt section.",
  },
  {
    id: "alias-project",
    route: "/project",
    state: "owner-published-alias",
    storage: { ...baseStorage, "prbar-session": { isAuthenticated: true, githubConnected: true } },
    expectedText: "Proof attaches to the things Maya shipped.",
    mockupMapping: "mockups/web #/project archived/direct alias: fused into Builder Proof app proof section.",
  },
];

function waitForServer(url, timeoutMs = 30000) {
  const started = Date.now();

  return new Promise((resolveWait, reject) => {
    const tick = async () => {
      try {
        const response = await fetch(url);
        if (response.ok) {
          resolveWait();
          return;
        }
      } catch {
        // Retry until Next is listening.
      }

      if (Date.now() - started > timeoutMs) {
        reject(new Error(`Timed out waiting for ${url}`));
        return;
      }

      setTimeout(tick, 250);
    };

    tick();
  });
}

function findOpenPort() {
  return new Promise((resolvePort, reject) => {
    const server = net.createServer();
    server.unref();
    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      if (!address || typeof address === "string") {
        server.close(() => reject(new Error("Unable to allocate a local QA port")));
        return;
      }
      server.close(() => resolvePort(address.port));
    });
  });
}

function serializeStorage(storage) {
  return Object.entries(storage).map(([key, value]) => [key, typeof value === "string" ? value : JSON.stringify(value)]);
}

async function applyStorage(page, scenario) {
  const entries = serializeStorage(scenario.storage);
  await page.evaluate((items) => {
    window.localStorage.clear();
    window.sessionStorage.clear();
    for (const [key, value] of items) window.localStorage.setItem(key, value);
  }, entries);
}

async function horizontalOverflow(page) {
  return page.evaluate(() => {
    const viewportWidth = document.documentElement.clientWidth;
    const documentWidth = document.documentElement.scrollWidth;
    const bodyWidth = document.body ? document.body.scrollWidth : 0;

    return Math.max(documentWidth, bodyWidth) - viewportWidth;
  });
}

async function captureScenario(browser, baseUrl, scenario, viewport) {
  const context = await browser.newContext({
    baseURL: baseUrl,
    viewport: { width: viewport.width, height: viewport.height },
  });
  const page = await context.newPage();

  try {
    await page.goto(baseUrl, { waitUntil: "networkidle" });
    await applyStorage(page, scenario);
    await page.goto(`${baseUrl}${scenario.route}`, { waitUntil: "networkidle" });

    const bodyText = await page.locator("body").innerText();
    if (!bodyText.includes(scenario.expectedText)) {
      throw new Error(`${scenario.id} ${viewport.name} missing expected text: ${scenario.expectedText}`);
    }

    const overflowPx = await horizontalOverflow(page);
    if (overflowPx > 1) {
      throw new Error(`${scenario.id} ${viewport.name} has horizontal overflow: ${overflowPx}px`);
    }

    const screenshotPath = resolve(screenshotDir, `${scenario.id}-${viewport.name}.png`);
    await page.screenshot({ fullPage: true, path: screenshotPath });

    return {
      id: scenario.id,
      route: scenario.route,
      state: scenario.state,
      viewport: viewport.name,
      viewportSize: { width: viewport.width, height: viewport.height },
      screenshot: relative(appDir, screenshotPath),
      expectedText: scenario.expectedText,
      mockupMapping: scenario.mockupMapping,
      overflow: { pass: true, px: overflowPx },
    };
  } finally {
    await context.close();
  }
}

function markdownReport(results) {
  const lines = [
    "# PRBar Next.js Parity QA",
    "",
    "Generated by `npm run qa` from the built app. The static mockup remains the reference; this report maps prototype surfaces back to the mockups/web hash-route behavior without editing mockups/web.",
    "",
    "| Surface | Route | Viewport | Screenshot | Mockup mapping | Overflow |",
    "| --- | --- | --- | --- | --- | --- |",
  ];

  for (const result of results) {
    lines.push(`| ${result.id} | \`${result.route}\` | ${result.viewport} | \`${result.screenshot}\` | ${result.mockupMapping} | ${result.overflow.pass ? `pass (${result.overflow.px}px)` : `fail (${result.overflow.px}px)`} |`);
  }

  lines.push(
    "",
    "Covered surfaces: home, Builder Proof owner/published, signed-out prospect published, Sources & Privacy connected, and direct card/receipt/project aliases.",
  );

  return `${lines.join("\n")}\n`;
}

async function main() {
  await rm(artifactDir, { force: true, recursive: true });
  await mkdir(screenshotDir, { recursive: true });

  const port = await findOpenPort();
  const baseUrl = `http://127.0.0.1:${port}`;
  const server = spawn("npm", ["run", "start", "--", "-p", String(port), "-H", "127.0.0.1"], {
    cwd: appDir,
    env: { ...process.env, PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"],
  });

  let output = "";
  server.stdout.on("data", (chunk) => {
    output += chunk.toString();
  });
  server.stderr.on("data", (chunk) => {
    output += chunk.toString();
  });

  try {
    await waitForServer(baseUrl);
    const browser = await chromium.launch();
    const results = [];
    try {
      for (const scenario of scenarios) {
        for (const viewport of viewports) {
          results.push(await captureScenario(browser, baseUrl, scenario, viewport));
        }
      }
    } finally {
      await browser.close();
    }

    const report = {
      generatedBy: "npm run qa",
      app: "PRBar Next.js prototype",
      reference: "mockups/web static prototype",
      baseUrl,
      capturedAt: new Date().toISOString(),
      results,
    };

    await writeFile(resolve(artifactDir, "parity-report.json"), `${JSON.stringify(report, null, 2)}\n`);
    await writeFile(resolve(artifactDir, "parity-report.md"), markdownReport(results));

    console.log(`PRBar parity QA passed: ${results.length} screenshots captured`);
    console.log(`Report: ${relative(appDir, resolve(artifactDir, "parity-report.md"))}`);
  } catch (error) {
    console.error(output);
    throw error;
  } finally {
    server.kill("SIGTERM");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
