#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Installation directories
INSTALL_DIR="$HOME/.local/share/resumatyk"
BIN_DIR="$HOME/.local/bin"

echo -e "${GREEN}[*]${NC} Uninstalling Resumatyk..."

# Remove symlink
if [ -L "$BIN_DIR/resume" ]; then
    rm "$BIN_DIR/resume"
    echo -e "${GREEN}[*]${NC} Removed command symlink"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}[*]${NC} Removed installation directory"
fi

# Remove PATH addition from shell config (optional)
SHELL_RC="$HOME/.$(basename $SHELL)rc"
if [ -f "$SHELL_RC" ]; then
    sed -i '/export PATH="$HOME\/.local\/bin:$PATH"/d' "$SHELL_RC"
fi

echo -e "${GREEN}[*]${NC} Uninstallation complete!"
echo -e "${GREEN}[*]${NC} Please restart your shell or run: source $SHELL_RC"
