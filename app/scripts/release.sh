#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Poppy"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Poppy.xcodeproj"
SCHEME="$APP_NAME"
CONFIGURATION="Release"
TEAM_ID="${DEVELOPMENT_TEAM:-4XRBD4BK9D}"
ARCHIVE_PATH="$ROOT_DIR/build/release/$APP_NAME.xcarchive"
EXPORT_PATH="$ROOT_DIR/build/release/export"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/$APP_NAME.app"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
APP_STORE_CONNECT_KEY_ID="${APP_STORE_CONNECT_KEY_ID:-}"
APP_STORE_CONNECT_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-}"
APP_STORE_CONNECT_API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-}"
VERSION=""
BUILD_NUMBER=""

usage() {
  cat <<'USAGE'
Usage:
  app/scripts/release.sh [options]

Options:
  --version VERSION             Override MARKETING_VERSION for the archive
  --build-number BUILD_NUMBER   Override CURRENT_PROJECT_VERSION for the archive
  -h, --help                    Show this help

Environment:
  CODESIGN_IDENTITY             Developer ID Application identity for signing the DMG
  DEVELOPMENT_TEAM              Apple Developer team ID; defaults to the project team
  NOTARY_PROFILE                notarytool keychain profile name

  Or, instead of NOTARY_PROFILE:
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_API_KEY_PATH
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

plist_value() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

notary_args=()
if [[ -n "$NOTARY_PROFILE" ]]; then
  notary_args=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n "$APP_STORE_CONNECT_KEY_ID" && -n "$APP_STORE_CONNECT_ISSUER_ID" && -n "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
  notary_args=(--key "$APP_STORE_CONNECT_API_KEY_PATH" --key-id "$APP_STORE_CONNECT_KEY_ID" --issuer "$APP_STORE_CONNECT_ISSUER_ID")
else
  echo "Missing notarization credentials. Set NOTARY_PROFILE or App Store Connect API key environment variables." >&2
  exit 1
fi

require_command xcodebuild
require_command xcrun
require_command codesign
require_command ditto
require_command spctl

rm -rf "$ROOT_DIR/build/release" "$APP_PATH"
mkdir -p "$DIST_DIR" "$EXPORT_PATH"

archive_args=(
  -project "$PROJECT_PATH"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
  DEVELOPMENT_TEAM="$TEAM_ID"
  CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="$CODESIGN_IDENTITY"
  PROVISIONING_PROFILE_SPECIFIER=
)

if [[ -n "$VERSION" ]]; then
  archive_args+=(MARKETING_VERSION="$VERSION")
fi

if [[ -n "$BUILD_NUMBER" ]]; then
  archive_args+=(CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
fi

echo "Archiving $APP_NAME..."
xcodebuild archive "${archive_args[@]}"

EXPORT_OPTIONS_PLIST="$ROOT_DIR/build/release/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>signingCertificate</key>
  <string>Developer ID Application</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
</dict>
</plist>
PLIST

echo "Exporting signed app..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

EXPORTED_APP="$EXPORT_PATH/$APP_NAME.app"
if [[ ! -d "$EXPORTED_APP" ]]; then
  echo "Missing exported app: $EXPORTED_APP" >&2
  exit 1
fi

ditto "$EXPORTED_APP" "$APP_PATH"

INFO_PLIST="$APP_PATH/Contents/Info.plist"
RESOLVED_VERSION="$(plist_value "$INFO_PLIST" CFBundleShortVersionString)"
RESOLVED_VERSION="${RESOLVED_VERSION:-$(plist_value "$INFO_PLIST" CFBundleVersion)}"
RESOLVED_VERSION="${RESOLVED_VERSION:-unknown}"

echo "Verifying app signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

NOTARY_UPLOAD_ZIP="$ROOT_DIR/build/release/$APP_NAME-notary-upload.zip"
echo "Creating notarization upload ZIP..."
ditto -c -k --keepParent "$APP_PATH" "$NOTARY_UPLOAD_ZIP"

echo "Submitting app for notarization..."
xcrun notarytool submit "$NOTARY_UPLOAD_ZIP" --wait "${notary_args[@]}"

echo "Stapling app notarization ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

APP_ZIP="$DIST_DIR/$APP_NAME-$RESOLVED_VERSION.zip"
echo "Creating distributable app ZIP..."
rm -f "$APP_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$APP_ZIP"

DMG_PATH="$DIST_DIR/$APP_NAME-$RESOLVED_VERSION.dmg"
echo "Creating DMG..."
"$ROOT_DIR/scripts/create_dmg.sh" --app "$APP_PATH" --output "$DMG_PATH" --version "$RESOLVED_VERSION" --force

echo "Signing DMG..."
codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

echo "Submitting DMG for notarization..."
xcrun notarytool submit "$DMG_PATH" --wait "${notary_args[@]}"

echo "Stapling DMG notarization ticket..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

echo "Release artifacts:"
printf '  %s\n' "$APP_PATH" "$APP_ZIP" "$DMG_PATH"
