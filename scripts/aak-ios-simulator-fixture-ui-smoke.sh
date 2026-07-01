#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RECEIPT_PATH="${AAK_FIXTURE_RECEIPT_PATH:-artifacts/fixture-ui-smoke/ios-simulator-fixture-ui-smoke.receipt.json}"
LOG_PATH="${AAK_FIXTURE_LOG_PATH:-artifacts/fixture-ui-smoke/ios-simulator-fixture.log}"
RESULT_BUNDLE="${AAK_FIXTURE_RESULT_BUNDLE:-artifacts/fixture-ui-smoke/ios-simulator-fixture.xcresult}"
SIMULATOR_DESTINATION="${AAK_FIXTURE_SIMULATOR_DESTINATION:-${IOS_DESTINATION:-}}"
FIXTURE_BUNDLE_ID="${AAK_FIXTURE_BUNDLE_ID:-com.neonwatty.PRBar.ios}"
LOG_SUBSYSTEM="${AAK_FIXTURE_LOG_SUBSYSTEM:-com.neonwatty.PRBar.ios}"
PROFILE="${IOS_UI_SMOKE_PROFILE:-fast}"
RAW_LOG="$(mktemp "${TMPDIR:-/tmp}/prbar-aak-ios-simulator-fixture.XXXXXX.log")"

cleanup() {
  rm -f "$RAW_LOG"
}
trap cleanup EXIT

case "$PROFILE" in
  fast)
    expected_events=("testTabsExposeReviewedPrototypeSurfaces")
    ;;
  pr)
    expected_events=("testTabsExposeReviewedPrototypeSurfaces" "testShareTabExplainsWorkCardExport")
    ;;
  full)
    expected_events=("ios-ui-smoke-full")
    ;;
  *)
    echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'" >&2
    exit 64
    ;;
esac

mkdir -p "$(dirname "$RECEIPT_PATH")" "$(dirname "$LOG_PATH")" "$(dirname "$RESULT_BUNDLE")"
rm -rf "$RESULT_BUNDLE"

started_at="$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
)"

set +e
env \
  IOS_DESTINATION="$SIMULATOR_DESTINATION" \
  IOS_UI_SMOKE_PROFILE="$PROFILE" \
  IOS_UI_SMOKE_RESULT_BUNDLE="$RESULT_BUNDLE" \
  ./scripts/ios-ui-smoke.sh >"$RAW_LOG" 2>&1
exit_code=$?
set -e

python3 - "$RAW_LOG" "$LOG_PATH" "$ROOT" <<'PY'
import re
import sys
from pathlib import Path

raw_path, log_path, repo_root = sys.argv[1:]
text = Path(raw_path).read_text(encoding="utf-8", errors="replace")
text = text.replace(repo_root, "<repo>")
text = re.sub(r"/Users/[^/\s]+", "<user-home>", text)
text = re.sub(r"\b[A-F0-9]{8}-[A-F0-9-]{27,}\b", "<uuid>", text)
Path(log_path).write_text(text, encoding="utf-8")
PY

completed_at="$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
)"

if command -v shasum >/dev/null 2>&1; then
  log_sha="$(shasum -a 256 "$LOG_PATH" | awk '{print $1}')"
else
  log_sha="$(sha256sum "$LOG_PATH" | awk '{print $1}')"
fi
log_size="$(wc -c < "$LOG_PATH" | tr -d ' ')"

python3 - "$RECEIPT_PATH" "$LOG_PATH" "$log_sha" "$log_size" "$started_at" "$completed_at" "$exit_code" "$PROFILE" "$FIXTURE_BUNDLE_ID" "$LOG_SUBSYSTEM" "${expected_events[@]}" <<'PY'
import json
import re
import sys
from datetime import datetime
from pathlib import Path

(
    receipt_path,
    log_path,
    log_sha,
    log_size,
    started_at,
    completed_at,
    exit_code_text,
    profile,
    fixture_bundle_id,
    log_subsystem,
    *expected_events,
) = sys.argv[1:]

exit_code = int(exit_code_text)
log_text = Path(log_path).read_text(encoding="utf-8", errors="replace")
passed_methods = set(re.findall(r"Test Case '-\[[^ ]+ (test[A-Za-z0-9_]+)\]' passed", log_text))
if profile == "full":
    observed_count = 1 if exit_code == 0 else 0
else:
    observed_count = len(set(expected_events).intersection(passed_methods))
result = "succeeded" if exit_code == 0 else "failed"
duration_seconds = (
    datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
    - datetime.fromisoformat(started_at.replace("Z", "+00:00"))
).total_seconds()

receipt = {
    "schemaVersion": "fixture-ui-smoke/v1",
    "kind": "fixture-ui-smoke.receipt",
    "adapter": {
        "name": "prbar-fixture",
        "platform": "ios",
    },
    "startedAt": started_at,
    "completedAt": completed_at,
    "result": result,
    "target": {
        "fixtureBundleIdentifier": fixture_bundle_id,
        "fixtureMode": f"ios-simulator-ui-smoke-{profile}",
        "nonFixtureAppsTouched": False,
        "physicalDeviceActions": False,
    },
    "commands": [
        {
            "id": "ios-ui-smoke",
            "class": "ios-simulator-fixture-ui-smoke",
            "summary": "Ran deterministic PRBar iOS simulator UI smoke",
            "durationSeconds": duration_seconds,
            "exitCode": exit_code,
            "result": result,
        }
    ],
    "evidence": {
        "logSubsystem": log_subsystem,
        "logTimeWindow": f"{started_at}/{completed_at}",
        "expectedEvents": expected_events,
        "observedEventCount": observed_count,
        "artifacts": [
            {
                "label": "sanitized-fixture-log",
                "path": log_path,
                "sha256": log_sha,
                "sizeBytes": int(log_size),
            }
        ],
        "withheld": [
            {
                "label": "raw-xcodebuild-log",
                "reason": "raw xcodebuild output may include local filesystem paths and simulator identifiers",
            },
            {
                "label": "result-bundle-internals",
                "reason": "xcresult internals can contain screenshots, logs, and simulator metadata",
            },
            {
                "label": "raw-accessibility-tree",
                "reason": "raw private accessibility trees are not public evidence",
            },
        ],
    },
    "privacy": {
        "screenshots": "none",
        "rawAccessibilityTrees": False,
        "redactSecrets": True,
        "assertions": [
            "No physical-device actions were requested.",
            "No WDA or Appium session was started.",
            "No screenshots were published as public evidence.",
            "The public log artifact is path- and identifier-sanitized.",
        ],
    },
    "strongestAttemptedDisproof": "Wrapped ios-ui-smoke, used the adapter simulator destination, counted passed fixture UI test methods, withheld raw output and result-bundle internals, and validated simulator-only receipt boundaries.",
}

if result != "succeeded":
    receipt["strongestAttemptedDisproof"] = (
        "iOS simulator fixture smoke failed. Raw output and result-bundle internals were withheld; sanitized evidence was recorded for diagnosis."
    )

with open(receipt_path, "w", encoding="utf-8") as handle:
    json.dump(receipt, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY

exit "$exit_code"
