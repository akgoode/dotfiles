#!/bin/bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"

backup_and_link() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    echo "Linking $dest -> $src"
    ln -s "$src" "$dest"
}

echo "Setting up symlinks..."

# Shell
mkdir -p ~/.config
backup_and_link "$DOTFILES_DIR/shell/zshrc" ~/.zshrc

# Create dotfiles config directory for aliases
mkdir -p ~/.config/dotfiles/shell
backup_and_link "$DOTFILES_DIR/shell/aliases.zsh" ~/.config/dotfiles/shell/aliases.zsh

# Git
backup_and_link "$DOTFILES_DIR/git/gitconfig" ~/.gitconfig

# Neovim
backup_and_link "$DOTFILES_DIR/editors/nvim" ~/.config/nvim

# VS Code (macOS path - adjust for Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_DIR="$HOME/.config/Code/User"
fi
mkdir -p "$VSCODE_DIR"
backup_and_link "$DOTFILES_DIR/editors/vscode/settings.json" "$VSCODE_DIR/settings.json"

# Kiro
mkdir -p ~/.kiro/settings
backup_and_link "$DOTFILES_DIR/editors/kiro/settings/mcp.json" ~/.kiro/settings/mcp.json

# tmux
backup_and_link "$DOTFILES_DIR/tmux/tmux.conf" ~/.tmux.conf

# Claude Code
mkdir -p ~/.claude
backup_and_link "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json

echo "Symlinks complete!"

# Install VS Code extensions
if command -v code &> /dev/null; then
    echo "Installing VS Code extensions..."
    cat "$DOTFILES_DIR/editors/vscode/extensions.txt" | xargs -L 1 code --install-extension || true
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    
    # Try chsh first (works in most normal environments)
    if chsh -s "$(which zsh)" 2>/dev/null; then
        echo "Default shell changed to zsh"
    else
        # In Docker or restricted environments, update /etc/passwd directly
        echo "chsh failed, trying alternative method..."
        ZSH_PATH=$(which zsh)
        CURRENT_USER=$(whoami)
        
        # Check if we can modify /etc/passwd
        if sudo test -w /etc/passwd 2>/dev/null || [ -w /etc/passwd ]; then
            # Update the user's shell in /etc/passwd
            if sudo sed -i "s|^\($CURRENT_USER:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\).*|\1$ZSH_PATH|" /etc/passwd 2>/dev/null; then
                echo "Successfully updated default shell to zsh in /etc/passwd"
                export SHELL="$ZSH_PATH"
            else
                echo "Could not update /etc/passwd. Run manually: sudo chsh -s $ZSH_PATH $CURRENT_USER"
            fi
        else
            echo "No permission to modify /etc/passwd. Run manually: chsh -s $ZSH_PATH"
        fi
    fi
fi

# Updated: 2025-01-04 22:25:00
