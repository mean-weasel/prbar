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
PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
XCODEBUILD_EXTRA_ARGS=()

if [[ -n "${IOS_DEVELOPMENT_TEAM:-}" ]]; then
  XCODEBUILD_EXTRA_ARGS+=("DEVELOPMENT_TEAM=$IOS_DEVELOPMENT_TEAM")
fi

if [[ -n "${IOS_XCODEBUILD_EXTRA_ARGS:-}" ]]; then
  read -r -a USER_XCODEBUILD_EXTRA_ARGS <<<"$IOS_XCODEBUILD_EXTRA_ARGS"
  XCODEBUILD_EXTRA_ARGS+=("${USER_XCODEBUILD_EXTRA_ARGS[@]}")
fi

case "$PROFILE" in
  fast|pr)
    TESTS=("$UI_TEST_TARGET/$UI_TEST_TARGET/testPreviewDeviceCanLaunchCoreTabs")
    ;;
  full)
    TESTS=()
    ;;
  *)
    echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'" >&2
    exit 64
    ;;
esac

device_id="$(IOS_DEVICE_NAME="$DEVICE_NAME" ./scripts/ios-resolve-preview-device.sh)"

./scripts/ios-generate.sh
rm -rf "$RESULT_BUNDLE"

args=(
  test
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "platform=iOS,id=$device_id"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -resultBundlePath "$RESULT_BUNDLE"
)

for test_id in "${TESTS[@]}"; do
  args+=("-only-testing:$test_id")
done

args+=("${XCODEBUILD_EXTRA_ARGS[@]}")

xcodebuild "${args[@]}"
