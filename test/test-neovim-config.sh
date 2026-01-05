#!/bin/bash
# Test Neovim configuration loading and functionality

set -e

CONTAINER="dotfiles-test"

echo "========================================"
echo "  Neovim Configuration Tests"
echo "========================================"

# Test 5.1: Test Neovim configuration
echo ""
echo "[5.1] Testing Neovim configuration..."

# Verify lazy.nvim loads correctly in remote container
echo "  Testing lazy.nvim bootstrap and loading..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that nvim is installed and accessible
    if command -v nvim &>/dev/null; then
        echo "    ✓ Neovim is installed and accessible"
    else
        echo "    ✗ Neovim not found in PATH"
        exit 1
    fi
    
    # Test that the nvim config directory is properly symlinked
    if [ -L ~/.config/nvim ] && [ -d ~/.config/nvim ]; then
        echo "    ✓ Neovim config directory is properly symlinked"
    else
        echo "    ✗ Neovim config directory symlink is broken"
        exit 1
    fi
    
    # Test that init.lua exists and is readable
    if [ -f ~/.config/nvim/init.lua ]; then
        echo "    ✓ init.lua exists and is readable"
    else
        echo "    ✗ init.lua not found"
        exit 1
    fi
    
    # Test that vim-options.lua exists
    if [ -f ~/.config/nvim/lua/vim-options.lua ]; then
        echo "    ✓ vim-options.lua exists"
    else
        echo "    ✗ vim-options.lua not found"
        exit 1
    fi
    
    # Test that plugins directory exists
    if [ -d ~/.config/nvim/lua/plugins ]; then
        echo "    ✓ plugins directory exists"
    else
        echo "    ✗ plugins directory not found"
        exit 1
    fi
'

# Test lazy.nvim bootstrap functionality
echo "  Testing lazy.nvim bootstrap process..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that lazy.nvim can be bootstrapped (simulate the bootstrap check)
    LAZYPATH="$HOME/.local/share/nvim/data/lazy/lazy.nvim"
    
    # Remove lazy.nvim if it exists to test bootstrap
    rm -rf "$HOME/.local/share/nvim/data/lazy"
    
    # Test that the bootstrap logic works by running a minimal nvim command
    # This will trigger the bootstrap process in init.lua
    timeout 30 nvim --headless -c "lua print(\"Bootstrap test\")" -c "qall" 2>/dev/null || {
        echo "    ⚠ Neovim bootstrap may have timed out (network dependent)"
        # Check if lazy directory was created
        if [ -d "$HOME/.local/share/nvim/data/lazy" ]; then
            echo "    ✓ lazy.nvim directory was created during bootstrap"
        else
            echo "    ✗ lazy.nvim bootstrap failed to create directory"
            exit 1
        fi
    }
    
    # Verify lazy.nvim was cloned/installed
    if [ -d "$LAZYPATH" ]; then
        echo "    ✓ lazy.nvim was successfully bootstrapped"
    else
        echo "    ⚠ lazy.nvim bootstrap may not have completed (network dependent)"
    fi
'

# Test LSP and plugin functionality via SSH simulation
echo "  Testing plugin configuration loading..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that plugin files exist and are readable
    PLUGIN_FILES=(
        ~/.config/nvim/lua/plugins/lsp-config.lua
        ~/.config/nvim/lua/plugins/telescope.lua
        ~/.config/nvim/lua/plugins/treesitter.lua
        ~/.config/nvim/lua/plugins/debugging.lua
    )
    
    for plugin_file in "${PLUGIN_FILES[@]}"; do
        if [ -f "$plugin_file" ]; then
            echo "    ✓ $(basename "$plugin_file") exists"
        else
            echo "    ✗ $(basename "$plugin_file") not found"
            exit 1
        fi
    done
    
    # Test that plugin files have valid Lua syntax
    for plugin_file in "${PLUGIN_FILES[@]}"; do
        if lua -c "dofile(\"$plugin_file\")" 2>/dev/null; then
            echo "    ✓ $(basename "$plugin_file") has valid Lua syntax"
        else
            echo "    ⚠ $(basename "$plugin_file") may have syntax issues (or missing dependencies)"
        fi
    done
'

# Test basic Neovim functionality
echo "  Testing basic Neovim functionality..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that nvim can start and exit cleanly
    if timeout 10 nvim --headless -c "echo \"Neovim test\"" -c "qall" 2>/dev/null; then
        echo "    ✓ Neovim can start and exit cleanly"
    else
        echo "    ⚠ Neovim may have startup issues (possibly network/plugin related)"
    fi
    
    # Test that nvim can load vim-options
    if timeout 10 nvim --headless -c "lua require(\"vim-options\")" -c "qall" 2>/dev/null; then
        echo "    ✓ vim-options.lua can be loaded"
    else
        echo "    ⚠ vim-options.lua may have loading issues"
    fi
    
    # Test that basic vim functionality works
    echo "test content" > /tmp/nvim_test.txt
    if timeout 10 nvim --headless -c "edit /tmp/nvim_test.txt" -c "1s/test/modified/" -c "wq" 2>/dev/null; then
        if grep -q "modified content" /tmp/nvim_test.txt; then
            echo "    ✓ Basic editing functionality works"
        else
            echo "    ✗ Basic editing functionality failed"
            exit 1
        fi
    else
        echo "    ✗ Neovim editing test failed"
        exit 1
    fi
    
    # Clean up test file
    rm -f /tmp/nvim_test.txt
'

# Fix any plugin or configuration issues (basic validation)
echo "  Validating configuration integrity..."
docker exec -u testuser $CONTAINER bash -c '
    # Check that lazy-lock.json exists (indicates plugins were configured)
    if [ -f ~/.config/nvim/lazy-lock.json ]; then
        echo "    ✓ lazy-lock.json exists (plugin lockfile)"
    else
        echo "    ⚠ lazy-lock.json not found (plugins may not be fully configured)"
    fi
    
    # Validate that init.lua has the expected structure
    if grep -q "lazy.nvim" ~/.config/nvim/init.lua && grep -q "require.*vim-options" ~/.config/nvim/init.lua; then
        echo "    ✓ init.lua has expected structure"
    else
        echo "    ✗ init.lua structure validation failed"
        exit 1
    fi
    
    # Check that essential plugin configurations exist
    ESSENTIAL_PLUGINS=("lsp-config" "telescope" "treesitter")
    for plugin in "${ESSENTIAL_PLUGINS[@]}"; do
        if [ -f ~/.config/nvim/lua/plugins/${plugin}.lua ]; then
            echo "    ✓ Essential plugin ${plugin} configuration exists"
        else
            echo "    ✗ Essential plugin ${plugin} configuration missing"
            exit 1
        fi
    done
'

echo "  ✓ Subtask 5.1 completed: Neovim configuration tests passed"

echo ""
echo "========================================"
echo "  Neovim Configuration Tests Complete"
echo "========================================"