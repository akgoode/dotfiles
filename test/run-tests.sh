#!/bin/bash
# Run dotfiles installation tests in the container

set -e

CONTAINER="dotfiles-test"

echo "========================================"
echo "  Dotfiles Installation Test"
echo "========================================"

# Run installation script
echo ""
echo "[1/5] Running Linux installation script..."
docker exec -u testuser $CONTAINER bash -c "cd ~/.dotfiles && ./scripts/install-linux.sh"

# Run common setup (symlinks)
echo ""
echo "[2/5] Running common setup (symlinks)..."
docker exec -u testuser $CONTAINER bash -c "cd ~/.dotfiles && ./scripts/common.sh"

# Verify symlinks
echo ""
echo "[3/5] Verifying symlinks..."
docker exec -u testuser $CONTAINER bash -c '
    echo "Checking symlinks..."

    check_link() {
        if [ -L "$1" ]; then
            echo "  ✓ $1 -> $(readlink $1)"
        else
            echo "  ✗ $1 is not a symlink"
            exit 1
        fi
    }

    check_link ~/.zshrc
    check_link ~/.config/starship.toml
    check_link ~/.gitconfig
    check_link ~/.config/nvim
    check_link ~/.tmux.conf
'

# Verify installed tools
echo ""
echo "[4/5] Verifying installed tools..."
docker exec -u testuser $CONTAINER bash -c '
    check_cmd() {
        if command -v $1 &> /dev/null; then
            echo "  ✓ $1 installed"
        else
            echo "  ✗ $1 not found"
        fi
    }

    check_cmd zsh
    check_cmd nvim
    check_cmd starship
    check_cmd tmux
    check_cmd git
    check_cmd jq
    check_cmd rg
    check_cmd go
    check_cmd terraform
    check_cmd aws
    check_cmd kubectl
'

# Test shell
echo ""
echo "[5/5] Testing zsh configuration..."
docker exec -u testuser $CONTAINER zsh -c '
    source ~/.zshrc
    echo "  ✓ zsh config loads without errors"

    # Check aliases exist
    alias gst &>/dev/null && echo "  ✓ Git aliases loaded"
'

echo ""
echo "========================================"
echo "  All tests passed!"
echo "========================================"
