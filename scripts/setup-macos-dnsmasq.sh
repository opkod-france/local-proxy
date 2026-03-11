#!/usr/bin/env bash
set -euo pipefail

BREW_PREFIX=""
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
else
  echo "Homebrew is required for this setup." >&2
  exit 1
fi

DNSMASQ_CONF_DIR="$BREW_PREFIX/etc/dnsmasq.d"
DNSMASQ_CONF_FILE="$DNSMASQ_CONF_DIR/localhost.test.conf"
RESOLVER_DIR="/etc/resolver"
RESOLVER_FILE="$RESOLVER_DIR/localhost.test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_CONF="$SCRIPT_DIR/dnsmasq/localhost.test.conf"

mkdir -p "$DNSMASQ_CONF_DIR"
cp "$SOURCE_CONF" "$DNSMASQ_CONF_FILE"

sudo mkdir -p "$RESOLVER_DIR"
printf 'nameserver 127.0.0.1\n' | sudo tee "$RESOLVER_FILE" >/dev/null

brew services start dnsmasq

echo "Configured dnsmasq for *.localhost.test"
echo "Config: $DNSMASQ_CONF_FILE"
echo "Resolver: $RESOLVER_FILE"
