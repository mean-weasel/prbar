#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
KEYCHAIN="${IOS_PREVIEW_KEYCHAIN:-login.keychain-db}"

for command_name in xcodebuild xcrun xcodegen /usr/libexec/PlistBuddy; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is required for iOS preview runner workflows." >&2
    exit 69
  fi
done

if [[ ! -d "$PROJECT" ]]; then
  if [[ -x scripts/ios-generate.sh ]]; then
    ./scripts/ios-generate.sh
  fi
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "Expected Xcode project at '$PROJECT'. Run scripts/ios-generate.sh first." >&2
  exit 66
fi

if [[ -n "${IOS_PREVIEW_KEYCHAIN_PASSWORD:-}" ]]; then
  security unlock-keychain -p "$IOS_PREVIEW_KEYCHAIN_PASSWORD" "$KEYCHAIN"
  security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$IOS_PREVIEW_KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null
fi

if ! security find-identity -v -p codesigning | grep -Eq 'Apple Development|iPhone Developer'; then
  echo "No valid codesigning identity is visible to the runner." >&2
  echo "Install an Apple Development or iPhone Developer signing identity, or unlock the signing keychain." >&2
  exit 70
fi

device_id="$(IOS_DEVICE_NAME="$DEVICE_NAME" ./scripts/ios-resolve-preview-device.sh)"
echo "Resolved $DEVICE_NAME as $device_id"

lock_state_json="$(mktemp)"
if ! xcrun devicectl device info lockState --device "$device_id" --timeout 20 --json-output "$lock_state_json" >/dev/null; then
  rm -f "$lock_state_json"
  echo "The preview device '$DEVICE_NAME' is listed, but CoreDevice cannot query its lock state." >&2
  echo "Unlock and trust the iPhone, make sure Developer Mode is enabled, then retry." >&2
  exit 66
fi

if grep -Eiq '"isLocked"[[:space:]]*:[[:space:]]*true|"lockState"[[:space:]]*:[[:space:]]*"locked"|"deviceLockState"[[:space:]]*:[[:space:]]*"locked"' "$lock_state_json"; then
  rm -f "$lock_state_json"
  echo "The preview device '$DEVICE_NAME' is locked. Unlock it before running preview workflows." >&2
  exit 66
fi
rm -f "$lock_state_json"

xcodebuild -version
