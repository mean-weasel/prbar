#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
SCHEME="${IOS_SCHEME:-PRBarPreview}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
DEVICE_ROLE="${IOS_DEVICE_ROLE:-iOS device}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/DeviceBuild}"
PRODUCT_NAME="${IOS_PRODUCT_NAME:-$SCHEME}"
EXPECTED_BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"
LAUNCH_AFTER_INSTALL="${IOS_LAUNCH_AFTER_INSTALL:-0}"
LAUNCH_TIMEOUT="${IOS_LAUNCH_TIMEOUT:-30}"
XCODEBUILD_EXTRA_ARGS=()

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

device_id="$(IOS_DEVICE_NAME="$DEVICE_NAME" IOS_DEVICE_ROLE="$DEVICE_ROLE" IOS_SCHEME="$SCHEME" IOS_PROJECT="$PROJECT" ./scripts/ios-resolve-device.sh)"

./scripts/ios-generate.sh
args=(
  build
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "platform=iOS,id=$device_id"
  -derivedDataPath "$DERIVED_DATA_PATH"
)

for extra_arg in "${XCODEBUILD_EXTRA_ARGS[@]+"${XCODEBUILD_EXTRA_ARGS[@]}"}"; do
  args+=("$extra_arg")
done

xcodebuild "${args[@]}"

app_path="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/${PRODUCT_NAME}.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app was not found at '$app_path'." >&2
  exit 66
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"
if [[ "$bundle_id" != "$EXPECTED_BUNDLE_ID" ]]; then
  echo "Refusing to install unexpected bundle id '$bundle_id' from $app_path" >&2
  echo "Expected bundle id: $EXPECTED_BUNDLE_ID" >&2
  exit 70
fi

echo "Installing $PRODUCT_NAME ($bundle_id) on $DEVICE_ROLE '$DEVICE_NAME'."
if [[ "${IOS_SKIP_INSTALL:-0}" == "1" ]]; then
  echo "IOS_SKIP_INSTALL=1; verified build output and bundle id without installing."
  exit 0
fi

xcrun devicectl device install app --device "$device_id" "$app_path"

if [[ "$LAUNCH_AFTER_INSTALL" == "1" ]]; then
  echo "Launching $bundle_id on $DEVICE_ROLE '$DEVICE_NAME'."
  xcrun devicectl device process launch \
    --device "$device_id" \
    "$bundle_id" \
    --terminate-existing \
    --timeout "$LAUNCH_TIMEOUT"
fi
