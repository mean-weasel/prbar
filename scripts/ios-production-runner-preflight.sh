#!/usr/bin/env bash
set -euo pipefail

export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-prod}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-production device}"
export IOS_SCHEME="${IOS_SCHEME:-PRBar}"
export IOS_UI_SCHEME="${IOS_UI_SCHEME:-PRBar}"
export PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.neonwatty.PRBar.ios}"

exec ./scripts/ios-physical-runner-preflight.sh
