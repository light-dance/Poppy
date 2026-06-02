#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Poppy"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/dmg"
ASSET_DIR="$ROOT_DIR/assets/dmg"
BACKGROUND_PATH="$ASSET_DIR/background.png"
BACKGROUND_2X_PATH="$ASSET_DIR/background@2x.png"
VOLUME_ICON_PATH=""
WINDOW_WIDTH=680
WINDOW_HEIGHT=489
WINDOW_X=200
WINDOW_Y=120
APP_ICON_X=190
APP_ICON_Y=205
APPLICATIONS_ICON_X=490
APPLICATIONS_ICON_Y=205
ICON_SIZE=104
FORCE=0
OUTPUT_PATH=""
VERSION=""

usage() {
  cat <<'USAGE'
Usage:
  app/scripts/create_dmg.sh [options]

Options:
  --app PATH              App bundle to package. Default: app/dist/Poppy.app
  --output PATH           Final DMG path. Default: app/dist/Poppy-<version>.dmg
  --version VERSION       Version used in default output name. Default: app Info.plist version
  --force                 Replace an existing output DMG
  -h, --help              Show this help

Example:
  app/scripts/create_dmg.sh --force
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_PATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
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

require_command hdiutil
require_command osascript

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle: $APP_PATH" >&2
  exit 1
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "Missing app Info.plist: $INFO_PLIST" >&2
  exit 1
fi

APP_BUNDLE_NAME="$(basename "$APP_PATH")"
APP_DISPLAY_NAME="$(plist_value "$INFO_PLIST" CFBundleDisplayName)"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-$(plist_value "$INFO_PLIST" CFBundleName)}"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-${APP_BUNDLE_NAME%.app}}"
VERSION="${VERSION:-$(plist_value "$INFO_PLIST" CFBundleShortVersionString)}"
VERSION="${VERSION:-$(plist_value "$INFO_PLIST" CFBundleVersion)}"
VERSION="${VERSION:-1.0.0}"
VOLUME_NAME="$APP_DISPLAY_NAME"
OUTPUT_PATH="${OUTPUT_PATH:-$DIST_DIR/$APP_DISPLAY_NAME-$VERSION.dmg}"

VOLUME_ICON_PATH="$APP_PATH/Contents/Resources/AppIcon.icns"

if [[ -e "$OUTPUT_PATH" && "$FORCE" -ne 1 ]]; then
  echo "Output already exists: $OUTPUT_PATH" >&2
  echo "Pass --force to replace it." >&2
  exit 1
fi

if [[ -e "$OUTPUT_PATH" ]]; then
  rm -f "$OUTPUT_PATH"
fi

mkdir -p "$DIST_DIR" "$BUILD_DIR"

WORK_DMG="$BUILD_DIR/$APP_DISPLAY_NAME-$VERSION.rw.dmg"
FINAL_STAGING_DMG="$BUILD_DIR/$APP_DISPLAY_NAME-$VERSION.compressed.dmg"
MOUNT_DIR="$BUILD_DIR/mount"

rm -f "$WORK_DMG" "$FINAL_STAGING_DMG"
mkdir -p "$MOUNT_DIR"

if [[ -d "/Volumes/$VOLUME_NAME" ]]; then
  echo "Detaching existing /Volumes/$VOLUME_NAME..."
  hdiutil detach "/Volumes/$VOLUME_NAME" -quiet || true
fi

APP_SIZE_KB="$(du -sk "$APP_PATH" | awk '{print $1}')"
IMAGE_SIZE_MB="$((APP_SIZE_KB / 1024 + 160))"
if [[ "$IMAGE_SIZE_MB" -lt 256 ]]; then
  IMAGE_SIZE_MB=256
fi

echo "Creating writable disk image..."
hdiutil create \
  "$WORK_DMG" \
  -volname "$VOLUME_NAME" \
  -size "${IMAGE_SIZE_MB}m" \
  -fs HFS+ \
  -ov >/dev/null

DEVICE=""
cleanup() {
  if [[ -n "$DEVICE" ]]; then
    hdiutil detach "$DEVICE" -quiet || true
  fi
}
trap cleanup EXIT

echo "Mounting disk image..."
ATTACH_OUTPUT="$(hdiutil attach "$WORK_DMG" -readwrite -noverify -noautoopen -mountpoint "$MOUNT_DIR")"
DEVICE="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/Apple_HFS/ {print $1; exit}')"

echo "Copying app..."
ditto "$APP_PATH" "$MOUNT_DIR/$APP_BUNDLE_NAME"
ln -s /Applications "$MOUNT_DIR/Applications"

if [[ -f "$BACKGROUND_PATH" ]]; then
  mkdir -p "$MOUNT_DIR/.background"
  cp "$BACKGROUND_PATH" "$MOUNT_DIR/.background/background.png"
  if [[ -f "$BACKGROUND_2X_PATH" ]]; then
    cp "$BACKGROUND_2X_PATH" "$MOUNT_DIR/.background/background@2x.png"
  fi
else
  echo "No background image found at $BACKGROUND_PATH; DMG will use Finder's default background." >&2
fi

if [[ -f "$VOLUME_ICON_PATH" ]]; then
  cp "$VOLUME_ICON_PATH" "$MOUNT_DIR/.VolumeIcon.icns"
  if command -v SetFile >/dev/null 2>&1; then
    SetFile -a C "$MOUNT_DIR"
  else
    echo "SetFile not found; mounted volume icon may not be applied." >&2
  fi
else
  echo "No volume icon found at $VOLUME_ICON_PATH; mounted volume will use default disk icon." >&2
fi

echo "Applying Finder layout..."
osascript <<APPLESCRIPT
tell application "Finder"
  set dmgFolder to POSIX file "$MOUNT_DIR" as alias
  open dmgFolder
  delay 1
  set dmgWindow to container window of dmgFolder
  set current view of dmgWindow to icon view
  try
    set toolbar visible of dmgWindow to false
  end try
  try
    set statusbar visible of dmgWindow to false
  end try
  set bounds of dmgWindow to {$WINDOW_X, $WINDOW_Y, $((WINDOW_X + WINDOW_WIDTH)), $((WINDOW_Y + WINDOW_HEIGHT))}

  set iconViewOptions to the icon view options of dmgWindow
  set arrangement of iconViewOptions to not arranged
  set icon size of iconViewOptions to $ICON_SIZE

  try
    set background picture of iconViewOptions to (POSIX file "$MOUNT_DIR/.background/background@2x.png" as alias)
  on error
    try
      set background picture of iconViewOptions to (POSIX file "$MOUNT_DIR/.background/background.png" as alias)
    end try
  end try

  set position of item "$APP_BUNDLE_NAME" of dmgFolder to {$APP_ICON_X, $APP_ICON_Y}
  set position of item "Applications" of dmgFolder to {$APPLICATIONS_ICON_X, $APPLICATIONS_ICON_Y}
  update dmgFolder without registering applications
  try
    set statusbar visible of dmgWindow to false
  end try
  try
    set toolbar visible of dmgWindow to false
  end try
  delay 1
  close dmgWindow
end tell
APPLESCRIPT

sync
sync

echo "Detaching disk image..."
hdiutil detach "$DEVICE" -quiet
DEVICE=""

echo "Compressing disk image..."
hdiutil convert "$WORK_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_STAGING_DMG" >/dev/null
mv "$FINAL_STAGING_DMG" "$OUTPUT_PATH"

echo "Created $OUTPUT_PATH"
