#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required to list iOS devices." >&2
  exit 69
fi

echo "CoreDevice devices:"
if xcrun devicectl list devices >/dev/null 2>&1; then
  xcrun devicectl list devices
else
  echo "devicectl is unavailable with the selected Xcode." >&2
fi

echo
echo "Default preview device resolution:"
./scripts/ios-resolve-preview-device.sh human || true

echo
echo "xctrace devices:"
xcrun xctrace list devices || true

echo
echo "Xcode destinations for ${IOS_SCHEME:-PRBarPreview}:"
if [[ ! -d "${IOS_PROJECT:-apple/PRBar.xcodeproj}" ]] && [[ -x scripts/ios-generate.sh ]]; then
  ./scripts/ios-generate.sh >/dev/null
fi
xcodebuild \
  -project "${IOS_PROJECT:-apple/PRBar.xcodeproj}" \
  -scheme "${IOS_SCHEME:-PRBarPreview}" \
  -showdestinations 2>/dev/null || true
