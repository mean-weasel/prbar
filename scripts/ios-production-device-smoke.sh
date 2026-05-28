#!/usr/bin/env bash
set -euo pipefail

export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-prod}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-production device}"
export IOS_SCHEME="${IOS_SCHEME:-PRBar}"
export IOS_UI_SCHEME="${IOS_UI_SCHEME:-PRBar}"
export IOS_UI_TEST_TARGET="${IOS_UI_TEST_TARGET:-PRBarUITests}"
export IOS_UI_SMOKE_TESTS="${IOS_UI_SMOKE_TESTS:-PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces}"
export IOS_DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/ProductionSmokeBuild}"
export IOS_DEVICE_SMOKE_RESULT_BUNDLE="${IOS_DEVICE_SMOKE_RESULT_BUNDLE:-apple/ProductionDeviceSmokeResults.xcresult}"
export PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios}"

exec ./scripts/ios-device-smoke.sh
