const { chromium } = require("/Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright");

const baseUrl = "http://127.0.0.1:4181/";
const viewport = { width: 390, height: 844 };

const routes = [
  ["#/home", "Turn shipped work into Builder Proof."],
  ["#/signup", "Start with the short proof link."],
  ["#/signin", "Sign in to manage Builder Proof."],
  ["#/login", "Sign in to manage Builder Proof."],
  ["#/logout", "You're signed out."],
  ["#/onboarding", "Publish Builder Proof in four moves."],
  ["#/connect-github", "Bring in the facts, then choose what counts."],
  ["#/profile", "Builder Proof is not published yet."],
  ["#/user", "Sign in to manage Builder Proof."],
  ["#/edit-profile", "Sign in to edit this profile."],
  ["#/receipt", "Maya Chen"],
  ["#/project", "Maya Chen"],
  ["#/card", "Maya Chen"],
  ["#/repos", "Sources & Privacy"],
  ["#/account", "Sign in to manage account permissions."],
  ["#/studio", "Sources & Privacy"],
  ["#/trust", "Sources & Privacy"],
];

async function assertNoHorizontalOverflow(page, route) {
  const overflow = await page.evaluate(() => {
    const documentWidth = document.documentElement.scrollWidth;
    const bodyWidth = document.body ? document.body.scrollWidth : 0;
    const viewportWidth = document.documentElement.clientWidth;

    return {
      bodyWidth,
      documentWidth,
      overflow: Math.max(documentWidth, bodyWidth) - viewportWidth,
      viewportWidth,
    };
  });

  if (overflow.overflow > 1) {
    throw new Error(
      `${route} has horizontal overflow: document=${overflow.documentWidth}, body=${overflow.bodyWidth}, viewport=${overflow.viewportWidth}`
    );
  }
}

async function assertBodyIncludes(page, route, expectedText) {
  const bodyText = await page.locator("body").innerText();

  if (!bodyText.includes(expectedText)) {
    throw new Error(`${route} is missing expected text: ${expectedText}`);
  }
}

async function assertBodyExcludes(page, route, forbiddenText) {
  const bodyText = await page.locator("body").innerText();

  if (bodyText.includes(forbiddenText)) {
    throw new Error(`${route} still includes retired text: ${forbiddenText}`);
  }
}

async function assertLocatorIncludes(page, selector, route, expectedText) {
  const text = await page.locator(selector).innerText();

  if (!text.includes(expectedText)) {
    throw new Error(`${route} ${selector} is missing expected text: ${expectedText}`);
  }
}

async function assertLocatorExcludes(page, selector, route, forbiddenText) {
  const text = await page.locator(selector).innerText();

  if (text.includes(forbiddenText)) {
    throw new Error(`${route} ${selector} still includes retired text: ${forbiddenText}`);
  }
}

