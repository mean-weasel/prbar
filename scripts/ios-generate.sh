#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

node scripts/sync-product-version.mjs

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install with: brew install xcodegen" >&2
  exit 69
fi

xcodegen generate --spec apple/project.yml
