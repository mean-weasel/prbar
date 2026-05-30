#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
SCHEME="${IOS_UI_SCHEME:-PRBarPreview}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
DEVICE_ROLE="${IOS_DEVICE_ROLE:-iOS device}"
UI_TEST_TARGET="${IOS_UI_TEST_TARGET:-PRBarPreviewUITests}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/DeviceSmokeBuild}"
RESULT_BUNDLE="${IOS_DEVICE_SMOKE_RESULT_BUNDLE:-apple/DeviceSmokeResults.xcresult}"
PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"
PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
DEVICE_READY_TIMEOUT="${IOS_DEVICE_READY_TIMEOUT:-45}"
XCODEBUILD_EXTRA_ARGS=()
TEMP_FILES=()
HEADLESS_LIVE_SMOKE=0

cleanup() {
  for temp_file in "${TEMP_FILES[@]}"; do
    rm -f "$temp_file"
  done
}
trap cleanup EXIT

if [[ -z "${IOS_DESTINATION:-}" ]]; then
  echo "Resolving physical $DEVICE_ROLE by name: $DEVICE_NAME"
  resolver_output="$(IOS_DEVICE_NAME="$DEVICE_NAME" IOS_DEVICE_ROLE="$DEVICE_ROLE" IOS_SCHEME="$SCHEME" IOS_PROJECT="$PROJECT" ./scripts/ios-resolve-device.sh shell)"
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

if [[ -n "${PRBAR_IOS_LIVE_GITHUB_TOKEN:-}" || -n "${PRBAR_IOS_LIVE_REPOSITORY:-}" || -n "${PRBAR_IOS_LIVE_GITHUB_LOGIN:-}" ]]; then
  live_xcconfig="$(mktemp "${TMPDIR:-/tmp}/prbar-live-smoke.XXXXXX.xcconfig")"
  TEMP_FILES+=("$live_xcconfig")
  {
    if [[ -n "${PRBAR_IOS_LIVE_GITHUB_TOKEN:-}" ]]; then
      printf 'PRBAR_IOS_LIVE_GITHUB_TOKEN = %s\n' "$PRBAR_IOS_LIVE_GITHUB_TOKEN"
    fi
    if [[ -n "${PRBAR_IOS_LIVE_REPOSITORY:-}" ]]; then
      printf 'PRBAR_IOS_LIVE_REPOSITORY = %s\n' "$PRBAR_IOS_LIVE_REPOSITORY"
    fi
    if [[ -n "${PRBAR_IOS_LIVE_GITHUB_LOGIN:-}" ]]; then
      printf 'PRBAR_IOS_LIVE_GITHUB_LOGIN = %s\n' "$PRBAR_IOS_LIVE_GITHUB_LOGIN"
    fi
  } >"$live_xcconfig"
  XCODEBUILD_EXTRA_ARGS+=("-xcconfig" "$live_xcconfig")
fi

if [[ -n "${IOS_XCODEBUILD_EXTRA_ARGS:-}" ]]; then
  read -r -a USER_XCODEBUILD_EXTRA_ARGS <<<"$IOS_XCODEBUILD_EXTRA_ARGS"
  XCODEBUILD_EXTRA_ARGS+=("${USER_XCODEBUILD_EXTRA_ARGS[@]}")
fi

