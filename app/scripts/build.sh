#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/Poppy.app"

xcodebuild \
  -project "$ROOT_DIR/Poppy.xcodeproj" \
  -scheme Poppy \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

/usr/bin/open -n "$APP_PATH"
