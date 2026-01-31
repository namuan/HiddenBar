#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_PATH="$SCRIPT_DIR/Hidden Bar.xcodeproj"
SCHEME="Hidden Bar"
CONFIGURATION="Release"

DERIVED_DATA_PATH="$SCRIPT_DIR/build"
APP_NAME="Hidden Bar.app"

BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"
DEST_DIR="$HOME/Applications"
DEST_APP_PATH="$DEST_DIR/$APP_NAME"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "error: Xcode project not found at: $PROJECT_PATH" >&2
  exit 1
fi

mkdir -p "$DERIVED_DATA_PATH"

echo "Building $SCHEME ($CONFIGURATION)..."
/usr/bin/xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "error: build output not found at: $BUILT_APP_PATH" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

if [[ -e "$DEST_APP_PATH" ]]; then
  echo "Removing existing: $DEST_APP_PATH"
  rm -rf "$DEST_APP_PATH"
fi

echo "Installing to: $DEST_APP_PATH"
/usr/bin/ditto "$BUILT_APP_PATH" "$DEST_APP_PATH"

echo "Done."
