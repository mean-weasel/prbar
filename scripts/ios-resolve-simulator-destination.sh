#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${IOS_DESTINATION:-}" ]]; then
  printf '%s\n' "$IOS_DESTINATION"
  exit 0
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required to resolve an iOS simulator destination." >&2
  exit 69
fi

devices="$(xcrun simctl list devices available 2>/dev/null || true)"
preferred_names=(
  "iPhone 16"
  "iPhone 16 Pro"
  "iPhone 15"
  "iPhone 15 Pro"
  "iPhone 17"
)

for name in "${preferred_names[@]}"; do
  if grep -q "^[[:space:]]*$name (" <<<"$devices"; then
    printf 'platform=iOS Simulator,name=%s\n' "$name"
    exit 0
  fi
done

device_name="$(
  awk '
    /^[[:space:]]*iPhone .* \([A-F0-9-]+\) \(.*\)$/ {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      sub(/ \([A-F0-9-]+\).*$/, "", line)
      print line
      exit
    }
  ' <<<"$devices"
)"

if [[ -n "$device_name" ]]; then
  printf 'platform=iOS Simulator,name=%s\n' "$device_name"
  exit 0
fi

echo "Could not find an available iPhone simulator. Available devices:" >&2
if [[ -n "$devices" ]]; then
  echo "$devices" >&2
else
  echo "No available devices reported by simctl." >&2
fi
exit 66
