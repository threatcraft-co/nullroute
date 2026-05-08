#!/usr/bin/env bash
# Nullroute — update ClearURLs rules
# https://github.com/threatcraft-co/nullroute
#
# Fetches a fresh copy of the ClearURLs rules file from the official source
# and verifies the SHA256 hash before replacing the local copy.
#
# This is the ONLY time Nullroute touches the network, and only when you
# explicitly run this script. The daemon itself never makes network calls.

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }

INSTALL_DIR="$HOME/.nullroute"
RULES_URL="https://rules2.clearurls.xyz/data.minify.json"
HASH_URL="https://rules2.clearurls.xyz/rules.minify.hash"
TMP_RULES="$(mktemp)"
TMP_HASH="$(mktemp)"

echo -e "\n${BOLD}Nullroute — update rules${RESET}\n"

if [[ ! -d "$INSTALL_DIR" ]]; then
    error "Nullroute does not appear to be installed at $INSTALL_DIR"
    error "Run install.sh first."
    exit 1
fi

info "Fetching rules from $RULES_URL ..."
if ! curl -fsSL "$RULES_URL" -o "$TMP_RULES"; then
    error "Failed to download rules. Check your network connection."
    rm -f "$TMP_RULES" "$TMP_HASH"
    exit 1
fi

info "Fetching hash from $HASH_URL ..."
if ! curl -fsSL "$HASH_URL" -o "$TMP_HASH"; then
    error "Failed to download hash file."
    rm -f "$TMP_RULES" "$TMP_HASH"
    exit 1
fi

# Verify hash
EXPECTED_HASH=$(cat "$TMP_HASH" | tr '[:upper:]' '[:lower:]' | awk '{print $1}')
ACTUAL_HASH=$(shasum -a 256 "$TMP_RULES" | awk '{print $1}')

if [[ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]]; then
    error "Hash mismatch — rules file may be corrupted or tampered with."
    error "Expected: $EXPECTED_HASH"
    error "Got:      $ACTUAL_HASH"
    rm -f "$TMP_RULES" "$TMP_HASH"
    exit 1
fi

success "Hash verified: $ACTUAL_HASH"

# Back up existing rules
cp "$INSTALL_DIR/data.min.json" "$INSTALL_DIR/data.min.json.bak"
info "Backed up existing rules to data.min.json.bak"

# Replace
mv "$TMP_RULES" "$INSTALL_DIR/data.min.json"
rm -f "$TMP_HASH"

success "Rules updated at $INSTALL_DIR/data.min.json"

# Restart daemon to pick up new rules
info "Restarting Nullroute..."
PLIST="$HOME/Library/LaunchAgents/com.threatcraft.nullroute.plist"
if [[ -f "$PLIST" ]]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    launchctl load "$PLIST"
    success "Nullroute restarted with updated rules"
else
    info "LaunchAgent plist not found — restart Nullroute manually if needed"
fi

echo ""
echo -e "${GREEN}${BOLD}Rules updated successfully.${RESET}\n"
