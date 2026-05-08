#!/usr/bin/env bash
# Nullroute — macOS installer
# https://github.com/threatcraft-co/nullroute
#
# Installs Nullroute as a LaunchAgent that starts at login and runs silently
# in the background. No UI. No network calls. Zero dependencies beyond Python 3.
#
# Usage: bash install.sh [--strip-referral]
#   --strip-referral    Also remove affiliate/referral parameters (e.g. Amazon tag=)

set -euo pipefail

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
INSTALL_DIR="$HOME/.nullroute"
PLIST_NAME="com.threatcraft.nullroute.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"
LOG_DIR="$HOME/Library/Logs/nullroute"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
STRIP_REFERRAL=false
for arg in "$@"; do
    case $arg in
        --strip-referral) STRIP_REFERRAL=true ;;
        *) error "Unknown argument: $arg"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------
header "Nullroute installer"
echo "  Browser-agnostic URL tracking stripper"
echo "  https://github.com/threatcraft-co/nullroute"
echo ""

info "Checking requirements..."

# Python 3
PYTHON=$(command -v python3 2>/dev/null || true)
if [[ -z "$PYTHON" ]]; then
    error "Python 3 is required but was not found."
    error "Install it via: brew install python3  or  xcode-select --install"
    exit 1
fi

PYTHON_VERSION=$("$PYTHON" --version 2>&1 | awk '{print $2}')
success "Python 3 found at $PYTHON ($PYTHON_VERSION)"

# macOS check
if [[ "$(uname)" != "Darwin" ]]; then
    error "This installer is for macOS only."
    error "See README.md for Linux and Windows installation."
    exit 1
fi

# Rules file
if [[ ! -f "$SCRIPT_DIR/data.min.json" ]]; then
    error "data.min.json not found in $SCRIPT_DIR"
    error "Please ensure data.min.json is present alongside install.sh."
    exit 1
fi
success "Rules file found (data.min.json)"

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
header "Installing..."

# Create install directory
mkdir -p "$INSTALL_DIR"
success "Created $INSTALL_DIR"

# Copy daemon and rules
cp "$SCRIPT_DIR/nullroute.py" "$INSTALL_DIR/nullroute.py"
cp "$SCRIPT_DIR/data.min.json" "$INSTALL_DIR/data.min.json"
chmod 755 "$INSTALL_DIR/nullroute.py"
success "Copied nullroute.py and data.min.json to $INSTALL_DIR"

# Optionally enable referral marketing stripping
if [[ "$STRIP_REFERRAL" == "true" ]]; then
    sed -i '' 's/^STRIP_REFERRAL_MARKETING = False/STRIP_REFERRAL_MARKETING = True/' \
        "$INSTALL_DIR/nullroute.py"
    success "Referral/affiliate parameter stripping enabled"
fi

# Create log directory
mkdir -p "$LOG_DIR"
success "Created log directory: $LOG_DIR"

# Create LaunchAgents directory if needed
mkdir -p "$LAUNCH_AGENTS_DIR"

# Populate plist from template
sed \
    -e "s|__PYTHON__|$PYTHON|g" \
    -e "s|__INSTALL_DIR__|$INSTALL_DIR|g" \
    -e "s|__LOG_DIR__|$LOG_DIR|g" \
    "$SCRIPT_DIR/$PLIST_NAME" > "$PLIST_DEST"

success "Installed LaunchAgent plist to $PLIST_DEST"

# ---------------------------------------------------------------------------
# Load the LaunchAgent
# ---------------------------------------------------------------------------
header "Starting Nullroute..."

# Unload first if already running (upgrade path)
if launchctl list | grep -q "com.threatcraft.nullroute" 2>/dev/null; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    info "Unloaded previous instance"
fi

launchctl load "$PLIST_DEST"
success "LaunchAgent loaded — Nullroute is now running"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}Nullroute is installed and running.${RESET}"
echo ""
echo "  It will start automatically at login."
echo "  Logs: $LOG_DIR/nullroute.log"
echo ""
echo "  To uninstall: bash uninstall.sh"
echo "  To update rules: bash update-rules.sh"
echo ""
