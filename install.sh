#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Installation directories
INSTALL_DIR="$HOME/.local/share/resumatyk"
BIN_DIR="$HOME/.local/bin"

echo -e "${GREEN}[*]${NC} Installing Resumatyk..."

# Create directories
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$BIN_DIR"

# Copy library files
cp lib/* "$INSTALL_DIR/lib/"

# Copy main executable to install directory
mkdir -p "$INSTALL_DIR/bin"
cp bin/resume "$INSTALL_DIR/bin/"
chmod +x "$INSTALL_DIR/bin/resume"

# Create symlink to 'resume' in BIN_DIR
ln -sf "$INSTALL_DIR/bin/resume" "$BIN_DIR/resume"

# Update shell configuration
SHELL_RC="$HOME/.$(basename $SHELL)rc"
if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
fi

echo -e "${GREEN}[*]${NC} Installation complete!"
echo -e "${GREEN}[*]${NC} Please restart your shell or run: source $SHELL_RC"
echo -e "${GREEN}[*]${NC} You can now use the 'resume' command!"
