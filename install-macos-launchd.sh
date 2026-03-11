#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PLIST="$SCRIPT_DIR/launchd/com.shared-local-proxy.plist"
TARGET_PLIST="$HOME/Library/LaunchAgents/com.shared-local-proxy.plist"

mkdir -p "$HOME/Library/LaunchAgents"
cp "$SOURCE_PLIST" "$TARGET_PLIST"

launchctl unload "$TARGET_PLIST" >/dev/null 2>&1 || true
launchctl load "$TARGET_PLIST"
launchctl start com.shared-local-proxy || true

echo "Installed launchd agent: $TARGET_PLIST"