async function main() {
  const browser = await chromium.launch();

  try {
    const page = await browser.newPage({ viewport });
    await page.addInitScript(() => {
      window.localStorage.removeItem("prbar-profile");
      window.localStorage.removeItem("prbar-session");
      window.localStorage.removeItem("prbar-proof-workflow");
      window.localStorage.setItem("prbar-review-map-collapsed", "true");
      window.sessionStorage.clear();
    });

    for (const [route, expectedText] of routes) {
      await page.goto(`${baseUrl}${route}`, { waitUntil: "networkidle" });
      await assertBodyIncludes(page, route, expectedText);
      await assertNoHorizontalOverflow(page, route);
    }

    await page.goto(`${baseUrl}#/home`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/home nav", "Builder Proof");
    await assertBodyIncludes(page, "#/home nav", "Sources");
    await assertBodyIncludes(page, "#/home CTA", "Sign in");
    await assertBodyIncludes(page, "#/home value", "PRBar is a proof resume");
    await assertBodyExcludes(page, "#/home retired IA", "Proof Index");
    await assertBodyExcludes(page, "#/home retired IA", "Builder Search");
    await assertBodyExcludes(page, "#/home retired IA", "Mockup review map");
    const reviewMapHidden = await page.evaluate(() => document.body.classList.contains("toc-collapsed"));
    if (!reviewMapHidden) throw new Error("#/home should hide review map by default");

    await page.goto(`${baseUrl}#/card`, { waitUntil: "networkidle" });
    await assertBodyExcludes(page, "#/card setup duplicate", "Four obvious steps");
    await assertBodyExcludes(page, "#/card subpage tabs", "BUILDER PROOF PAGES");
    await assertBodyIncludes(page, "#/card fused card", "Builder card");
    await assertBodyIncludes(page, "#/card fused receipt", "Featured receipt");

    await page.goto(`${baseUrl}#/repos`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/repos setup", "Connect GitHub to choose sources.");
    await assertBodyExcludes(page, "#/repos subpage tabs", "SOURCES PAGES");

    await page.goto(`${baseUrl}#/dashboard`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/dashboard collapsed", "Sources & Privacy");

    await page.goto(`${baseUrl}#/profile`, { waitUntil: "networkidle" });
    await assertBodyExcludes(page, "#/profile subpage tabs", "BUILDER PROOF PAGES");
    await assertBodyIncludes(page, "#/profile unpublished state", "Builder Proof is not published yet.");

    await page.goto(`${baseUrl}#/studio`, { waitUntil: "networkidle" });
    await assertBodyExcludes(page, "#/studio subpage tabs", "SOURCES PAGES");
    await assertBodyIncludes(page, "#/studio fused editor", "Edit latest receipt");

    await page.goto(`${baseUrl}#/signup`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/signup flow", "Continue to GitHub");
    await assertBodyIncludes(page, "#/signup stepper", "Choose sources");

    await page.goto(`${baseUrl}#/signin`, { waitUntil: "networkidle" });
    await page.locator('.auth-panel [data-auth-action="login"]').click();
    await page.waitForURL(`${baseUrl}#/user`);
    await assertBodyIncludes(page, "#/user after login", "Log out");
    await assertBodyIncludes(page, "#/user after login", "Connect GitHub");
    await assertBodyIncludes(page, "#/user setup checklist", "FINISH SETUP");
    await assertBodyIncludes(page, "#/user checklist profile", "Profile claimed");
    await assertBodyIncludes(page, "#/user checklist github", "GitHub connected");
    await assertBodyIncludes(page, "#/user checklist sources", "Sources chosen");
    await assertBodyIncludes(page, "#/user checklist publish", "Builder Proof published");
    await assertBodyIncludes(page, "#/user checklist share", "Share link copied");

    await page.locator('.topbar-account [data-auth-action="logout"]').click();
    await page.waitForURL(`${baseUrl}#/home`);
    await assertBodyIncludes(page, "#/home after logout", "Sign in");
    await assertBodyIncludes(page, "#/home after logout", "Claim builder card");

    await page.goto(`${baseUrl}#/signup`, { waitUntil: "networkidle" });
    await page.locator('.auth-panel [data-auth-action="signup"]').click();
    await page.waitForURL(`${baseUrl}#/connect-github`);
    await assertBodyIncludes(page, "#/connect after signup", "Log out");
    await assertBodyIncludes(page, "#/connect after signup", "Connect GitHub");

    await page.goto(`${baseUrl}#/connect-github`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/connect-github permissions", "Release tags");
    await assertBodyIncludes(page, "#/connect-github CTA", "Authorize and choose sources");
    await page.locator('[data-auth-action="connect-github"]').click();
    await page.waitForURL(`${baseUrl}#/repos`);
    await assertBodyIncludes(page, "#/repos after connect", "GitHub connected");
    await assertBodyIncludes(page, "#/repos draft state", "Draft Builder Proof");
    await assertBodyIncludes(page, "#/repos publish CTA", "Publish Builder Proof");

    await page.goto(`${baseUrl}#/edit-profile`, { waitUntil: "networkidle" });
    await page.locator('[name="profile-name"]').fill("Maya R. Chen");
    await page.locator('[name="profile-handle"]').fill("@maya.rchen");
    await page.locator('[name="profile-title"]').fill("AI-native product engineer");
    await page.locator('[name="profile-availability"]').fill("Open to proof-driven launches");
    await page.locator('[name="profile-note"]').fill("Builds shipped products with selected GitHub proof.");
    await page.locator('[data-profile-action="save"]').click();
    await page.waitForURL(`${baseUrl}#/user`);
    await assertBodyIncludes(page, "#/user saved profile name", "Maya R. Chen");
    await assertBodyIncludes(page, "#/user saved profile handle", "@maya.rchen");

    await page.goto(`${baseUrl}#/repos`, { waitUntil: "networkidle" });

    const includeExperiments = page.locator('[data-source-id="maya/experiments"][data-source-action="include"]');
    if ((await includeExperiments.count()) !== 1) throw new Error("Missing include control for maya/experiments");
    await includeExperiments.click();
    await assertBodyIncludes(page, "#/repos live source count", "4 sources power Builder Proof");

    const attachExperiments = page.locator('[data-source-id="maya/experiments"][data-source-action="attach"]');
    if ((await attachExperiments.count()) !== 1) throw new Error("Missing app attachment control for maya/experiments");
    await attachExperiments.click();
    await assertBodyIncludes(page, "#/repos live attachment count", "3 attached apps");

    const excludeClient = page.locator('[data-source-id="client/stealth-onboarding"][data-source-action="exclude"]');
    if ((await excludeClient.count()) !== 1) throw new Error("Missing exclude control for client/stealth-onboarding");
    await excludeClient.click();
    await assertBodyIncludes(page, "#/repos live excluded count", "1 excluded");

    const publishButton = page.locator('[data-proof-action="publish"]');
    if ((await publishButton.count()) !== 1) throw new Error("Missing publish action");
    await publishButton.click();
    await assertBodyIncludes(page, "#/repos published state", "Builder Proof is live");
    await assertBodyIncludes(page, "#/repos share link", "Share link ready");

    await page.locator('[data-proof-action="open-public"]').click();
    await page.waitForURL(`${baseUrl}#/profile`);
    await assertBodyIncludes(page, "#/profile published badge", "PUBLISHED BUILDER PROOF");
    await assertBodyIncludes(page, "#/profile saved name", "Maya R. Chen");
    await assertBodyIncludes(page, "#/profile saved title", "AI-native product engineer");
    await assertBodyIncludes(page, "#/profile saved availability", "Open to proof-driven launches");
    await assertBodyIncludes(page, "#/profile saved note", "Builds shipped products with selected GitHub proof.");
    await assertBodyIncludes(page, "#/profile owner mode", "OWNER VIEW");
    await assertBodyIncludes(page, "#/profile owner controls", "Owner controls");
    await assertBodyIncludes(page, "#/profile owner edit", "Edit profile");
    await assertBodyExcludes(page, "#/profile owner should not show prospect CTA", "Create your Builder Proof");
    await assertBodyIncludes(page, "#/profile fused card after publish", "Builder card");
    await assertBodyIncludes(page, "#/profile fused receipt after publish", "CURRENT SHIPPED THING");
    await page.locator('.proof-share-rail [data-share-action="proof"]').click();
    await assertBodyIncludes(page, "#/profile share feedback", "Copied Builder Proof link");

    await page.goto(`${baseUrl}#/user`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/user completed checklist", "SETUP COMPLETE");
    await assertBodyIncludes(page, "#/user checklist copied", "Share link copied");

    await page.goto(`${baseUrl}#/account`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/account permissions", "GitHub");
    await assertBodyIncludes(page, "#/account exports", "Exports");

    await page.locator('.topbar-account [data-auth-action="logout"]').click();
    await page.waitForURL(`${baseUrl}#/home`);
    await page.goto(`${baseUrl}#/profile`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/profile signed-out public name", "Maya R. Chen");
    await assertBodyIncludes(page, "#/profile prospect CTA", "Want proof like this?");
    await assertBodyIncludes(page, "#/profile create proof CTA", "Create your Builder Proof");
    await assertBodyExcludes(page, "#/profile signed-out owner controls", "Owner controls");
    await assertLocatorIncludes(page, ".topbar-account", "#/profile signed-out topbar", "Sign in");
    await assertLocatorIncludes(page, ".topbar-account", "#/profile signed-out topbar", "Claim builder card");
    await assertLocatorExcludes(page, ".topbar-account", "#/profile signed-out topbar", "Log out");
    await assertLocatorExcludes(page, ".topbar-account", "#/profile signed-out topbar", "GitHub connected");
    await assertLocatorExcludes(page, ".topbar .nav", "#/profile signed-out nav", "Sources & Privacy");

    await page.goto(`${baseUrl}#/user`, { waitUntil: "networkidle" });
    await assertBodyIncludes(page, "#/user signed-out gate", "Sign in to manage Builder Proof.");
    await assertBodyExcludes(page, "#/user signed-out gate hides setup", "FINISH SETUP");
  } finally {
    await browser.close();
  }

  console.log("PRBar web prototype smoke test passed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
