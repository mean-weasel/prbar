#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
RESULT_BUNDLE="${IOS_UI_SMOKE_RESULT_BUNDLE:-apple/UISmokeResults.xcresult}"
AAK_SCRIPT="${AAK_SCRIPT_PATH:-.aak/apple-agent-kit/scripts/aak.py}"

EXPECTED_TESTS=()
case "$PROFILE" in
  fast)
    EXPECTED_TESTS=("PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces")
    ;;
  pr | full)
    EXPECTED_TESTS=(
      "PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces"
      "PRBarUITests/PRBarUITests/testShareTabExplainsWorkCardExport"
    )
    ;;
  *)
    echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'" >&2
    exit 64
    ;;
esac

if [[ ! -f "$AAK_SCRIPT" ]]; then
  echo "AAK script not found at $AAK_SCRIPT" >&2
  exit 66
fi

args=(assert-xcresult --path "$RESULT_BUNDLE" --require-success --json)
for test_id in "${EXPECTED_TESTS[@]}"; do
  args+=(--expect-test "$test_id")
done

python3 "$AAK_SCRIPT" "${args[@]}"
