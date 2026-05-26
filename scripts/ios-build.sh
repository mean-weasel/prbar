#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/ios-generate.sh
xcodebuild build \
  -project apple/PRBar.xcodeproj \
  -scheme "${IOS_SCHEME:-PRBar}" \
  -configuration "${IOS_CONFIGURATION:-Debug}" \
  -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 16}" \
  -derivedDataPath apple/build \
  CODE_SIGNING_ALLOWED="${IOS_CODE_SIGNING_ALLOWED:-NO}"
