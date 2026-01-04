#!/bin/bash
set -e

echo "Running macOS setup..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install packages from Brewfile
echo "Installing Homebrew packages..."
brew bundle --file="$HOME/.dotfiles/Brewfile"

# Prompt is built into zshrc - no external dependencies needed

# Install Node via NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
nvm install --lts
nvm use --lts

echo "macOS setup complete!"
