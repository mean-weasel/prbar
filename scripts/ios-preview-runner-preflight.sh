#!/usr/bin/env bash
set -euo pipefail

export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-preview device}"
export IOS_SCHEME="${IOS_SCHEME:-PRBarPreview}"
export IOS_UI_SCHEME="${IOS_UI_SCHEME:-PRBarPreview}"
export PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"

exec ./scripts/ios-physical-runner-preflight.sh
