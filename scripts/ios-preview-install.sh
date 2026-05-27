#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
SCHEME="${IOS_SCHEME:-PRBarPreview}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/PreviewBuild}"
EXPECTED_BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"
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

device_id="$(IOS_DEVICE_NAME="$DEVICE_NAME" ./scripts/ios-resolve-preview-device.sh)"

./scripts/ios-generate.sh
xcodebuild \
  build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS,id=$device_id" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  "${XCODEBUILD_EXTRA_ARGS[@]}"

app_path="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/PRBarPreview.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app was not found at '$app_path'." >&2
  exit 66
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"
if [[ "$bundle_id" != "$EXPECTED_BUNDLE_ID" ]]; then
  echo "Refusing to install unexpected bundle id '$bundle_id' from $app_path" >&2
  exit 70
fi

xcrun devicectl device install app --device "$device_id" "$app_path"
