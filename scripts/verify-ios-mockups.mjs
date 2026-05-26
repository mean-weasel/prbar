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
  "Work cards from PRs or GitHub Releases",
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
  ".sync-steps",
  ".calendar-panel",
  ".day-strip",
  ".month-grid"
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
  "renderActivity",
  "renderActivityRepoDetail",
  "renderCalendar",
  "select-pr-date",
  "selectedPrRepoId",
  "select-activity-repo",
  "renderReleases",
  "releaseRange",
  "select-release-date",
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
  "Shipping moments",
  "Calendar",
  "Generated tag summary",
  "tag and PR activity",
  "Style & Privacy",
  "Export card",
  "Share public-side image",
  "Export evidence side",
  "Export both sides",
  "Copy caption",
  "Included repos power PRs, Releases, and Cards.",
  "Public side",
  "Evidence side",
  "day",
  "week",
  "month"
];

const requiredReadme = [
  "Interactive HTML prototype",
  "PRs / Releases / Share / More",
  "First-run GitHub sign-in",
  "Permission rationale",
  "Repo setup",
  "Privacy defaults",
  "Sync and recovery states",
  "More menu with Repos, Settings, Privacy, Sample Data, and About",
  "fixture-backed",
  "Public/evidence card sides",
  "Export sheet"
];

for (const item of requiredHtml) assertIncludes(html, item, "HTML prototype marker");
for (const item of requiredCss) assertIncludes(css, item, "CSS selector");
for (const item of requiredJs) assertIncludes(js, item, "JavaScript behavior marker");
for (const item of requiredReadme) assertIncludes(readme, item, "README description");

console.log("iOS interactive prototype verification passed");