case "$PROFILE" in
  fast|pr)
    if [[ -n "${IOS_UI_SMOKE_TESTS:-}" ]]; then
      read -r -a TESTS <<<"$IOS_UI_SMOKE_TESTS"
    else
      TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testPreviewDeviceCanLaunchCoreTabs")
    fi
    ;;
  setup)
    TESTS=(
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testSignedOutGitHubDeviceAuthorizationContinuesToRepoSelection"
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testRepositorySetupSearchAndFiltersRepos"
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testFirstRunSelectsOneRepoFinishesSetupAndShowsSyncedActivity"
    )
    ;;
  version)
    TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testMoreSettingsAndAboutShowProductVersion")
    ;;
  partial)
    TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testPartialRefreshShowsRepositoryIssueAndKeepsSyncedData")
    ;;
  live|live-headless)
    if [[ -z "${PRBAR_IOS_LIVE_GITHUB_TOKEN:-}" ]]; then
      echo "PRBAR_IOS_LIVE_GITHUB_TOKEN is required for IOS_UI_SMOKE_PROFILE=$PROFILE." >&2
      exit 64
    fi
    export PRBAR_IOS_LIVE_REPOSITORY="${PRBAR_IOS_LIVE_REPOSITORY:-mean-weasel/prbar}"
    if [[ "$PROFILE" == "live-headless" ]]; then
      HEADLESS_LIVE_SMOKE=1
      TESTS=()
    else
      TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testLiveGitHubSelectsOneRepositoryAndSyncsActivity")
    fi
    ;;
  production)
    if [[ -z "${PRBAR_IOS_LIVE_GITHUB_TOKEN:-}" ]]; then
      echo "PRBAR_IOS_LIVE_GITHUB_TOKEN is required for IOS_UI_SMOKE_PROFILE=$PROFILE." >&2
      exit 64
    fi
    export PRBAR_IOS_LIVE_REPOSITORY="${PRBAR_IOS_LIVE_REPOSITORY:-mean-weasel/prbar}"
    TESTS=(
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testMoreSettingsAndAboutShowProductVersion"
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testFirstRunSelectsOneRepoFinishesSetupAndShowsSyncedActivity"
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testPullToRefreshUpdatesPRsAndReleases"
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testPartialRefreshShowsRepositoryIssueAndKeepsSyncedData"
      "$UI_TEST_TARGET/$UI_TEST_TARGET/testLiveGitHubSelectsOneRepositoryAndSyncsActivity"
    )
    ;;
  full)
    TESTS=()
    ;;
  *)
    echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'. Expected fast, pr, version, setup, partial, full, live, live-headless, or production." >&2
    exit 64
    ;;
esac

if [[ -z "${IOS_DEVICE_ID:-}" || -z "${IOS_DESTINATION:-}" ]]; then
  echo "Could not resolve physical $DEVICE_ROLE '$DEVICE_NAME'." >&2
  exit 64
fi

echo "Checking physical iOS device readiness for: $IOS_DEVICE_ID"
echo "Device role: $DEVICE_ROLE"
echo "Device name: $DEVICE_NAME"
echo "Xcode destination: $IOS_DESTINATION"
echo "Keep the iPhone unlocked and awake until the UI test starts."
if [[ "$PROFILE" == live* || "$PROFILE" == "production" ]]; then
  echo "Live GitHub smoke profile:"
  echo "  GitHub login: ${PRBAR_IOS_LIVE_GITHUB_LOGIN:-neonwatty}"
  echo "  Included repo: $PRBAR_IOS_LIVE_REPOSITORY"
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
TEMP_FILES+=("$lock_json")
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
  for extra_arg in "${XCODEBUILD_EXTRA_ARGS[@]+"${XCODEBUILD_EXTRA_ARGS[@]}"}"; do
    build_args+=("$extra_arg")
  done

  xcodebuild "${build_args[@]}"

  app_path="${IOS_APP_PATH:-$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app}"
  if [[ ! -d "$app_path" ]]; then
    echo "Expected built app at $app_path." >&2
    exit 66
  fi

  echo "Installing $PRODUCT_BUNDLE_IDENTIFIER on $DEVICE_NAME."
  xcrun devicectl device install app --device "$IOS_DEVICE_ID" "$app_path" --timeout 120

  launch_environment="$(
    jq -cn \
      --arg login "${PRBAR_IOS_LIVE_GITHUB_LOGIN:-neonwatty}" \
      --arg repo "$PRBAR_IOS_LIVE_REPOSITORY" \
      --arg token "$PRBAR_IOS_LIVE_GITHUB_TOKEN" \
      '{
        PRBAR_IOS_LIVE_GITHUB_LOGIN: $login,
        PRBAR_IOS_LIVE_REPOSITORY: $repo,
        PRBAR_IOS_LIVE_GITHUB_TOKEN: $token
      }'
  )"
  mkdir -p "$RESULT_BUNDLE"
  launch_log="$RESULT_BUNDLE/headless-live.log"
  : >"$launch_log"

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

if ((${#TESTS[@]} > 0)); then
  for test_id in "${TESTS[@]}"; do
    args+=("-only-testing:$test_id")
  done
fi

for extra_arg in "${XCODEBUILD_EXTRA_ARGS[@]+"${XCODEBUILD_EXTRA_ARGS[@]}"}"; do
  args+=("$extra_arg")
done

xcodebuild "${args[@]}"
