#!/usr/bin/env bash
# Nullroute — macOS uninstaller
# https://github.com/threatcraft-co/nullroute

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }

INSTALL_DIR="$HOME/.nullroute"
PLIST_DEST="$HOME/Library/LaunchAgents/com.threatcraft.nullroute.plist"
LOG_DIR="$HOME/Library/Logs/nullroute"

echo -e "\n${BOLD}Nullroute uninstaller${RESET}\n"

# Unload LaunchAgent
if launchctl list | grep -q "com.threatcraft.nullroute" 2>/dev/null; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    success "LaunchAgent unloaded"
else
    info "LaunchAgent was not running"
fi

# Remove plist
if [[ -f "$PLIST_DEST" ]]; then
    rm "$PLIST_DEST"
    success "Removed $PLIST_DEST"
fi

# Remove install directory
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    success "Removed $INSTALL_DIR"
fi

# Optionally remove logs
echo ""
read -r -p "  Remove log files at $LOG_DIR? [y/N] " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    rm -rf "$LOG_DIR"
    success "Removed $LOG_DIR"
else
    info "Logs kept at $LOG_DIR"
fi

echo ""
echo -e "${GREEN}${BOLD}Nullroute has been uninstalled.${RESET}\n"
