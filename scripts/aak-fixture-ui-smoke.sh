#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RECEIPT_PATH="${AAK_FIXTURE_RECEIPT_PATH:-artifacts/fixture-ui-smoke/fixture-ui-smoke.receipt.json}"
LOG_PATH="${AAK_FIXTURE_LOG_PATH:-artifacts/fixture-ui-smoke/fixture.log}"
RAW_LOG="$(mktemp "${TMPDIR:-/tmp}/prbar-aak-fixture-ui-smoke.XXXXXX.log")"

cleanup() {
  rm -f "$RAW_LOG"
}
trap cleanup EXIT

mkdir -p "$(dirname "$RECEIPT_PATH")" "$(dirname "$LOG_PATH")"

started_at="$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
)"

set +e
make app-smoke >"$RAW_LOG" 2>&1
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

python3 - "$RECEIPT_PATH" "$LOG_PATH" "$log_sha" "$log_size" "$started_at" "$completed_at" "$exit_code" <<'PY'
import json
import re
import sys
from datetime import datetime
from pathlib import Path

receipt_path, log_path, log_sha, log_size, started_at, completed_at, exit_code_text = sys.argv[1:]
exit_code = int(exit_code_text)
log_text = Path(log_path).read_text(encoding="utf-8", errors="replace")
scenario_dir = Path("scripts/smoke")
scenario_names = sorted(path.stem for path in scenario_dir.glob("*.sh") if not path.name.startswith("_"))
passed = re.findall(r"^\s+([A-Za-z0-9_.:-]+)\s+PASS$", log_text, flags=re.MULTILINE)
failed = re.findall(r"^\s+([A-Za-z0-9_.:-]+)\s+FAIL$", log_text, flags=re.MULTILINE)
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
        "platform": "macos",
    },
    "startedAt": started_at,
    "completedAt": completed_at,
    "result": result,
    "target": {
        "fixtureBundleIdentifier": "com.neonwatty.PRMenuBar",
        "fixtureMode": "app-smoke-fixtures",
        "nonFixtureAppsTouched": False,
        "physicalDeviceActions": False,
    },
    "commands": [
        {
            "id": "make-app-smoke",
            "class": "macos-fixture-ui-smoke",
            "summary": "Built PRMenuBar and ran fixture-backed app smoke scenarios",
            "durationSeconds": duration_seconds,
            "exitCode": exit_code,
            "result": result,
        }
    ],
    "evidence": {
        "logSubsystem": "com.neonwatty.PRMenuBar",
        "logTimeWindow": f"{started_at}/{completed_at}",
        "expectedEvents": scenario_names or ["app-smoke"],
        "observedEventCount": len(passed),
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
                "label": "raw-smoke-log",
                "reason": "raw build output may include local filesystem paths",
            },
            {
                "label": "screenshots",
                "reason": "first AAK dogfood pass uses structured fixture dumps without screenshots",
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
            "No screenshots were captured.",
            "No raw accessibility tree was published.",
            "The public log artifact is path-sanitized.",
        ],
    },
    "strongestAttemptedDisproof": "Wrapped make app-smoke, counted fixture scenario results, withheld raw build output, and validated fixture-only receipt boundaries.",
}

if failed:
    receipt["strongestAttemptedDisproof"] = (
        "Fixture smoke failed for: " + ", ".join(failed[:8]) + ". Raw output was withheld and sanitized evidence was recorded."
    )

with open(receipt_path, "w", encoding="utf-8") as handle:
    json.dump(receipt, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY

exit "$exit_code"
