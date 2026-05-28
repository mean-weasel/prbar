#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
SCHEME="${IOS_UI_SCHEME:-PRBarPreview}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
UI_TEST_TARGET="${IOS_UI_TEST_TARGET:-PRBarPreviewUITests}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/PreviewSmokeBuild}"
RESULT_BUNDLE="${IOS_PREVIEW_SMOKE_RESULT_BUNDLE:-apple/PreviewDeviceSmokeResults.xcresult}"
PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"
PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
DEVICE_READY_TIMEOUT="${IOS_DEVICE_READY_TIMEOUT:-45}"
XCODEBUILD_EXTRA_ARGS=()
HEADLESS_LIVE_SMOKE=0

if [[ -z "${IOS_DESTINATION:-}" ]]; then
  echo "Resolving physical preview device by name: $DEVICE_NAME"
  resolver_output="$(IOS_DEVICE_NAME="$DEVICE_NAME" IOS_SCHEME="$SCHEME" IOS_PROJECT="$PROJECT" ./scripts/ios-resolve-preview-device.sh shell)"
  eval "$resolver_output"
  export IOS_DEVICE_ID IOS_XCODE_DEVICE_ID IOS_DESTINATION
else
  destination_id="$(printf '%s\n' "$IOS_DESTINATION" | sed -n 's/.*id=\([^,]*\).*/\1/p')"
  export IOS_XCODE_DEVICE_ID="${IOS_XCODE_DEVICE_ID:-$destination_id}"
  export IOS_DEVICE_ID="${IOS_DEVICE_ID:-$destination_id}"
fi

if [[ -n "${IOS_DEVELOPMENT_TEAM:-}" ]]; then
  XCODEBUILD_EXTRA_ARGS+=("DEVELOPMENT_TEAM=$IOS_DEVELOPMENT_TEAM")
fi

if [[ -n "${PRBAR_IOS_GITHUB_CLIENT_ID:-}" ]]; then
  XCODEBUILD_EXTRA_ARGS+=("PRBAR_IOS_GITHUB_CLIENT_ID=$PRBAR_IOS_GITHUB_CLIENT_ID")
fi

if [[ -n "${IOS_XCODEBUILD_EXTRA_ARGS:-}" ]]; then
  read -r -a USER_XCODEBUILD_EXTRA_ARGS <<<"$IOS_XCODEBUILD_EXTRA_ARGS"
  XCODEBUILD_EXTRA_ARGS+=("${USER_XCODEBUILD_EXTRA_ARGS[@]}")
fi

case "$PROFILE" in
  fast|pr)
    TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testPreviewDeviceCanLaunchCoreTabs")
    ;;
  live|live-headless)
    if [[ -z "${IOS_LIVE_GITHUB_LOGIN:-}" ]]; then
      echo "IOS_LIVE_GITHUB_LOGIN is required for IOS_UI_SMOKE_PROFILE=$PROFILE." >&2
      exit 64
    fi
    if [[ -z "${IOS_LIVE_INCLUDED_REPO:-}" ]]; then
      echo "IOS_LIVE_INCLUDED_REPO is required for IOS_UI_SMOKE_PROFILE=$PROFILE." >&2
      exit 64
    fi
    if [[ "$PROFILE" == "live-headless" ]]; then
      HEADLESS_LIVE_SMOKE=1
      TESTS=()
    else
      TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testLiveGitHubOneRepositoryRefresh")
    fi
    ;;
  full)
    TESTS=()
    ;;
  *)
    echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'" >&2
    exit 64
    ;;
esac

if [[ -z "${IOS_DEVICE_ID:-}" || -z "${IOS_DESTINATION:-}" ]]; then
  echo "Could not resolve physical preview device '$DEVICE_NAME'." >&2
  exit 64
fi

echo "Checking physical iOS device readiness for: $IOS_DEVICE_ID"
echo "Device role: $DEVICE_NAME"
echo "Xcode destination: $IOS_DESTINATION"
echo "Keep the iPhone unlocked and awake until the UI test starts."
if [[ "$PROFILE" == live* ]]; then
  echo "Live GitHub smoke profile:"
  echo "  GitHub login: $IOS_LIVE_GITHUB_LOGIN"
  echo "  Included repo: $IOS_LIVE_INCLUDED_REPO"
  echo "  Auth source: existing PRBar Keychain session on the target iPhone"
  if [[ "$HEADLESS_LIVE_SMOKE" == "1" ]]; then
    echo "  Driver: devicectl app launch"
  fi
fi

ready_deadline=$((SECONDS + DEVICE_READY_TIMEOUT))
while true; do
  if xcrun devicectl device info details --device "$IOS_DEVICE_ID" --quiet --timeout 10 >/dev/null 2>&1; then
    break
  fi

  if [[ "$SECONDS" -ge "$ready_deadline" ]]; then
    cat >&2 <<EOF
Device '$IOS_DEVICE_ID' was not ready within ${DEVICE_READY_TIMEOUT}s.

Make sure the iPhone is:
- connected to this Mac
- trusted by this Mac
- unlocked and awake

Run './scripts/ios-list-devices.sh' to verify the CoreDevice identifier, then retry.
EOF
    exit 69
  fi

  sleep 3
done

lock_json="$(mktemp "${TMPDIR:-/tmp}/prbar-device-lock.XXXXXX")"
trap 'rm -f "$lock_json"' EXIT
if xcrun devicectl device info lockState --device "$IOS_DEVICE_ID" --json-output "$lock_json" --quiet --timeout 10 >/dev/null 2>&1; then
  echo "Device lock state:"
  jq -r '.result | "  passcodeRequired=\(.passcodeRequired) unlockedSinceBoot=\(.unlockedSinceBoot)"' "$lock_json"
