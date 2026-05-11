#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

APP_PATH="${1:-build/Build/Products/Release/PRMenuBar.app}"
EXECUTABLE="$APP_PATH/Contents/MacOS/PRMenuBar"

if [ ! -x "$EXECUTABLE" ]; then
  echo "Missing executable: $EXECUTABLE" >&2
  exit 1
fi

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)/smoke"

PASS=0
FAIL=0
FAILED=()

for scenario in "$SCENARIO_DIR"/*.sh; do
  name="$(basename "$scenario" .sh)"
  # Skip lib files (underscore-prefixed by convention).
  case "$name" in
    _*) continue ;;
  esac

  printf "  %-32s" "$name"
  if output="$(APP_EXECUTABLE="$EXECUTABLE" "$scenario" 2>&1)"; then
    printf "PASS\n"
    PASS=$((PASS + 1))
  else
    printf "FAIL\n"
    FAIL=$((FAIL + 1))
    FAILED+=("$name")
    printf -- '--- output of %s ---\n%s\n--- end output ---\n' "$name" "$output"
  fi
done

echo
TOTAL=$((PASS + FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "No scenarios found in $SCENARIO_DIR" >&2
  exit 1
fi

echo "Smoke summary: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  printf "Failed scenarios: %s\n" "${FAILED[*]}"
  exit 1
fi
