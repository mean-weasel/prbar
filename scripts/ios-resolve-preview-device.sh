#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required to resolve '$DEVICE_NAME'." >&2
  exit 69
fi

devices="$(xcrun xctrace list devices 2>/dev/null || true)"
device_id="$(awk -v name="$DEVICE_NAME" '
  $0 ~ "^" name " \\(" && $0 !~ /Simulator/ {
    line = $0
    sub(/^.*\(/, "", line)
    sub(/\).*$/, "", line)
    print line
    exit
  }
' <<<"$devices")"

if [[ -z "$device_id" ]]; then
  echo "Could not find a trusted physical iOS device named '$DEVICE_NAME'." >&2
  echo "Available devices:" >&2
  if [[ -n "$devices" ]]; then
    echo "$devices" >&2
  else
    echo "No devices reported by xcrun xctrace." >&2
  fi
  echo "Set IOS_DEVICE_NAME to the exact iPhone name, then retry." >&2
  exit 66
fi

printf '%s\n' "$device_id"
