import { readFileSync } from "node:fs";

const html = readFileSync("mockups/ios/index.html", "utf8");
const css = readFileSync("mockups/ios/styles.css", "utf8");
const js = readFileSync("mockups/ios/app.js", "utf8");
const readme = readFileSync("mockups/ios/README.md", "utf8");

function assertIncludes(source, needle, label) {
  if (!source.includes(needle)) {
    throw new Error(`Missing ${label}: ${needle}`);
  }
}

const requiredHtml = [
  "data-prototype-app",
  "Interactive mobile app",
  "bottom nav",
  "More menu",
  "GitHub Releases",
  "Repo inclusion",
  "Cards from activity or GitHub Releases",
  "GitHub sign-in",
  "First-run onboarding"
];

const requiredCss = [
  ".bottom-nav",
  ".app-content",
  ".share-card.terminal",
  ".share-card.launch",
  ".share-card.hype",
  ".share-card.minimal",
  ".sheet-backdrop",
  ".bottom-sheet",
  ".card-back",
  ".evidence-list",
  ".card-actions",
  ".menu-list",
  ".repo-list",
  ".auth-screen",
  ".ios-list",
  ".status-banner",
  ".native-tabbar",
  ".permission-list",
  ".sync-steps"
];

const requiredJs = [
  "const repositories",
  "const pullRequests",
  "const releases",
  "activeTab",
  "activeMoreScreen",
  "activeSheet",
  "cardSide",
  "authState",
  "onboardingStep",
  "syncState",
  "applyInitialRoute",
  "renderWelcome",
  "renderPermissionRationale",
  "renderConnecting",
  "renderRepoSetup",
  "renderPrivacySetup",
  "renderSyncing",
  "renderAuthIssue",
  "renderEmptyState",
  "renderToday",
  "renderActivity",
  "renderReleases",
  "renderCards",
  "renderCardBackEvidence",
  "renderEditSheet",
  "renderShareSheet",
  "renderMore",
  "renderRepos",
  "Sign in with GitHub",
  "Continue to GitHub",
  "Choose repositories",
  "Private details warning",
  "Authorize SSO",
  "Reconnect GitHub",
  "Rate limit",
  "Last synced",
  "Make Release Card",
  "Open on GitHub",
  "Copy release notes",
  "Edit Card",
  "Share Card",
  "Share Front",
  "Share Back",
  "Share Both",
  "Copy Caption",
  "Included repos power Activity, Releases, and Cards.",
  "day",
  "week",
  "month"
];

const requiredReadme = [
  "Interactive HTML prototype",
  "Today / Activity / Releases / Cards / More",
  "First-run GitHub sign-in",
  "Permission rationale",
  "Repo setup",
  "Privacy defaults",
  "Sync and recovery states",
  "More menu with Repos, Settings, Privacy, Sample Data, and About",
  "fixture-backed",
  "Front/back card flip",
  "Share sheet"
];

for (const item of requiredHtml) assertIncludes(html, item, "HTML prototype marker");
for (const item of requiredCss) assertIncludes(css, item, "CSS selector");
for (const item of requiredJs) assertIncludes(js, item, "JavaScript behavior marker");
for (const item of requiredReadme) assertIncludes(readme, item, "README description");

console.log("iOS interactive prototype verification passed");
