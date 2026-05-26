#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="${ROOT_DIR:-$SCRIPT_ROOT}"
PROJECT="${PROJECT:-PRMenuBar.xcodeproj}"
SCHEME="${SCHEME:-PRMenuBar}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/release}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
STAGING_DIR="${STAGING_DIR:-$ROOT_DIR/build/release-staging}"
APP_NAME="${APP_NAME:-PRMenuBar}"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
STAGED_APP="$STAGING_DIR/$APP_NAME.app"
ARTIFACT_NAME="${ARTIFACT_NAME:-$APP_NAME-macOS.zip}"
ARTIFACT_PATH="$DIST_DIR/$ARTIFACT_NAME"
NOTARY_ZIP="$DIST_DIR/$APP_NAME-notary-submission.zip"
REQUIRE_NOTARIZATION="${PRBAR_REQUIRE_NOTARIZATION:-0}"
SIGNING_IDENTITY="${PRBAR_SIGNING_IDENTITY:-}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

has_apple_id_notary_credentials() {
  [ -n "${APPLE_ID:-}" ] &&
    [ -n "${APPLE_TEAM_ID:-}" ] &&
    [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]
}

has_notary_profile() {
  [ -n "${PRBAR_NOTARY_KEYCHAIN_PROFILE:-}" ]
}

notarization_available() {
  has_notary_profile || has_apple_id_notary_credentials
}

submit_for_notarization() {
  if has_notary_profile; then
    xcrun notarytool submit "$NOTARY_ZIP" \
      --keychain-profile "$PRBAR_NOTARY_KEYCHAIN_PROFILE" \
      --wait
  else
    xcrun notarytool submit "$NOTARY_ZIP" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_APP_SPECIFIC_PASSWORD" \
      --wait
  fi
}

need xcodebuild
need xcrun
need ditto

cd "$ROOT_DIR"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
else
  echo "error: xcodegen is required to generate $PROJECT" >&2
  exit 1
fi

rm -rf "$DERIVED_DATA" "$STAGING_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

build_args=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration Release
  -destination "platform=macOS"
  -derivedDataPath "$DERIVED_DATA"
)

if [ -n "$SIGNING_IDENTITY" ]; then
  echo "Building Release app with signing identity: $SIGNING_IDENTITY"
  xcodebuild build "${build_args[@]}" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-}" \
    OTHER_CODE_SIGN_FLAGS="--timestamp"
else
  echo "Building Release app with ad-hoc signing."
  xcodebuild build "${build_args[@]}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO
fi

test -d "$APP_BUNDLE" || {
  echo "error: expected app bundle not found: $APP_BUNDLE" >&2
  exit 1
}

ditto "$APP_BUNDLE" "$STAGED_APP"

if [ -n "$SIGNING_IDENTITY" ]; then
  codesign --force --deep --options runtime --timestamp \
    --sign "$SIGNING_IDENTITY" "$STAGED_APP"
fi

codesign --verify --deep --strict --verbose=2 "$STAGED_APP"
codesign -dv --verbose=4 "$STAGED_APP" 2>&1 | tee "$DIST_DIR/codesign.txt"

if [ -n "$SIGNING_IDENTITY" ] && notarization_available; then
  echo "Creating notarization submission zip."
  ditto -c -k --keepParent "$STAGED_APP" "$NOTARY_ZIP"

  echo "Submitting app for notarization."
  submit_for_notarization

  echo "Stapling notarization ticket."
  xcrun stapler staple "$STAGED_APP"
  xcrun stapler validate "$STAGED_APP"
elif [ "$REQUIRE_NOTARIZATION" = "1" ]; then
  echo "error: notarization required, but signing/notary configuration is incomplete." >&2
  echo "Set PRBAR_SIGNING_IDENTITY plus either PRBAR_NOTARY_KEYCHAIN_PROFILE or APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD." >&2
  exit 1
else
  echo "warning: notarization skipped; artifact is for local validation only." >&2
fi

rm -f "$ARTIFACT_PATH"
ditto -c -k --keepParent "$STAGED_APP" "$ARTIFACT_PATH"
shasum -a 256 "$ARTIFACT_PATH" | tee "$DIST_DIR/$ARTIFACT_NAME.sha256"

echo "Created $ARTIFACT_PATH"
