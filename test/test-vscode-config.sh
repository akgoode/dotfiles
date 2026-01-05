#!/bin/bash
# Test VS Code configuration and settings

set -e

CONTAINER="dotfiles-test"

echo "========================================"
echo "  VS Code Configuration Tests"
echo "========================================"

# Test 5.3: Test VS Code settings and extensions
echo ""
echo "[5.3] Testing VS Code settings and extensions..."

# Verify settings.json is applied correctly in container
echo "  Testing VS Code settings.json configuration..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that VS Code settings directory exists and is properly symlinked
    if [ -L ~/.config/Code/User/settings.json ] && [ -f ~/.config/Code/User/settings.json ]; then
        echo "    ✓ VS Code settings.json is properly symlinked"
    else
        echo "    ✗ VS Code settings.json symlink is broken or missing"
        exit 1
    fi
    
    # Test that the symlink points to the correct dotfiles location
    LINK_TARGET=$(readlink ~/.config/Code/User/settings.json)
    if [[ "$LINK_TARGET" == *"dotfiles/editors/vscode/settings.json" ]]; then
        echo "    ✓ VS Code settings.json symlink points to correct location"
    else
        echo "    ✗ VS Code settings.json symlink points to wrong location: $LINK_TARGET"
        exit 1
    fi
    
    # Test that the settings file is readable and contains expected content
    if [ -r ~/.config/Code/User/settings.json ]; then
        echo "    ✓ VS Code settings.json is readable"
    else
        echo "    ✗ VS Code settings.json is not readable"
        exit 1
    fi
'

# Test extension installation process via remote testing
echo "  Testing VS Code settings content and format..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that the settings file is valid JSON
    if jq . ~/.config/Code/User/settings.json >/dev/null 2>&1; then
        echo "    ✓ VS Code settings.json is valid JSON"
    else
        echo "    ✗ VS Code settings.json is not valid JSON"
        exit 1
    fi
    
    # Test for essential VS Code settings
    SETTINGS_FILE=~/.config/Code/User/settings.json
    
    # Check for theme setting
    if jq -e ".\"workbench.colorTheme\"" "$SETTINGS_FILE" >/dev/null 2>&1; then
        THEME=$(jq -r ".\"workbench.colorTheme\"" "$SETTINGS_FILE")
        echo "    ✓ Color theme is configured: $THEME"
    else
        echo "    ⚠ No color theme configured"
    fi
    
    # Check for editor settings
    if jq -e ".\"editor.formatOnSave\"" "$SETTINGS_FILE" >/dev/null 2>&1; then
        FORMAT_ON_SAVE=$(jq -r ".\"editor.formatOnSave\"" "$SETTINGS_FILE")
        echo "    ✓ Format on save is configured: $FORMAT_ON_SAVE"
    else
        echo "    ⚠ Format on save not configured"
    fi
    
    # Check for git settings
    if jq -e ".\"git.autofetch\"" "$SETTINGS_FILE" >/dev/null 2>&1; then
        GIT_AUTOFETCH=$(jq -r ".\"git.autofetch\"" "$SETTINGS_FILE")
        echo "    ✓ Git autofetch is configured: $GIT_AUTOFETCH"
    else
        echo "    ⚠ Git autofetch not configured"
    fi
    
    # Check for vim keybindings (if configured)
    if jq -e ".\"vim.insertModeKeyBindingsNonRecursive\"" "$SETTINGS_FILE" >/dev/null 2>&1; then
        echo "    ✓ Vim keybindings are configured"
    else
        echo "    ⚠ Vim keybindings not configured"
    fi
'

# Fix any cross-platform path issues
echo "  Testing cross-platform path compatibility..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that paths in settings.json work on Linux
    SETTINGS_FILE=~/.config/Code/User/settings.json
    
    # Check for any Windows-specific paths that might cause issues
    if grep -q "C:\\\\" "$SETTINGS_FILE" 2>/dev/null; then
        echo "    ⚠ Found Windows-specific paths in settings.json"
    else
        echo "    ✓ No Windows-specific paths found"
    fi
    
    # Check for any macOS-specific paths that might cause issues on Linux
    if grep -q "/Users/" "$SETTINGS_FILE" 2>/dev/null; then
        echo "    ⚠ Found macOS-specific paths in settings.json"
    else
        echo "    ✓ No macOS-specific paths found"
    fi
    
    # Test that the settings file uses forward slashes (Unix-style paths)
    if grep -q "\\\\\\\\" "$SETTINGS_FILE" 2>/dev/null; then
        echo "    ⚠ Found backslashes in paths (Windows-style)"
    else
        echo "    ✓ Paths use forward slashes (Unix-style)"
    fi
'

# Test VS Code extensions list
echo "  Testing VS Code extensions configuration..."
docker exec -u testuser $CONTAINER bash -c '
    # Check if extensions.txt exists
    if [ -f ~/.dotfiles/editors/vscode/extensions.txt ]; then
        echo "    ✓ VS Code extensions.txt exists"
        
        # Count the number of extensions
        EXT_COUNT=$(wc -l < ~/.dotfiles/editors/vscode/extensions.txt)
        echo "    ✓ Extensions list contains $EXT_COUNT extensions"
        
        # Check for some essential extensions
        if grep -q "ms-vscode.vscode-typescript-next" ~/.dotfiles/editors/vscode/extensions.txt 2>/dev/null; then
            echo "    ✓ TypeScript extension is listed"
        else
            echo "    ⚠ TypeScript extension not found in list"
        fi
        
        if grep -q "esbenp.prettier-vscode" ~/.dotfiles/editors/vscode/extensions.txt 2>/dev/null; then
            echo "    ✓ Prettier extension is listed"
        else
            echo "    ⚠ Prettier extension not found in list"
        fi
        
        # Test that extensions file has no empty lines or invalid entries
        if grep -q "^$" ~/.dotfiles/editors/vscode/extensions.txt 2>/dev/null; then
            echo "    ⚠ Extensions file contains empty lines"
        else
            echo "    ✓ Extensions file has no empty lines"
        fi
        
    else
        echo "    ✗ VS Code extensions.txt not found"
        exit 1
    fi
'

# Test VS Code configuration directory structure
echo "  Testing VS Code directory structure..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that the VS Code User directory exists
    if [ -d ~/.config/Code/User ]; then
        echo "    ✓ VS Code User directory exists"
    else
        echo "    ✗ VS Code User directory does not exist"
        exit 1
    fi
    
    # Test directory permissions
    if [ -w ~/.config/Code/User ]; then
        echo "    ✓ VS Code User directory is writable"
    else
        echo "    ✗ VS Code User directory is not writable"
        exit 1
    fi
    
    # Test that the parent directories exist
    if [ -d ~/.config/Code ]; then
        echo "    ✓ VS Code config directory exists"
    else
        echo "    ✗ VS Code config directory does not exist"
        exit 1
    fi
'

echo "  ✓ Subtask 5.3 completed: VS Code configuration tests passed"

echo ""
echo "========================================"
echo "  VS Code Configuration Tests Complete"
echo "========================================"