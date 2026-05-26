#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/ios-generate.sh
rm -rf apple/TestResults.xcresult
destination="$(./scripts/ios-resolve-simulator-destination.sh)"
xcodebuild test \
  -project apple/PRBar.xcodeproj \
  -scheme "${IOS_SCHEME:-PRBar}" \
  -configuration "${IOS_CONFIGURATION:-Debug}" \
  -destination "$destination" \
  -derivedDataPath apple/build \
  -resultBundlePath apple/TestResults.xcresult \
  CODE_SIGNING_ALLOWED="${IOS_CODE_SIGNING_ALLOWED:-NO}"
