#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required to list iOS devices." >&2
  exit 69
fi

echo "xctrace devices:"
xcrun xctrace list devices

echo
echo "devicectl devices:"
if xcrun devicectl list devices >/dev/null 2>&1; then
  xcrun devicectl list devices
else
  echo "devicectl is unavailable with the selected Xcode." >&2
fi
