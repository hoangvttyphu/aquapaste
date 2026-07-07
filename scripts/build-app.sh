#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AquaPaste"
CONFIGURATION="${1:-release}"
BUILD_DIR="$ROOT_DIR/.build"
PRODUCT_DIR="$BUILD_DIR/$CONFIGURATION"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE_PATH="$PRODUCT_DIR/$APP_NAME"

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "Usage: $0 [debug|release]"
  exit 1
fi

echo "Building $APP_NAME ($CONFIGURATION)..."
swift build -c "$CONFIGURATION"

if [[ ! -f "$EXECUTABLE_PATH" ]]; then
  echo "Executable not found at $EXECUTABLE_PATH"
  exit 1
fi

echo "Packaging app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/AppBundle/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

echo "App bundle created at:"
echo "$APP_DIR"
