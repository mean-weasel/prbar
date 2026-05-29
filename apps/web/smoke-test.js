import { chromium } from "@playwright/test";
import { spawn } from "node:child_process";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const port = 4181;
const baseUrl = `http://127.0.0.1:${port}`;
const mobileViewport = { width: 390, height: 844 };
const desktopViewport = { width: 1280, height: 900 };

const routeExpectations = [
  ["#/home", "PRBar is the new resume for AI-native builders."],
  ["#/signup", "Start with the short proof link."],
  ["#/signin", "Sign in to manage Builder Proof."],
  ["#/login", "Sign in to manage Builder Proof."],
  ["#/logout", "You're signed out."],
  ["#/onboarding", "Publish Builder Proof in four moves."],
  ["#/connect-github", "Bring in the facts, then choose what counts."],
  ["#/profile", "Builder Proof is not published yet."],
  ["#/card", "Builder Proof is not published yet."],
  ["#/receipt", "Builder Proof is not published yet."],
  ["#/project", "Builder Proof is not published yet."],
  ["#/user", "Sign in to manage Builder Proof."],
  ["#/edit-profile", "Sign in to edit this profile."],
  ["#/repos", "Sources & Privacy"],
  ["#/account", "Sign in to manage account permissions."],
];

function waitForServer(url, timeoutMs = 30000) {
  const started = Date.now();

  return new Promise((resolve, reject) => {
    const tick = async () => {
      try {
        const response = await fetch(url);
        if (response.ok) {
          resolve();
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

async function assertBodyIncludes(page, route, expectedText) {
  const bodyText = await page.locator("body").innerText();
  if (!bodyText.includes(expectedText)) {
    throw new Error(`${route} missing expected text: ${expectedText}`);
  }
}

async function assertBodyExcludes(page, route, forbiddenText) {
  const bodyText = await page.locator("body").innerText();
  if (bodyText.includes(forbiddenText)) {
    throw new Error(`${route} includes forbidden text: ${forbiddenText}`);
  }
}

async function assertLocatorIncludes(page, selector, route, expectedText) {
  const text = await page.locator(selector).innerText();
  if (!text.includes(expectedText)) {
    throw new Error(`${route} ${selector} missing expected text: ${expectedText}`);
  }
}

async function assertLocatorExcludes(page, selector, route, forbiddenText) {
  const text = await page.locator(selector).innerText();
  if (text.includes(forbiddenText)) {
    throw new Error(`${route} ${selector} includes forbidden text: ${forbiddenText}`);
  }
}

async function assertLocatorCount(page, selector, route, expectedCount) {
  const count = await page.locator(selector).count();
  if (count !== expectedCount) {
    throw new Error(`${route} ${selector} expected ${expectedCount} matches, found ${count}`);
  }
}

async function assertLocatorDisabled(page, selector, route) {
  const disabled = await page.locator(selector).isDisabled();
  if (!disabled) {
    throw new Error(`${route} ${selector} expected to be disabled`);
  }
}

async function assertActiveProofStep(page, route, expectedText) {
  const activeSteps = page.locator(".home-proof-path .active");
  const count = await activeSteps.count();
  if (count !== 1) {
    throw new Error(`${route} expected exactly 1 active proof path step, found ${count}`);
  }

  const text = await activeSteps.first().innerText();
  if (!text.includes(expectedText)) {
    throw new Error(`${route} active proof path step expected ${expectedText}, got ${text}`);
  }
}

async function assertSectionNearTop(page, route, selector) {
  await page.waitForFunction((selector) => {
    const element = document.querySelector(selector);
    return element ? Math.abs(element.getBoundingClientRect().top) <= 300 : false;
  }, selector);
  const distance = await page.locator(selector).evaluate((element) => Math.abs(element.getBoundingClientRect().top));
  if (distance > 300) {
    throw new Error(`${route} ${selector} is not focused near the top; distance ${distance}px`);
  }
}

async function assertNoHorizontalOverflow(page, route) {
  const overflow = await page.evaluate(() => {
    const viewportWidth = document.documentElement.clientWidth;
    const documentWidth = document.documentElement.scrollWidth;
    const bodyWidth = document.body ? document.body.scrollWidth : 0;

    return Math.max(documentWidth, bodyWidth) - viewportWidth;
  });

  if (overflow > 1) {
    throw new Error(`${route} has horizontal overflow: ${overflow}px`);
  }
}

async function assertTopbarCompact(page, route) {
  const height = await page.locator(".topbar").evaluate((element) => element.getBoundingClientRect().height);
  if (height > 132) {
    throw new Error(`${route} mobile topbar expected height <= 132px, got ${height}px`);
  }
}

async function assertMobileBuilderCardHeight(page, route) {
  const box = await page.locator("[data-builder-link-card]").boundingBox();
  if (!box) {
    throw new Error(`${route} [data-builder-link-card] is not visible`);
  }

  if (box.height < 360 || box.height > 620) {
    throw new Error(`${route} mobile builder card expected height between 360px and 620px, got ${box.height}px`);
  }
}

async function runChecks(page) {
  await page.goto(`${baseUrl}/home`, { waitUntil: "networkidle" });
  await page.evaluate(() => {
    window.localStorage.removeItem("prbar-profile");
    window.localStorage.removeItem("prbar-session");
    window.localStorage.removeItem("prbar-proof-workflow");
    window.localStorage.setItem("prbar-review-map-collapsed", "true");
    window.sessionStorage.clear();
  });

  for (const route of ["#/card", "#/receipt", "#/project"]) {
    await page.goto(`${baseUrl}/${route}`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, route, "Builder Proof is not published yet.");
    await assertBodyExcludes(page, route, "SideProject Radar v2.1");
    await assertBodyExcludes(page, route, "Share links are ready.");
    await assertNoHorizontalOverflow(page, route);
  }

  for (const [route, expectedText] of routeExpectations) {
    await page.goto(`${baseUrl}/${route}`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, route, expectedText);
    await assertNoHorizontalOverflow(page, route);
  }

  await page.goto(`${baseUrl}/#/onboarding`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "#/onboarding solo path", "Claim card -> connect GitHub -> choose what counts -> publish Builder Proof -> share anywhere.");

  await page.goto(`${baseUrl}/#/signup`, { waitUntil: "networkidle" });
  await page.locator('.auth-panel [data-auth-action="signup"]').click();
  await page.waitForURL(`${baseUrl}/connect-github`);
  await assertBodyIncludes(page, "/connect-github after signup", "Authorize and choose sources");

  await page.goto(`${baseUrl}/#/home`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "#/home nav", "Builder Proof");
  await assertBodyIncludes(page, "#/home value", "PRBar is a proof resume");
  await assertBodyIncludes(page, "#/home builder model", "BUILDER CARD -> BUILDER PROOF");
  await assertBodyIncludes(page, "#/home path", "Claim a builder card, connect GitHub, choose what counts, publish Builder Proof, and share one inspectable link anywhere.");
  await assertBodyExcludes(page, "#/home retired IA", "Proof Index");
  await assertBodyExcludes(page, "#/home retired IA", "Builder Search");
  await assertLocatorCount(page, '[data-builder-link-card]', "#/home flipping card", 1);
  await assertMobileBuilderCardHeight(page, "#/home");
  await assertLocatorIncludes(page, '[data-builder-link-card]', "#/home card front", "FRONT: PORTABLE CARD");
  await page.locator('[data-builder-link-card] [data-card-side="back"]').click();
  await page.waitForFunction(() => document.querySelector('[data-builder-link-card]')?.classList.contains("flipped"));
  await assertLocatorIncludes(page, '[data-builder-link-card]', "#/home card back", "BACK: GITHUB-BACKED PROOF");
  await page.locator('[data-builder-link-card] [data-card-side="front"]').click();
  await page.waitForFunction(() => !document.querySelector('[data-builder-link-card]')?.classList.contains("flipped"));
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.locator('[data-builder-link-card] [data-card-side="back"]').click();
  const reducedMotionTransition = await page.locator('[data-builder-link-card] .builder-link-flip').evaluate((element) => getComputedStyle(element).transitionDuration);
  if (reducedMotionTransition !== "0s") {
    throw new Error(`#/home reduced motion expected 0s transition, got ${reducedMotionTransition}`);
  }
  await page.emulateMedia({ reducedMotion: "no-preference" });

  const reviewMapHidden = await page.evaluate(() => document.body.classList.contains("toc-collapsed"));
  if (!reviewMapHidden) throw new Error("#/home should hide review map by default");

  await page.locator(".toc-toggle").click();
  await assertBodyIncludes(page, "#/home workflow map", "Claim card -> connect GitHub -> choose what counts -> publish Builder Proof -> share anywhere.");
  await page.locator(".workflow-map-actions button", { hasText: "Close" }).click();
  await assertBodyExcludes(page, "#/home workflow map closed", "Workflow map");

  await page.locator('.topbar .nav button[data-section="/profile"]').click();
  await page.waitForURL(`${baseUrl}/profile`);
  await assertLocatorIncludes(page, ".topbar .nav", "/profile signed-out nav after click", "Sources & Privacy");

  await page.goto(`${baseUrl}/#/signin`, { waitUntil: "networkidle" });
  await page.locator('.auth-panel [data-auth-action="login"]').click();
  await page.waitForURL(`${baseUrl}/user`);
  await assertBodyIncludes(page, "/user after login", "Log out");
  await assertTopbarCompact(page, "/user signed-in mobile");
  await assertLocatorIncludes(page, ".topbar .nav", "/user signed-in nav", "Dashboard");
  await assertLocatorIncludes(page, ".topbar .nav", "/user signed-in nav", "Account");
  await assertBodyIncludes(page, "/user workspace heading", "Manage your Builder Proof workspace.");
  await assertBodyIncludes(page, "/user new signed-in state", "NEW SIGNED-IN USER");
  await assertBodyIncludes(page, "/user setup checklist", "FINISH SETUP");
  await assertBodyIncludes(page, "/user checklist profile", "Profile claimed");
  await assertBodyIncludes(page, "/user checklist github", "GitHub connected");
  await assertBodyIncludes(page, "/user checklist publish", "Builder Proof published");
  await page.goto(`${baseUrl}/#/home`, { waitUntil: "networkidle" });
  await assertTopbarCompact(page, "/home signed-in mobile");
  await assertBodyIncludes(page, "/home signed-in owner panel", "SIGNED-IN OWNER VIEW");
  await assertBodyIncludes(page, "/home signed-in owner workspace", "Owner workspace for Maya Chen.");
  await assertSectionNearTop(page, "/home signed-in owner panel", ".signed-in-home-panel");
  await assertBodyIncludes(page, "/home signed-in dashboard action", "Open Dashboard");
  await assertBodyIncludes(page, "/home signed-in next action", "Connect GitHub");
  await assertActiveProofStep(page, "/home signed-in proof path", "Connect GitHub");

  await page.goto(`${baseUrl}/#/profile`, { waitUntil: "networkidle" });
  await assertTopbarCompact(page, "/profile signed-in mobile");
  await assertBodyIncludes(page, "/profile pre-github owner", "Connect GitHub to build Builder Proof.");
  await assertBodyIncludes(page, "/profile pre-github next", "Connect GitHub next");
  await assertBodyExcludes(page, "/profile pre-github misleading copy", "GitHub proof is connected");
  await assertLocatorCount(page, '[data-proof-action="publish-draft"]', "/profile pre-github publish action", 0);

  await page.goto(`${baseUrl}/#/connect-github`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "#/connect-github permissions", "Release tags");
  await assertBodyIncludes(page, "#/connect-github proof definition", "GitHub proof means imported PR, release, tag, timestamp, and check metadata.");
  await assertBodyIncludes(page, "#/connect-github source preview", "4 candidate sources found");
  await assertBodyIncludes(page, "#/connect-github source preview privacy", "name hidden by default");
  await page.locator('[data-auth-action="connect-github"]').click();
  await page.waitForURL(`${baseUrl}/repos`);
  await assertTopbarCompact(page, "/repos signed-in mobile");
  await assertBodyIncludes(page, "/repos after connect", "GitHub connected");
  await assertBodyIncludes(page, "/repos connected draft state", "CONNECTED DRAFT");
  await assertBodyIncludes(page, "/repos draft state", "Draft Builder Proof");
  await assertBodyIncludes(page, "/repos review warning", "Review and confirm source choices before publishing.");
  await assertLocatorDisabled(page, '[data-proof-action="publish"]', "/repos publish before review");
  await page.locator('[data-source-action="confirm-review"]').click();
  await assertBodyIncludes(page, "/repos review confirmed", "Source choices reviewed. Builder Proof is ready to publish.");

  await page.goto(`${baseUrl}/#/profile`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/profile owner draft", "Your Builder Proof is almost shareable.");
  await assertBodyIncludes(page, "/profile owner draft state", "CONNECTED DRAFT");
  await assertBodyExcludes(page, "/profile owner draft should not show public empty", "Builder Proof is not published yet.");

  await page.goto(`${baseUrl}/#/edit-profile`, { waitUntil: "networkidle" });
  await page.locator('[name="profile-name"]').fill("Maya R. Chen");
  await page.locator('[name="profile-handle"]').fill("@maya.rchen");
  await page.locator('[name="profile-title"]').fill("AI-native product engineer");
  await page.locator('[name="profile-availability"]').fill("Open to proof-driven launches");
  await page.locator('[name="profile-note"]').fill("Builds shipped products with selected GitHub proof.");
  await page.locator('[data-profile-action="save"]').click();
  await page.waitForURL(`${baseUrl}/user`);
  await assertBodyIncludes(page, "/user saved profile name", "Maya R. Chen");

  await page.goto(`${baseUrl}/#/repos`, { waitUntil: "networkidle" });
  await page.locator('[data-source-id="maya/experiments"][data-source-action="include"]').click();
  await assertBodyIncludes(page, "/repos live source count", "4 sources power Builder Proof");
  await assertBodyIncludes(page, "/repos public status", "Public name visible");
  await assertBodyIncludes(page, "/repos reveal privacy label", "Reveal publicly");
  await page.locator('[data-source-id="maya/experiments"][data-source-action="privacy"]').click();
  await assertBodyIncludes(page, "/repos hidden status", "Hidden from public");
  await assertBodyIncludes(page, "/repos hidden impact", "Visible to you here. Hidden from public Builder Proof while still counting selected proof.");
  await page.locator('[data-source-id="maya/experiments"][data-source-action="attach"]').click();
  await assertBodyIncludes(page, "/repos live attachment count", "3 attached apps");
  await page.locator('[data-source-id="client/stealth-onboarding"][data-source-action="exclude"]').click();
  await assertBodyIncludes(page, "/repos live excluded count", "1 excluded");
  await assertLocatorDisabled(page, '[data-proof-action="publish"]', "/repos publish after source edit");
  await page.locator('[data-source-action="confirm-review"]').click();
  await page.locator('[data-proof-action="publish"]').click();
  await assertBodyIncludes(page, "/repos published state", "Builder Proof is live");
  await page.locator('[data-source-id="client/stealth-onboarding"][data-source-action="include"]').click();
  await assertBodyIncludes(page, "/repos post-publish draft feedback", "Source changes saved to draft.");
  await assertBodyIncludes(page, "/repos publish updates", "Publish updates");
  await assertLocatorDisabled(page, '[data-proof-action="publish-updates"]', "/repos publish updates before review");
  await assertBodyIncludes(page, "/repos live remains public", "Your live Builder Proof is still public. These source changes are private until you publish updates.");
  await page.locator('[data-proof-action="open-public"]').click();
  await page.waitForURL(`${baseUrl}/profile`);
  await page.locator('.owner-hero-actions [data-preview-action="enter"]').click();
  await assertBodyIncludes(page, "/profile dirty draft public snapshot", "3 selected sources power the card, receipt, app proof, and timeline.");
  await assertBodyExcludes(page, "/profile dirty draft excludes draft snapshot", "4 selected sources power the card, receipt, app proof, and timeline.");
  await page.goto(`${baseUrl}/#/repos`, { waitUntil: "networkidle" });
  await page.locator('[data-source-action="confirm-review"]').click();
  await page.locator('[data-proof-action="publish-updates"]').click();
  await assertBodyIncludes(page, "/repos published updates feedback", "Published updates to the public Builder Proof.");
  await assertBodyIncludes(page, "/repos published updates state", "Builder Proof is live");

  await page.locator('[data-proof-action="open-public"]').click();
  await page.waitForURL(`${baseUrl}/profile`);
  await assertBodyIncludes(page, "/profile updated public snapshot", "4 selected sources power the card, receipt, app proof, and timeline.");
  await assertBodyIncludes(page, "/profile published badge", "PUBLISHED BUILDER PROOF");
  await assertBodyIncludes(page, "/profile owner mode", "OWNER VIEW");
  await assertLocatorIncludes(page, ".owner-hero-actions", "/profile owner hero actions", "Review sources");
  await assertLocatorIncludes(page, ".owner-hero-actions", "/profile owner hero actions", "Edit profile");
  await assertLocatorIncludes(page, ".owner-hero-actions", "/profile owner hero actions", "View as public");
  await assertBodyIncludes(page, "/profile owner controls", "Owner controls");
  await assertBodyIncludes(page, "/profile saved note", "Builds shipped products with selected GitHub proof.");
  await assertBodyIncludes(page, "/profile featured receipt", "GitHub facts are imported from releases, PRs, tags, checks, and timestamps.");
  await assertBodyIncludes(page, "/profile app proof", "Proof attaches to the things Maya shipped.");
  await assertBodyIncludes(page, "/profile proof timeline", "Recent shipped work, in order.");
  await assertBodyIncludes(page, "/profile share rail", "selected sources power the card, receipt, app proof, and timeline.");
  await assertBodyIncludes(page, "/profile share card label", "Builder Card");
  await assertBodyIncludes(page, "/profile share proof label title", "Builder Proof");
  await assertBodyIncludes(page, "/profile share card copy label", "Copy Builder Card link");
  await assertBodyIncludes(page, "/profile share proof label", "Copy public Builder Proof link");
  await page.locator('.proof-share-rail [data-share-action="card"]').click();
  await page.waitForFunction(() => document.body.innerText.includes("Copied Builder Card link"));
  await assertBodyIncludes(page, "/profile card share feedback", "Copied Builder Card link");
  await assertBodyIncludes(page, "/profile card share output", "#builder-card");
  await page.locator('.proof-share-rail [data-share-action="proof"]').click();
  await page.waitForFunction(() => document.body.innerText.includes("Copied Builder Proof link"));
  await assertBodyIncludes(page, "/profile share feedback", "Copied Builder Proof link");
  await assertBodyIncludes(page, "/profile share output", "https://prbar.dev/");
  await page.goto(`${baseUrl}/maya.codes`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/maya.codes public link", "Maya R. Chen");
  await assertBodyIncludes(page, "/maya.codes public link", "PUBLISHED BUILDER PROOF");
  await page.goto(`${baseUrl}/maya.codes#builder-card`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/maya.codes#builder-card public link", "SHORT VERSION");
  await assertSectionNearTop(page, "/maya.codes#builder-card public link", "#builder-card");
  await page.goto(`${baseUrl}/#/profile`, { waitUntil: "networkidle" });
  await page.locator('.proof-share-rail [data-share-action="embed"]').click();
  await page.waitForFunction(() => document.body.innerText.includes("Copied embed snippet"));
  await assertBodyIncludes(page, "/profile embed output", "data-prbar-card");
  const cardDownload = page.waitForEvent("download");
  await page.locator('.proof-share-rail [data-share-action="image"]').click();
  const download = await cardDownload;
  if (download.suggestedFilename() !== "builder-card.svg") {
    throw new Error(`/profile card export expected builder-card.svg, got ${download.suggestedFilename()}`);
  }
  await assertBodyIncludes(page, "/profile image export feedback", "Downloaded builder-card.svg");
  await assertBodyIncludes(page, "/profile image export output", "<svg");
  await page.reload({ waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/profile persisted share feedback", "Downloaded builder-card.svg");
  await assertBodyIncludes(page, "/profile persisted share output", "<svg");
  await assertBodyIncludes(page, "/profile persisted source count", "4 selected sources power the card, receipt, app proof, and timeline.");

  await page.goto(`${baseUrl}/#/home`, { waitUntil: "networkidle" });
  await assertActiveProofStep(page, "/home published owner proof path", "Share anywhere");

  await page.goto(`${baseUrl}/#/profile`, { waitUntil: "networkidle" });
  await page.locator('.owner-hero-actions [data-preview-action="enter"]').click();
  await assertBodyIncludes(page, "/profile public preview state", "This is how signed-out visitors see Builder Proof.");
  await assertBodyIncludes(page, "/profile public preview product state", "PUBLIC PROSPECT VIEW");
  await assertBodyIncludes(page, "/profile public preview strip", "Public preview. Owner controls and GitHub connection details are hidden from visitors.");
  await assertLocatorCount(page, ".owner-proof-actions", "/profile public preview owner controls", 0);
  await assertLocatorIncludes(page, ".topbar-account", "/profile public preview topbar", "Public preview");
  await assertLocatorIncludes(page, ".topbar-account", "/profile public preview topbar exit", "Exit preview");
  await page.goto(`${baseUrl}/#/receipt`, { waitUntil: "networkidle" });
  await assertLocatorIncludes(page, ".topbar-account", "/receipt public preview topbar", "Public preview");
  await assertLocatorIncludes(page, ".topbar-account", "/receipt public preview topbar exit", "Exit preview");
  await assertLocatorExcludes(page, ".topbar-account", "/receipt public preview topbar profile", "Profile");
  await assertLocatorExcludes(page, ".topbar-account", "/receipt public preview topbar github", "GitHub connected");
  await assertLocatorExcludes(page, ".topbar-account", "/receipt public preview topbar logout", "Log out");
  await assertLocatorCount(page, ".owner-proof-actions", "/receipt public preview owner controls", 0);
  await page.locator('.topbar .nav button[data-section="/repos"]').click();
  await page.waitForURL(`${baseUrl}/repos`);
  await assertBodyExcludes(page, "/repos after public preview nav", "PUBLIC PROSPECT VIEW");
  await assertBodyIncludes(page, "/repos after public preview nav", "PUBLISHED OWNER");
  await assertLocatorIncludes(page, ".topbar-account", "/repos after public preview topbar owner", "GitHub connected");
  await page.goto(`${baseUrl}/#/profile`, { waitUntil: "networkidle" });
  await page.locator('.owner-hero-actions [data-preview-action="enter"]').click();
  await page.locator(".brand").click();
  await page.waitForURL(`${baseUrl}/home`);
  await assertActiveProofStep(page, "/home public preview proof path", "Share anywhere");
  await page.locator('.topbar .nav button[data-section="/profile"]').click();
  await page.waitForURL(`${baseUrl}/profile`);
  await assertBodyExcludes(page, "/profile public preview cleared", "This is how signed-out visitors see Builder Proof.");
  await assertBodyIncludes(page, "/profile owner controls restored", "Owner controls");

  for (const [route, expectedText, selector] of [
    ["#/card", "SHORT VERSION", "#builder-card"],
    ["#/receipt", "SideProject Radar v2.1", "#latest-receipt"],
    ["#/project", "Proof attaches to the things Maya shipped.", "#app-proof"],
  ]) {
    await page.goto(`${baseUrl}/${route}`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, route, expectedText);
    await assertBodyIncludes(page, route, "Open receipt section");
    await assertBodyExcludes(page, route, "Builder Proof is not published yet.");
    await assertSectionNearTop(page, route, selector);
    await assertNoHorizontalOverflow(page, route);
  }

  await page.goto(`${baseUrl}/#/account`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/account permissions", "GitHub");
  await assertBodyIncludes(page, "/account exports", "Exports");
  await assertBodyIncludes(page, "/account persistence", "Session, profile, selected sources, publish state, and share state persist in this browser");

  await page.goto(`${baseUrl}/#/user`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/user setup complete", "SETUP COMPLETE");
  await assertBodyIncludes(page, "/user setup source review", "4 selected sources confirmed for Builder Proof.");
  await assertBodyIncludes(page, "/user share output", "Share output created");

  await page.locator('.topbar-account [data-auth-action="logout"]').click();
  await page.waitForURL(`${baseUrl}/home`);
  await page.goto(`${baseUrl}/#/profile`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, "/profile signed-out public name", "Maya R. Chen");
  await assertBodyIncludes(page, "/profile signed-out product state", "PUBLIC PROSPECT VIEW");
  await assertBodyIncludes(page, "/profile signed-out public strip", "Public preview. Owner controls and GitHub connection details are hidden from visitors.");
  await assertBodyIncludes(page, "/profile prospect CTA", "Want proof like this?");
  await assertBodyIncludes(page, "/profile create proof CTA", "Create your Builder Proof");
  await assertLocatorCount(page, ".owner-proof-actions", "/profile signed-out owner controls", 0);
  await assertLocatorIncludes(page, ".topbar-account", "/profile signed-out topbar", "Sign in");
  await assertLocatorIncludes(page, ".topbar-account", "/profile signed-out topbar", "Claim builder card");
  await assertLocatorIncludes(page, ".topbar .nav", "/profile signed-out nav", "Sources & Privacy");

  await page.setViewportSize(desktopViewport);
  await page.goto(`${baseUrl}/profile`, { waitUntil: "networkidle" });
  await assertNoHorizontalOverflow(page, "/profile desktop");
}

async function main() {
  const server = spawn("npm", ["run", "start", "--", "-p", String(port), "-H", "127.0.0.1"], {
    cwd: __dirname,
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
    try {
      const page = await browser.newPage({ viewport: mobileViewport });
      await runChecks(page);
    } finally {
      await browser.close();
    }
  } catch (error) {
    console.error(output);
    throw error;
  } finally {
    server.kill("SIGTERM");
  }

  console.log("PRBar Next.js prototype smoke test passed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
