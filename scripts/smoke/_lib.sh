#!/usr/bin/env bash
set -euo pipefail

: "${APP_EXECUTABLE:?APP_EXECUTABLE must be set (run via scripts/app-smoke.sh)}"

if [ ! -x "$APP_EXECUTABLE" ]; then
  echo "Missing or non-executable: $APP_EXECUTABLE" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
DUMP_PATH="$TMP_DIR/initial-state.json"
APP_PID=""
SMOKE_ASSERT_COUNT=0

cleanup() {
  if [ -n "$APP_PID" ]; then
    kill "$APP_PID" 2>/dev/null || true
    for _ in $(seq 1 20); do
      kill -0 "$APP_PID" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}

# Catches scenarios that exited 0 without calling any assertion — a "passes
# because nothing was checked" silent failure.
finalize() {
  local status=$?
  cleanup
  if [ "$status" -eq 0 ] && [ "$SMOKE_ASSERT_COUNT" -eq 0 ]; then
    echo "FAIL: scenario made no assertions (likely a bug in the scenario)" >&2
    exit 1
  fi
  exit "$status"
}
trap finalize EXIT

# Launches the app with any extra KEY=VAL env vars passed as args, plus
# PR_MENU_BAR_INITIAL_STATE_DUMP_PATH pointing at $DUMP_PATH. Sets $APP_PID.
smoke_launch() {
  env "$@" PR_MENU_BAR_INITIAL_STATE_DUMP_PATH="$DUMP_PATH" "$APP_EXECUTABLE" &
  APP_PID=$!
}

# Waits up to 5s for the dump file to be non-empty AND structurally complete
# (ends with `}`), then verifies the app is still alive — catches the case
# where the app writes the dump and crashes before assertions can run.
smoke_wait_for_dump() {
  for _ in $(seq 1 50); do
    if [ -s "$DUMP_PATH" ] && [ "$(tail -c1 "$DUMP_PATH")" = "}" ]; then
      if ! kill -0 "$APP_PID" 2>/dev/null; then
        echo "App exited before assertions could run (pid $APP_PID)" >&2
        exit 1
      fi
      return 0
    fi
    sleep 0.1
  done
  echo "App did not write complete initial state dump within 5s" >&2
  exit 1
}

smoke_assert_contains() {
  local pattern="$1"
  local description="${2:-content matches}"
  SMOKE_ASSERT_COUNT=$((SMOKE_ASSERT_COUNT + 1))
  if ! grep -Fq "$pattern" "$DUMP_PATH"; then
    echo "FAIL: $description (looking for: $pattern)" >&2
    echo "--- dump ---" >&2
    cat "$DUMP_PATH" >&2
    return 1
  fi
}

smoke_assert_not_contains() {
  local pattern="$1"
  local description="${2:-content excluded}"
  SMOKE_ASSERT_COUNT=$((SMOKE_ASSERT_COUNT + 1))
  if grep -Fq "$pattern" "$DUMP_PATH"; then
    echo "FAIL: $description (unexpected: $pattern)" >&2
    echo "--- dump ---" >&2
    cat "$DUMP_PATH" >&2
    return 1
  fi
}

# Asserts the dump contains a multi-line block verbatim (preserves ordering,
# unlike grep -F which matches each line independently).
smoke_assert_dump_contains_block() {
  local block="$1"
  local description="${2:-block matches}"
  SMOKE_ASSERT_COUNT=$((SMOKE_ASSERT_COUNT + 1))
  local content
  content="$(cat "$DUMP_PATH")"
  if [[ "$content" != *"$block"* ]]; then
    echo "FAIL: $description" >&2
    echo "--- expected block ---" >&2
    echo "$block" >&2
    echo "--- actual dump ---" >&2
    echo "$content" >&2
    return 1
  fi
}
