#!/bin/bash
set -e

DOTFILES_REPO="https://github.com/akgoode/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

echo "================================================"
echo "  Dotfiles Installer"
echo "================================================"

# Clone or update repo
if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory exists..."
    cd "$DOTFILES_DIR"
    if [ -d ".git" ]; then
        echo "Updating from git..."
        git pull
    else
        echo "Not a git repo, skipping update"
    fi
else
    echo "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Detect OS and run appropriate installer
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"
    ./scripts/install-mac.sh
elif [[ -f /etc/debian_version ]]; then
    echo "Detected Debian/Ubuntu"
    ./scripts/install-linux.sh
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Run common setup (symlinks)
./scripts/common.sh

echo ""
echo "================================================"
echo "  Installation complete!"
echo "  Please restart your terminal."
echo "================================================"
