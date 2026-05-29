#!/usr/bin/env bash
set -euo pipefail

export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-preview device}"
export IOS_SCHEME="${IOS_SCHEME:-PRBarPreview}"
export IOS_UI_SCHEME="${IOS_UI_SCHEME:-PRBarPreview}"
export IOS_UI_TEST_TARGET="${IOS_UI_TEST_TARGET:-PRBarPreviewUITests}"
export IOS_DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/PreviewSmokeBuild}"
export IOS_DEVICE_SMOKE_RESULT_BUNDLE="${IOS_DEVICE_SMOKE_RESULT_BUNDLE:-${IOS_PREVIEW_SMOKE_RESULT_BUNDLE:-apple/PreviewDeviceSmokeResults.xcresult}}"
export PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios.preview}"

exec ./scripts/ios-device-smoke.sh
