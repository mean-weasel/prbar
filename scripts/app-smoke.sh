#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-build/Build/Products/Release/PRMenuBar.app}"
EXECUTABLE="$APP_PATH/Contents/MacOS/PRMenuBar"

if [ ! -x "$EXECUTABLE" ]; then
  echo "Missing executable: $EXECUTABLE"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
FIXTURE_PATH="$TMP_DIR/live-fixture.json"
DUMP_PATH="$TMP_DIR/initial-state.json"

cleanup() {
  if [ -n "${APP_PID:-}" ]; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cat >"$FIXTURE_PATH" <<'JSON'
{
  "bucketLabels": ["04/26"],
  "dailyBucketLabels": ["04/29", "04/30", "05/01", "05/02", "05/03", "05/04", "05/05"],
  "window": "1 week",
  "bin": "Day",
  "refreshInterval": "Daily",
  "repositories": [
    {
      "id": "mean-weasel/deckchecker",
      "owner": "mean-weasel",
      "name": "deckchecker",
      "colorHex": "#818cf8",
      "weeklyCounts": [9],
      "dailyCounts": [0, 0, 0, 0, 0, 9, 0],
      "isIncluded": true
    }
  ],
  "refreshedAt": 1777924800
}
JSON

PR_MENU_BAR_FIXTURE_PATH="$FIXTURE_PATH" \
PR_MENU_BAR_INITIAL_STATE_DUMP_PATH="$DUMP_PATH" \
"$EXECUTABLE" &
APP_PID=$!

for _ in $(seq 1 50); do
  if [ -s "$DUMP_PATH" ]; then
    break
  fi
  sleep 0.1
done

if [ ! -s "$DUMP_PATH" ]; then
  echo "App did not write initial state dump"
  exit 1
fi

grep -q '"dataSourceTitle" : "GitHub"' "$DUMP_PATH"
grep -q '"totalPullRequests" : 9' "$DUMP_PATH"
grep -q '"activeRepositoryCount" : 1' "$DUMP_PATH"
grep -Fq '"bucketTotals" : [' "$DUMP_PATH"
if grep -q '"totalPullRequests" : 462' "$DUMP_PATH" || grep -q '70' "$DUMP_PATH"; then
  echo "Smoke fixture unexpectedly produced sample-data totals"
  cat "$DUMP_PATH"
  exit 1
fi
