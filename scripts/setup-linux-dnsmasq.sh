#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_CONF="$SCRIPT_DIR/dnsmasq/localhost.test.conf"
TARGET_CONF="/etc/dnsmasq.d/localhost.test.conf"

if ! command -v dnsmasq >/dev/null 2>&1; then
  echo "dnsmasq must be installed before running this script." >&2
  exit 1
fi

sudo mkdir -p /etc/dnsmasq.d
sudo cp "$SOURCE_CONF" "$TARGET_CONF"

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl restart dnsmasq
else
  echo "Restart dnsmasq manually; systemctl was not found." >&2
fi

echo "Configured dnsmasq for *.localhost.test"
echo "Config: $TARGET_CONF"
