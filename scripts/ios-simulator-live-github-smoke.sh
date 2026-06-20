#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${IOS_SCHEME:-PRBar}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
SIMULATOR_NAME="${IOS_SIMULATOR_NAME:-iPhone 17}"
SIMULATOR_ID="${IOS_SIMULATOR_ID:-}"
BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/build}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphonesimulator/${SCHEME}.app"
LOG_DIR="${IOS_LIVE_GITHUB_SIM_LOG_DIR:-.codex/ios-live-github-simulator}"

prompt_value() {
  local var_name="$1"
  local prompt="$2"
  local current="${!var_name:-}"
  if [[ -z "$current" ]]; then
    read -r -p "$prompt" current
    export "$var_name=$current"
  fi
}

prompt_secret() {
  local var_name="$1"
  local prompt="$2"
  local current="${!var_name:-}"
  if [[ -z "$current" ]]; then
    read -r -s -p "$prompt" current
    printf '\n'
    export "$var_name=$current"
  fi
}

prompt_secret PRBAR_IOS_LIVE_GITHUB_TOKEN "GitHub token (input hidden): "
prompt_value PRBAR_IOS_LIVE_GITHUB_LOGIN "GitHub login for this token: "
prompt_value PRBAR_IOS_LIVE_REPOSITORY "Repository to demo (owner/repo): "

if [[ -z "${PRBAR_IOS_LIVE_GITHUB_TOKEN:-}" ||
  -z "${PRBAR_IOS_LIVE_GITHUB_LOGIN:-}" ||
  -z "${PRBAR_IOS_LIVE_REPOSITORY:-}" ]]; then
  echo "Token, login, and repository are required." >&2
  exit 64
fi

if [[ "$PRBAR_IOS_LIVE_REPOSITORY" != */* ]]; then
  echo "PRBAR_IOS_LIVE_REPOSITORY must look like owner/repo." >&2
  exit 64
fi

if [[ -z "$SIMULATOR_ID" ]]; then
  simulator_matches="$(
    xcrun simctl list devices available |
      SIMULATOR_NAME="$SIMULATOR_NAME" perl -ne 'BEGIN { $name = $ENV{"SIMULATOR_NAME"} } if (/^\s*\Q$name\E \(([0-9A-F-]+)\) \(([^)]+)\)/) { print "$1\t$2\n" }'
  )"
  simulator_match_count="$(printf '%s\n' "$simulator_matches" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$simulator_match_count" -eq 0 ]]; then
    echo "No available simulator named $SIMULATOR_NAME." >&2
    exit 66
  fi
  if [[ "$simulator_match_count" -gt 1 ]]; then
    echo "Multiple available simulators named $SIMULATOR_NAME. Set IOS_SIMULATOR_ID to one of:" >&2
    printf '%s\n' "$simulator_matches" >&2
    exit 64
  fi
  SIMULATOR_ID="$(printf '%s\n' "$simulator_matches" | cut -f1)"
fi

SIMULATOR_DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
SIMULATOR_LABEL="$SIMULATOR_NAME ($SIMULATOR_ID)"

mkdir -p "$LOG_DIR"
launch_log="$LOG_DIR/headless-live.log"

echo "Building $SCHEME for $SIMULATOR_LABEL..."
IOS_DESTINATION="$SIMULATOR_DESTINATION" ./scripts/ios-build.sh

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected built app at $APP_PATH." >&2
  exit 66
fi

echo "Booting $SIMULATOR_LABEL..."
xcrun simctl boot "$SIMULATOR_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b >/dev/null
open -a Simulator >/dev/null 2>&1 || true

echo "Installing $BUNDLE_ID..."
xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

echo "Running headless live GitHub smoke for $PRBAR_IOS_LIVE_REPOSITORY..."
: >"$launch_log"
set +e
env \
  SIMCTL_CHILD_PRBAR_IOS_LIVE_GITHUB_TOKEN="$PRBAR_IOS_LIVE_GITHUB_TOKEN" \
  SIMCTL_CHILD_PRBAR_IOS_LIVE_GITHUB_LOGIN="$PRBAR_IOS_LIVE_GITHUB_LOGIN" \
  SIMCTL_CHILD_PRBAR_IOS_LIVE_REPOSITORY="$PRBAR_IOS_LIVE_REPOSITORY" \
  xcrun simctl launch \
    --terminate-running-process \
    --console \
    "$SIMULATOR_ID" \
    "$BUNDLE_ID" \
    --live-github-smoke-headless 2>&1 | tee "$launch_log"
launch_status=${PIPESTATUS[0]}
set -e

if grep -q "PRBAR_LIVE_SMOKE_RESULT success" "$launch_log"; then
  echo "Live GitHub smoke succeeded."
elif grep -q "PRBAR_LIVE_SMOKE_RESULT failure" "$launch_log"; then
  echo "Live GitHub smoke reported a PRBar failure. See $launch_log." >&2
  exit 65
else
  echo "Live GitHub smoke did not emit a result marker. See $launch_log." >&2
  exit "$launch_status"
fi

echo "Launching PRBar visually with the seeded simulator session..."
env \
  SIMCTL_CHILD_PRBAR_IOS_LIVE_GITHUB_TOKEN="$PRBAR_IOS_LIVE_GITHUB_TOKEN" \
  SIMCTL_CHILD_PRBAR_IOS_LIVE_GITHUB_LOGIN="$PRBAR_IOS_LIVE_GITHUB_LOGIN" \
  SIMCTL_CHILD_PRBAR_IOS_LIVE_REPOSITORY="$PRBAR_IOS_LIVE_REPOSITORY" \
  xcrun simctl launch --terminate-running-process "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null
echo "Ready. Screenshot/log folder: $LOG_DIR"
