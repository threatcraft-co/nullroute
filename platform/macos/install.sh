#!/usr/bin/env bash
# Nullroute — macOS installer
# https://github.com/threatcraft-co/nullroute
#
# Installs Nullroute as a LaunchAgent that starts at login and runs silently
# in the background. No UI. No network calls. Zero dependencies beyond Python 3.
#
# Usage: bash install.sh [--strip-referral] [--no-log] [--verbose]
#   --strip-referral    Also remove affiliate/referral parameters (e.g. Amazon tag=)
#   --no-log            Disable all file logging
#   --verbose           Log full URLs (default: domain+path only)

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
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
EXTRA_ARGS=""
for arg in "$@"; do
    case $arg in
        --strip-referral) EXTRA_ARGS="$EXTRA_ARGS --strip-referral" ;;
        --no-log)         EXTRA_ARGS="$EXTRA_ARGS --no-log" ;;
        --verbose)        EXTRA_ARGS="$EXTRA_ARGS --verbose" ;;
        *) error "Unknown argument: $arg"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Pre-flight checks
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

# macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This installer is for macOS only."
    error "See README.md for Linux and Windows installation."
    exit 1
fi

# Required files
if [[ ! -f "$REPO_ROOT/nullroute.py" ]]; then
    error "nullroute.py not found at $REPO_ROOT"
    exit 1
fi

if [[ ! -f "$REPO_ROOT/data.min.json" ]]; then
    error "data.min.json not found at $REPO_ROOT"
    error "Download it from: https://rules2.clearurls.xyz/data.minify.json"
    exit 1
fi
success "Required files found"

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
header "Installing..."

# Create install directory with restricted permissions (owner only)
mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"
success "Created $INSTALL_DIR (mode 700)"

# Copy daemon and rules, restrict to owner read-only
cp "$REPO_ROOT/nullroute.py" "$INSTALL_DIR/nullroute.py"
cp "$REPO_ROOT/data.min.json" "$INSTALL_DIR/data.min.json"
chmod 700 "$INSTALL_DIR/nullroute.py"
chmod 600 "$INSTALL_DIR/data.min.json"
success "Copied and secured nullroute.py and data.min.json"

# Compute and store SHA-256 of data.min.json for runtime integrity checks
shasum -a 256 "$INSTALL_DIR/data.min.json" | awk '{print $1}' \
    > "$INSTALL_DIR/data.min.json.sha256"
chmod 600 "$INSTALL_DIR/data.min.json.sha256"
STORED_HASH=$(cat "$INSTALL_DIR/data.min.json.sha256")
success "Stored integrity hash: $STORED_HASH"

# Create log directory and lock down permissions
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
success "Created log directory: $LOG_DIR (mode 700)"

# Create LaunchAgents directory if needed
mkdir -p "$LAUNCH_AGENTS_DIR"

# Populate plist from template, appending extra args if provided
PROGRAM_ARGS="        <string>$PYTHON<\/string>\n        <string>$INSTALL_DIR\/nullroute.py<\/string>"
if [[ -n "$EXTRA_ARGS" ]]; then
    for arg in $EXTRA_ARGS; do
        PROGRAM_ARGS="$PROGRAM_ARGS\n        <string>$arg<\/string>"
    done
fi

sed \
    -e "s|__PYTHON__|$PYTHON|g" \
    -e "s|__INSTALL_DIR__|$INSTALL_DIR|g" \
    -e "s|__LOG_DIR__|$LOG_DIR|g" \
    "$SCRIPT_DIR/$PLIST_NAME" > "$PLIST_DEST"

chmod 644 "$PLIST_DEST"
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
success "LaunchAgent loaded — Nullroute is running"

# ---------------------------------------------------------------------------
# Post-install integrity self-check
# ---------------------------------------------------------------------------
header "Verifying installation..."

VERIFY_HASH=$(shasum -a 256 "$INSTALL_DIR/data.min.json" | awk '{print $1}')
if [[ "$VERIFY_HASH" == "$STORED_HASH" ]]; then
    success "Post-install integrity check passed"
else
    error "Post-install integrity check FAILED — installation may be corrupted"
    error "Run: bash uninstall.sh && bash install.sh"
    exit 1
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}Nullroute is installed and running.${RESET}"
echo ""
echo "  Starts automatically at login."
echo "  Install directory: $INSTALL_DIR"
echo "  Logs: $LOG_DIR/nullroute.log"
echo ""
echo "  To uninstall:     bash platform/macos/uninstall.sh"
echo "  To update rules:  bash update-rules.sh"
echo ""
