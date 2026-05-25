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
  "Cards from activity or GitHub Releases"
];

const requiredCss = [
  ".bottom-nav",
  ".app-content",
  ".share-card.terminal",
  ".share-card.launch",
  ".share-card.hype",
  ".share-card.minimal",
  ".menu-list",
  ".repo-list"
];

const requiredJs = [
  "const repositories",
  "const pullRequests",
  "const releases",
  "activeTab",
  "activeMoreScreen",
  "renderToday",
  "renderActivity",
  "renderReleases",
  "renderCards",
  "renderMore",
  "renderRepos",
  "Make Release Card",
  "Open on GitHub",
  "Copy release notes",
  "Included repos power Activity, Releases, and Cards.",
  "day",
  "week",
  "month"
];

const requiredReadme = [
  "Interactive HTML prototype",
  "Today / Activity / Releases / Cards / More",
  "More menu with Repos, Settings, Privacy, Sample Data, and About",
  "fixture-backed"
];

for (const item of requiredHtml) assertIncludes(html, item, "HTML prototype marker");
for (const item of requiredCss) assertIncludes(css, item, "CSS selector");
for (const item of requiredJs) assertIncludes(js, item, "JavaScript behavior marker");
for (const item of requiredReadme) assertIncludes(readme, item, "README description");

console.log("iOS interactive prototype verification passed");
