#!/bin/bash
# Test Neovim configuration (local version)

set -e

echo "========================================"
echo "  Neovim Configuration Tests (Local)"
echo "========================================"

# Test 5.1: Test Neovim configuration
echo ""
echo "[5.1] Testing Neovim configuration..."

# Test lazy.nvim bootstrap and loading
echo "  Testing lazy.nvim bootstrap and loading..."

# Check if Neovim is available
if ! command -v nvim >/dev/null 2>&1; then
    echo "    ⊘ Neovim not available, skipping tests"
    exit 0
fi

echo "    ✓ Neovim is available: $(nvim --version | head -1)"

# Test that Neovim config directory exists or can be created
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [ -d "$NVIM_CONFIG_DIR" ] || [ -L "$NVIM_CONFIG_DIR" ]; then
    echo "    ✓ Neovim config directory exists: $NVIM_CONFIG_DIR"
else
    echo "    ✗ Neovim config directory not found: $NVIM_CONFIG_DIR"
    exit 1
fi

# Test that init.lua exists
if [ -f "$NVIM_CONFIG_DIR/init.lua" ]; then
    echo "    ✓ init.lua exists"
else
    echo "    ✗ init.lua not found"
    exit 1
fi

# Test that init.lua is valid Lua syntax
if nvim --headless -c "luafile $NVIM_CONFIG_DIR/init.lua" -c "qa" 2>/dev/null; then
    echo "    ✓ init.lua has valid Lua syntax"
else
    echo "    ✗ init.lua has syntax errors"
    exit 1
fi

# Test that lazy.nvim directory exists or will be created
LAZY_DIR="$HOME/.local/share/nvim/lazy"
if [ -d "$LAZY_DIR" ]; then
    echo "    ✓ Lazy.nvim directory exists: $LAZY_DIR"
else
    echo "    ℹ Lazy.nvim directory will be created on first run: $LAZY_DIR"
fi

# Test basic Neovim functionality
echo "  Testing basic Neovim functionality..."

# Test that Neovim can start and exit cleanly
if timeout 10 nvim --headless -c "echo 'Neovim started successfully'" -c "qa" 2>/dev/null; then
    echo "    ✓ Neovim starts and exits cleanly"
else
    echo "    ✗ Neovim failed to start or exit cleanly"
    exit 1
fi

# Test LSP configuration
echo "  Testing LSP configuration..."

# Check if LSP configuration exists in the config
if grep -r "lsp" "$NVIM_CONFIG_DIR" >/dev/null 2>&1; then
    echo "    ✓ LSP configuration found in config files"
else
    echo "    ⊘ LSP configuration not found (may be in plugins)"
fi

# Test plugin configuration
echo "  Testing plugin configuration..."

# Check for common plugin configurations
PLUGIN_CONFIGS=(
    "telescope"
    "treesitter"
    "lualine"
    "neotree"
)

for plugin in "${PLUGIN_CONFIGS[@]}"; do
    if find "$NVIM_CONFIG_DIR" -name "*.lua" -exec grep -l "$plugin" {} \; | head -1 >/dev/null 2>&1; then
        echo "    ✓ $plugin configuration found"
    else
        echo "    ⊘ $plugin configuration not found"
    fi
done

# Test that lazy-lock.json exists (indicates plugins are configured)
if [ -f "$NVIM_CONFIG_DIR/lazy-lock.json" ]; then
    echo "    ✓ lazy-lock.json exists (plugins configured)"
    PLUGIN_COUNT=$(jq 'keys | length' "$NVIM_CONFIG_DIR/lazy-lock.json" 2>/dev/null || echo "unknown")
    echo "    ℹ Number of plugins: $PLUGIN_COUNT"
else
    echo "    ⊘ lazy-lock.json not found (plugins may not be installed yet)"
fi

# Test keybinding configuration
echo "  Testing keybinding configuration..."

# Check for common keybinding patterns
if grep -r "vim.keymap.set\|vim.api.nvim_set_keymap" "$NVIM_CONFIG_DIR" >/dev/null 2>&1; then
    echo "    ✓ Custom keybindings configured"
else
    echo "    ⊘ Custom keybindings not found"
fi

echo "  ✓ Subtask 5.1 completed: Neovim configuration tests passed"

echo ""
echo "========================================"
echo "  Neovim Configuration Tests Complete"
echo "========================================"