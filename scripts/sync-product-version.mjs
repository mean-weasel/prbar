#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const check = process.argv.includes("--check");
const productVersion = normalizeVersion(
  process.env.PRBAR_VERSION || readText("VERSION")
);
const buildNumber = normalizeOptional(
  process.env.PRBAR_BUILD_NUMBER || process.env.GITHUB_RUN_NUMBER
);
const macOSBuildNumber = normalizeOptional(
  process.env.PRBAR_MACOS_BUILD_NUMBER || buildNumber
);
const iOSBuildNumber = normalizeOptional(
  process.env.PRBAR_IOS_BUILD_NUMBER || buildNumber
);

const updates = [
  updateProjectVersion("project.yml", productVersion, macOSBuildNumber),
  updateProjectVersion("apple/project.yml", productVersion, iOSBuildNumber),
  updateWebVersion("apps/web/app/version.ts", productVersion),
];

const changed = updates.filter(Boolean);
if (check && changed.length > 0) {
  console.error(
    `Product version drift found in: ${changed.join(", ")}. Run npm run version:sync.`
  );
  process.exit(1);
}

if (changed.length > 0) {
  console.log(`Updated product version ${productVersion}: ${changed.join(", ")}`);
} else {
  console.log(`Product version ${productVersion} is already in sync.`);
}

function readText(relativePath) {
  return readFileSync(path.join(root, relativePath), "utf8").trim();
}

function writeText(relativePath, content) {
  if (!check) {
    writeFileSync(path.join(root, relativePath), content);
  }
}

function normalizeVersion(value) {
  const normalized = value.trim().replace(/^v/i, "");
  if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(normalized)) {
    throw new Error(`Invalid PRBar product version: ${value}`);
  }
  return normalized;
}

function normalizeOptional(value) {
  const normalized = (value || "").trim();
  return normalized.length > 0 ? normalized : null;
}

function updateProjectVersion(relativePath, version, build) {
  const original = readText(relativePath);
  let next = original.replace(
    /MARKETING_VERSION: "[^"]+"/,
    `MARKETING_VERSION: "${version}"`
  );

  if (build) {
    next = next.replace(
      /CURRENT_PROJECT_VERSION: "[^"]+"/,
      `CURRENT_PROJECT_VERSION: "${build}"`
    );
  }

  if (next === original) {
    return null;
  }

  writeText(relativePath, `${next}\n`);
  return relativePath;
}

function updateWebVersion(relativePath, version) {
  const original = readText(relativePath);
  const next = original.replace(
    /const fallbackMarketingVersion = "[^"]+";/,
    `const fallbackMarketingVersion = "${version}";`
  );

  if (next === original) {
    return null;
  }

  writeText(relativePath, `${next}\n`);
  return relativePath;
}
