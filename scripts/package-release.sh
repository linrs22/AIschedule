#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=${1:-0.1.0}
DERIVED_DATA="$ROOT_DIR/DerivedData"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DERIVED_DATA/Build/Products/Release/AIschedule.app"
ZIP_PATH="$DIST_DIR/AIschedule-$VERSION-macOS.zip"

rm -rf "$DERIVED_DATA" "$DIST_DIR"
mkdir -p "$DIST_DIR"

xcodebuild \
  -quiet \
  -project "$ROOT_DIR/SunMoonSchedule.xcodeproj" \
  -scheme SunMoonSchedule \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

codesign --force --deep --sign - "$APP_PATH"
ditto -c -k --keepParent --norsrc "$APP_PATH" "$ZIP_PATH"

echo "Created $ZIP_PATH"
