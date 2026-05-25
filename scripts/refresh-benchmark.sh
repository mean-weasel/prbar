#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH="build/refresh-benchmark.json"
PROJECT="PRMenuBar.xcodeproj"
SCHEME="PRMenuBar"
DESTINATION="platform=macOS"
DERIVED_DATA="build"

xcodegen generate
mkdir -p "$(dirname "$REPORT_PATH")"
rm -f "$REPORT_PATH"

PR_MENU_BAR_REFRESH_BENCHMARK_REPORT="$REPORT_PATH" \
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:PRMenuBarTests/RefreshBenchmarkTests \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

test -s "$REPORT_PATH"
cat "$REPORT_PATH"
