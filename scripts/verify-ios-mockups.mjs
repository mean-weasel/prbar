import { readFileSync } from "node:fs";

const html = readFileSync("mockups/ios/index.html", "utf8");
const css = readFileSync("mockups/ios/styles.css", "utf8");
const js = readFileSync("mockups/ios/app.js", "utf8");

const requiredScreens = [
  "today-week",
  "today-day",
  "today-month",
  "activity-detail",
  "releases",
  "repo-filter",
  "card-entry",
  "card-composer",
  "card-clean",
  "card-terminal",
  "card-hype",
  "cards-gallery",
  "settings-auth"
];

const requiredStates = [
  "sample-data",
  "connected-github",
  "refreshing",
  "refresh-failed",
  "empty-range",
  "privacy-hidden",
  "high-activity",
  "first-run"
];

const requiredThemes = ["clean", "terminal", "launch", "hype", "minimal"];
const requiredRanges = ["day", "week", "month"];

function assertIncludes(source, needle, label) {
  if (!source.includes(needle)) {
    throw new Error(`Missing ${label}: ${needle}`);
  }
}

for (const screen of requiredScreens) {
  assertIncludes(html, `data-required-screen="${screen}"`, "screen");
}

for (const state of requiredStates) {
  assertIncludes(html, `data-state="${state}"`, "state");
}

for (const theme of requiredThemes) {
  assertIncludes(html, `data-theme="${theme}"`, "theme button");
  assertIncludes(css, `.share-card.${theme}`, "theme style");
  assertIncludes(js, `${theme}:`, "theme script copy");
}

for (const range of requiredRanges) {
  assertIncludes(html, `data-range="${range}"`, "range button");
  assertIncludes(html, `data-range-panel="${range}"`, "range panel");
}

assertIncludes(html, "Day / Week / Month", "approved range language");
assertIncludes(html, "Share proof of work", "cards positioning");
assertIncludes(html, "Make Release Card", "release card action");
assertIncludes(html, "Hide private repos", "privacy default");

console.log("iOS mockup verification passed");
