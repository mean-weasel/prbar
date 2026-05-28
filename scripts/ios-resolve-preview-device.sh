#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export IOS_SCHEME="${IOS_SCHEME:-PRBarPreview}"
export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
export IOS_DEVICE_ROLE="${IOS_DEVICE_ROLE:-preview device}"

exec ./scripts/ios-resolve-device.sh "$@"
