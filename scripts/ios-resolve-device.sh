#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
SCHEME="${IOS_SCHEME:-PRBarPreview}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
DEVICE_ROLE="${IOS_DEVICE_ROLE:-iOS device}"
MODE="${1:-id}"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required to resolve $DEVICE_ROLE '$DEVICE_NAME'." >&2
  exit 69
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse CoreDevice output." >&2
  exit 69
fi

if [[ ! -d "$PROJECT" ]] && [[ -x scripts/ios-generate.sh ]]; then
  ./scripts/ios-generate.sh >/dev/null
fi

json_file="$(mktemp "${TMPDIR:-/tmp}/prbar-ios-devices.XXXXXX")"
trap 'rm -f "$json_file"' EXIT

xcrun devicectl list devices --json-output "$json_file" >/dev/null

device_summary() {
  jq -r --arg name "$DEVICE_NAME" '
    .result.devices[]
    | select(.deviceProperties.name == $name)
    | [
        "  name=\(.deviceProperties.name // "unknown")",
        "identifier=\(.identifier // "unknown")",
        "model=\(.hardwareProperties.marketingName // "unknown")",
        "udid=\(.hardwareProperties.udid // "unknown")",
        "pairingState=\(.connectionProperties.pairingState // "unknown")",
        "tunnelState=\(.connectionProperties.tunnelState // "unknown")",
        "developerMode=\(.deviceProperties.developerModeStatus // "unknown")",
        "ddiServicesAvailable=\(.deviceProperties.ddiServicesAvailable // "unknown")",
        "lastConnection=\(.connectionProperties.lastConnectionDate // "unknown")"
      ]
    | join(" ")
  ' "$json_file" | head -n 1
}

coredevice_id="$(
  jq -r --arg name "$DEVICE_NAME" '
    .result.devices[]
    | select(.deviceProperties.name == $name)
    | .identifier
  ' "$json_file" | head -n 1
)"

if [[ -z "$coredevice_id" ]]; then
  echo "Could not find CoreDevice $DEVICE_ROLE named '$DEVICE_NAME'." >&2
  echo "Available devices:" >&2
  jq -r '.result.devices[] | "  \(.deviceProperties.name // "unknown") \(.identifier) pairing=\(.connectionProperties.pairingState // "unknown") tunnel=\(.connectionProperties.tunnelState // "unknown") \(.hardwareProperties.marketingName // "")"' "$json_file" >&2
  exit 69
fi

coredevice_tunnel_state="$(
  jq -r --arg name "$DEVICE_NAME" '
    .result.devices[]
    | select(.deviceProperties.name == $name)
    | .connectionProperties.tunnelState // "unknown"
  ' "$json_file" | head -n 1
)"
coredevice_pairing_state="$(
  jq -r --arg name "$DEVICE_NAME" '
    .result.devices[]
    | select(.deviceProperties.name == $name)
    | .connectionProperties.pairingState // "unknown"
  ' "$json_file" | head -n 1
)"

xcode_device_id="$(
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null \
    | awk -v name="$DEVICE_NAME" '
        $0 ~ /platform:iOS,/ && $0 !~ /Simulator/ && $0 ~ "name:" name {
          print
          exit
        }
      ' \
    | sed -n 's/.*id:\([^,}]*\).*/\1/p'
)"

if [[ -z "$xcode_device_id" ]]; then
  echo "Could not find Xcode iOS destination named '$DEVICE_NAME' for scheme '$SCHEME'." >&2
  echo "CoreDevice record:" >&2
  device_summary >&2
  if [[ "$coredevice_tunnel_state" == "unavailable" ]]; then
    cat >&2 <<EOF

The $DEVICE_ROLE is paired, but CoreDevice reports tunnelState=unavailable.
This is a runner/device availability blocker, not a PRBar app failure.

Bring '$DEVICE_NAME' back online, then rerun the workflow:
- keep the iPhone unlocked and awake
- connect it to this Mac or the same trusted local network
- confirm the trust prompt is accepted if iOS asks
- confirm Developer Mode remains enabled
- wait for Xcode to list '$DEVICE_NAME' as an iOS destination
EOF
  elif [[ "$coredevice_pairing_state" != "paired" ]]; then
    cat >&2 <<EOF

CoreDevice found '$DEVICE_NAME', but pairingState=$coredevice_pairing_state.
Pair/trust the device with this Mac before rerunning the workflow.
EOF
  else
    cat >&2 <<EOF

CoreDevice found '$DEVICE_NAME', but Xcode did not expose it as a destination.
This usually means the device is locked, asleep, offline, untrusted, busy
preparing developer services, or temporarily unavailable to Xcode.
EOF
  fi
  echo >&2
  echo "Available destinations:" >&2
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations >&2
  exit 70
fi

case "$MODE" in
  id)
    printf '%s\n' "$xcode_device_id"
    ;;
  shell)
    printf 'IOS_DEVICE_NAME=%q\n' "$DEVICE_NAME"
    printf 'IOS_DEVICE_ID=%q\n' "$coredevice_id"
    printf 'IOS_XCODE_DEVICE_ID=%q\n' "$xcode_device_id"
    printf 'IOS_DESTINATION=%q\n' "platform=iOS,id=$xcode_device_id"
    ;;
  human)
    printf 'Device role: %s\n' "$DEVICE_ROLE"
    printf 'Device name: %s\n' "$DEVICE_NAME"
    printf 'CoreDevice id: %s\n' "$coredevice_id"
    printf 'Xcode destination id: %s\n' "$xcode_device_id"
    printf 'Xcode destination: platform=iOS,id=%s\n' "$xcode_device_id"
    ;;
  *)
    echo "Usage: $0 [id|human|shell]" >&2
    exit 64
    ;;
esac
