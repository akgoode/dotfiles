#!/bin/bash
# Run dotfiles installation tests in the container

set -e

CONTAINER="dotfiles-test"

echo "========================================"
echo "  Dotfiles Installation Test"
echo "========================================"

# Run installation script (allow partial failures for network-dependent tools)
echo ""
echo "[1/5] Running Linux installation script..."
docker exec -u testuser $CONTAINER bash -c "cd ~/.dotfiles && ./scripts/install-linux.sh" || echo "  ⚠ Some tools may have failed to install due to network issues"

# Run common setup (symlinks)
echo ""
echo "[2/5] Running common setup (symlinks)..."
docker exec -u testuser $CONTAINER bash -c "cd ~/.dotfiles && ./scripts/common.sh"

# Run comprehensive symlink tests
echo ""
echo "[2.5/5] Running comprehensive symlink tests..."
docker exec -u testuser $CONTAINER bash -c "cd ~/.dotfiles && ./test/test-symlinks.sh"

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
    check_link ~/.gitconfig
    check_link ~/.config/nvim
    check_link ~/.tmux.conf
    check_link ~/.config/dotfiles/shell/aliases.zsh
'

# Verify core tools (required) and optional tools
echo ""
echo "[4/5] Verifying installed tools..."
docker exec -u testuser $CONTAINER bash -c '
    CORE_TOOLS_FAILED=0
    
    check_core_cmd() {
        if command -v $1 &> /dev/null; then
            echo "  ✓ $1 installed (core)"
        else
            echo "  ✗ $1 not found (core - REQUIRED)"
            CORE_TOOLS_FAILED=1
        fi
    }
    
    check_optional_cmd() {
        if command -v $1 &> /dev/null; then
            echo "  ✓ $1 installed (optional)"
        else
            echo "  ⚠ $1 not found (optional - may fail due to network issues)"
        fi
    }

    # Core tools that should always install
    check_core_cmd zsh
    check_core_cmd nvim
    check_core_cmd tmux
    check_core_cmd git
    check_core_cmd jq
    check_core_cmd rg
    
    # Optional tools that may fail due to network issues
    check_optional_cmd go
    check_optional_cmd terraform
    check_optional_cmd aws
    check_optional_cmd kubectl
    
    if [ $CORE_TOOLS_FAILED -eq 1 ]; then
        echo "  ✗ Core tool installation failed"
        exit 1
    fi
'

# Test shell
echo ""
echo "[5/5] Testing zsh configuration..."
docker exec -u testuser $CONTAINER bash -c '
    cd ~/.dotfiles
    
    # Test that aliases are available (this is the key functionality)
    if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gst" &>/dev/null; then
        echo "  ✓ Git aliases loaded"
    else
        echo "  ✗ Git aliases not loaded"
        exit 1
    fi
    
    # Test that zsh can run basic commands
    if zsh -c "echo test" &>/dev/null; then
        echo "  ✓ zsh works correctly"
    else
        echo "  ✗ zsh has issues"
        exit 1
    fi
    
    # Test that symlinks are working
    if [ -L ~/.zshrc ] && [ -f ~/.zshrc ]; then
        echo "  ✓ zshrc symlink is working"
    else
        echo "  ✗ zshrc symlink is broken"
        exit 1
    fi
    
    # Check Go PATH (only if Go is installed)
    if command -v go &> /dev/null; then
        echo "  ✓ Go available in PATH"
    else
        echo "  ⚠ Go not available (may not be installed due to network issues)"
    fi
'

echo ""
echo "========================================"
echo "  Core tests passed!"
echo "  Docker testing environment is ready"
echo "========================================"
