#!/usr/bin/env bash
set -euo pipefail

export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-prod}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-production device}"
export IOS_SCHEME="${IOS_SCHEME:-PRBar}"
export IOS_PRODUCT_NAME="${IOS_PRODUCT_NAME:-PRBar}"
export IOS_DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-apple/ProductionBuild}"
export PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios}"
export IOS_LAUNCH_AFTER_INSTALL="${IOS_LAUNCH_AFTER_INSTALL:-1}"

exec ./scripts/ios-install-app.sh