else
  echo "Could not read device lock state; continuing to xcodebuild, which will fail if the phone is locked." >&2
fi

./scripts/ios-generate.sh
rm -rf "$RESULT_BUNDLE"

if [[ "$HEADLESS_LIVE_SMOKE" == "1" ]]; then
  build_args=(
    build
    -project "$PROJECT"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -destination "$IOS_DESTINATION"
    -derivedDataPath "$DERIVED_DATA_PATH"
  )
  build_args+=("${XCODEBUILD_EXTRA_ARGS[@]}")

  xcodebuild "${build_args[@]}"

  app_path="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/PRBarPreview.app"
  if [[ ! -d "$app_path" ]]; then
    echo "Expected built preview app at $app_path." >&2
    exit 66
  fi

  echo "Installing $PRODUCT_BUNDLE_IDENTIFIER on $DEVICE_NAME."
  xcrun devicectl device install app --device "$IOS_DEVICE_ID" "$app_path" --timeout 120

  launch_environment="$(
    jq -cn \
      --arg login "$IOS_LIVE_GITHUB_LOGIN" \
      --arg repo "$IOS_LIVE_INCLUDED_REPO" \
      '{PRBAR_LIVE_SMOKE_GITHUB_LOGIN: $login, PRBAR_LIVE_SMOKE_INCLUDED_REPO: $repo}'
  )"
  mkdir -p "$RESULT_BUNDLE"
  launch_log="$RESULT_BUNDLE/headless-live.log"
  : >"$launch_log"
  trap 'rm -f "$lock_json"' EXIT

  echo "Launching headless live GitHub smoke on $DEVICE_NAME."
  set +e
  xcrun devicectl device process launch \
    --device "$IOS_DEVICE_ID" \
    --terminate-existing \
    --console \
    --timeout "${IOS_LIVE_HEADLESS_TIMEOUT:-180}" \
    --environment-variables "$launch_environment" \
    "$PRODUCT_BUNDLE_IDENTIFIER" \
    --live-github-smoke-headless 2>&1 | tee "$launch_log"
  launch_status=${PIPESTATUS[0]}
  set -e

  if grep -q "PRBAR_LIVE_SMOKE_RESULT success" "$launch_log"; then
    exit 0
  fi

  if grep -q "PRBAR_LIVE_SMOKE_RESULT failure" "$launch_log"; then
    echo "Headless live GitHub smoke reported a PRBar failure." >&2
    exit 65
  fi

  echo "Headless live GitHub smoke did not emit a PRBAR_LIVE_SMOKE_RESULT marker." >&2
  exit "$launch_status"
fi

args=(
  test
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "$IOS_DESTINATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -resultBundlePath "$RESULT_BUNDLE"
)

for test_id in "${TESTS[@]}"; do
  args+=("-only-testing:$test_id")
done

args+=("${XCODEBUILD_EXTRA_ARGS[@]}")

run_xcodebuild() {
  local log_path="$1"
  set +e
  xcodebuild "${args[@]}" 2>&1 | tee "$log_path"
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

check_device_unlocked() {
  local retry_lock_json
  retry_lock_json="$(mktemp "${TMPDIR:-/tmp}/prbar-device-lock-retry.XXXXXX")"
  if xcrun devicectl device info lockState --device "$IOS_DEVICE_ID" --json-output "$retry_lock_json" --quiet --timeout 10 >/dev/null 2>&1; then
    echo "Device lock state before retry:"
    jq -r '.result | "  passcodeRequired=\(.passcodeRequired) unlockedSinceBoot=\(.unlockedSinceBoot)"' "$retry_lock_json"
    if [[ "$(jq -r '.result.passcodeRequired' "$retry_lock_json")" == "true" ]]; then
      rm -f "$retry_lock_json"
      echo "The preview iPhone locked before UI automation could start. Unlock $DEVICE_NAME and retry." >&2
      exit 69
    fi
  else
    echo "Could not re-check device lock state before retry; continuing with one retry." >&2
  fi
  rm -f "$retry_lock_json"
}

xcodebuild_log="$(mktemp "${TMPDIR:-/tmp}/prbar-preview-xcodebuild.XXXXXX.log")"
trap 'rm -f "$lock_json" "$xcodebuild_log"' EXIT

if run_xcodebuild "$xcodebuild_log"; then
  exit 0
fi

if grep -q "Timed out while enabling automation mode" "$xcodebuild_log"; then
  cat <<EOF
Xcode timed out while enabling Automation Mode for UI testing.

This can happen on physical iPhones even after the runner Mac has been configured
with automationmodetool. Re-checking that $DEVICE_NAME is still unlocked, then
retrying the UI test once.
EOF
  check_device_unlocked
  sleep "${IOS_AUTOMATION_MODE_RETRY_DELAY:-10}"
  rm -rf "$RESULT_BUNDLE"
  if run_xcodebuild "$xcodebuild_log"; then
    exit 0
  fi

  if grep -q "Timed out while enabling automation mode" "$xcodebuild_log"; then
    cat >&2 <<EOF
Xcode still timed out while enabling Automation Mode after one retry.

Likely blocker: Automation Mode or device wake state on the physical preview
iPhone, before PRBar's live GitHub smoke test can launch. Keep $DEVICE_NAME
unlocked and awake, then retry the workflow. If this repeats, run this once from
an interactive admin session on the runner Mac:

  automationmodetool enable-automationmode-without-authentication
EOF
  fi
fi

exit 65
