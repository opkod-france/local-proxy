#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_UNIT="$SCRIPT_DIR/systemd/shared-local-proxy.service"
TARGET_UNIT="$HOME/.config/systemd/user/shared-local-proxy.service"

mkdir -p "$HOME/.config/systemd/user"
cp "$SOURCE_UNIT" "$TARGET_UNIT"

systemctl --user daemon-reload
systemctl --user enable --now shared-local-proxy.service

echo "Installed systemd user unit: $TARGET_UNIT"
