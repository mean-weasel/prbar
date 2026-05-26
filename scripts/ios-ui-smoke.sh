#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
destination="$(./scripts/ios-resolve-simulator-destination.sh)"
TESTS=()
case "$PROFILE" in
  fast) TESTS=("PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces") ;;
  pr) TESTS=("PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces" "PRBarUITests/PRBarUITests/testShareTabExplainsWorkCardExport") ;;
  full) TESTS=() ;;
  *) echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'" >&2; exit 64 ;;
esac

args=(
  test
  -project apple/PRBar.xcodeproj
  -scheme "${IOS_SCHEME:-PRBar}"
  -configuration "${IOS_CONFIGURATION:-Debug}"
  -destination "$destination"
  -derivedDataPath apple/build
  -resultBundlePath "${IOS_UI_SMOKE_RESULT_BUNDLE:-apple/UISmokeResults.xcresult}"
)

if [[ "$destination" != *"platform=iOS,"* ]]; then
  args+=("CODE_SIGNING_ALLOWED=${IOS_CODE_SIGNING_ALLOWED:-NO}")
fi

if (( ${#TESTS[@]} > 0 )); then
  for test_id in "${TESTS[@]}"; do
    args+=("-only-testing:$test_id")
  done
fi

./scripts/ios-generate.sh
rm -rf "${IOS_UI_SMOKE_RESULT_BUNDLE:-apple/UISmokeResults.xcresult}"
xcodebuild "${args[@]}"
