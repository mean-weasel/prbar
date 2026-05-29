#!/usr/bin/env bash
set -euo pipefail

export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-preview device}"
export IOS_SCHEME="${IOS_SCHEME:-PRBarPreview}"
export IOS_PRODUCT_NAME="${IOS_PRODUCT_NAME:-PRBarPreview}"
export IOS_DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/PreviewBuild}"
export PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"

exec ./scripts/ios-install-app.sh
