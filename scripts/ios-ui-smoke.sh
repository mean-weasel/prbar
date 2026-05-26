#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
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
  -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
  -derivedDataPath apple/build
)

if [[ "${IOS_DESTINATION:-}" != *"platform=iOS,"* ]]; then
  args+=("CODE_SIGNING_ALLOWED=${IOS_CODE_SIGNING_ALLOWED:-NO}")
fi

for test_id in "${TESTS[@]}"; do
  args+=("-only-testing:$test_id")
done

./scripts/ios-generate.sh
xcodebuild "${args[@]}"
