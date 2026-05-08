#!/usr/bin/env bash
# Nullroute — repo scaffold
# Creates the full multi-platform directory structure.
# Run this once in the root of your cloned repo.

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }

echo -e "\n${BOLD}Nullroute repo scaffold${RESET}\n"

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------

mkdir -p platform/macos
mkdir -p platform/linux
mkdir -p platform/windows

success "Created platform/macos"
success "Created platform/linux"
success "Created platform/windows"

# ---------------------------------------------------------------------------
# Root-level placeholder files (if not already present)
# ---------------------------------------------------------------------------

touch_if_absent() {
    if [[ ! -f "$1" ]]; then
        touch "$1"
        info "Created placeholder: $1"
    else
        info "Already exists, skipping: $1"
    fi
}

touch_if_absent "nullroute.py"
touch_if_absent "data.min.json"
touch_if_absent "update-rules.sh"
touch_if_absent "LICENSE"
touch_if_absent "NOTICES"
touch_if_absent "README.md"
touch_if_absent ".gitignore"

# ---------------------------------------------------------------------------
# Platform-level placeholder files
# ---------------------------------------------------------------------------

touch_if_absent "platform/macos/install.sh"
touch_if_absent "platform/macos/uninstall.sh"
touch_if_absent "platform/macos/com.threatcraft.nullroute.plist"

touch_if_absent "platform/linux/install.sh"
touch_if_absent "platform/linux/uninstall.sh"
touch_if_absent "platform/linux/nullroute.service"

touch_if_absent "platform/windows/install.ps1"
touch_if_absent "platform/windows/uninstall.ps1"

# ---------------------------------------------------------------------------
# Make scripts executable
# ---------------------------------------------------------------------------

chmod +x update-rules.sh 2>/dev/null || true
chmod +x platform/macos/install.sh platform/macos/uninstall.sh 2>/dev/null || true
chmod +x platform/linux/install.sh platform/linux/uninstall.sh 2>/dev/null || true

success "Permissions set on shell scripts"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo -e "${GREEN}${BOLD}Scaffold complete.${RESET}"
echo ""
echo "  Drop your files into:"
echo "    nullroute.py, data.min.json           → repo root"
echo "    install.sh, uninstall.sh, *.plist     → platform/macos/"
echo "    install.sh, uninstall.sh, *.service   → platform/linux/"
echo "    install.ps1, uninstall.ps1            → platform/windows/"
echo ""
echo "  Remember to manually download data.min.json from:"
echo "    https://rules2.clearurls.xyz/data.minify.json"
echo ""
