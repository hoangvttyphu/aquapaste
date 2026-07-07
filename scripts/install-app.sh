#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AquaPaste"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
TARGET_DIR="/Applications"
TARGET_APP="$TARGET_DIR/$APP_NAME.app"

"$ROOT_DIR/scripts/build-app.sh" release

for running_app in AquaPaste ClipVault; do
  if pgrep -x "$running_app" >/dev/null 2>&1; then
    echo "Stopping running $running_app instance..."
    pkill -x "$running_app" || true
  fi
done
sleep 1

echo "Installing into $TARGET_DIR..."
rm -rf "$TARGET_APP"
rm -rf "$TARGET_DIR/ClipVault.app"
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "Installed at:"
echo "$TARGET_APP"

open "$TARGET_APP"
