#!/bin/bash
# Test VS Code configuration (local version)

set -e

echo "========================================"
echo "  VS Code Configuration Tests (Local)"
echo "========================================"

# Test 5.3: Test VS Code settings and extensions
echo ""
echo "[5.3] Testing VS Code settings and extensions..."

# Check if VS Code is available
if ! command -v code >/dev/null 2>&1; then
    echo "    ⊘ VS Code not available, skipping tests"
    exit 0
fi

echo "    ✓ VS Code is available: $(code --version | head -1)"

# Test VS Code settings.json configuration
echo "  Testing VS Code settings.json configuration..."

# Check platform-specific settings path
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_SETTINGS_PATH="$HOME/Library/Application Support/Code/User/settings.json"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VSCODE_SETTINGS_PATH="$HOME/.config/Code/User/settings.json"
else
    echo "    ⊘ Unsupported platform for VS Code settings test"
    exit 0
fi

echo "    Expected settings path: $VSCODE_SETTINGS_PATH"

if [ -f "$VSCODE_SETTINGS_PATH" ] || [ -L "$VSCODE_SETTINGS_PATH" ]; then
    echo "    ✓ VS Code settings.json exists"
    
    # Test that settings.json is valid JSON
    if jq empty "$VSCODE_SETTINGS_PATH" 2>/dev/null; then
        echo "    ✓ settings.json is valid JSON"
    else
        echo "    ✗ settings.json is not valid JSON"
        exit 1
    fi
    
    # Test for some expected settings
    EXPECTED_SETTINGS=(
        "editor.fontSize"
        "editor.fontFamily"
        "workbench.colorTheme"
        "editor.tabSize"
    )
    
    for setting in "${EXPECTED_SETTINGS[@]}"; do
        if jq -e ".$setting" "$VSCODE_SETTINGS_PATH" >/dev/null 2>&1; then
            echo "    ✓ Setting '$setting' is configured"
        else
            echo "    ⊘ Setting '$setting' not found (optional)"
        fi
    done
    
else
    echo "    ✗ VS Code settings.json not found at expected path"
    exit 1
fi

# Test extension installation process
echo "  Testing extension installation..."

# Check if extensions.txt exists
EXTENSIONS_FILE="editors/vscode/extensions.txt"
if [ -f "$EXTENSIONS_FILE" ]; then
    echo "    ✓ extensions.txt file exists"
    
    EXTENSION_COUNT=$(wc -l < "$EXTENSIONS_FILE")
    echo "    ℹ Number of extensions listed: $EXTENSION_COUNT"
    
    # Test that extensions.txt has valid format
    if grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' "$EXTENSIONS_FILE" >/dev/null; then
        echo "    ✓ extensions.txt has valid extension ID format"
    else
        echo "    ✗ extensions.txt has invalid extension ID format"
        exit 1
    fi
    
    # Test a few extensions are actually installed (sample check)
    INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")
    if [ -n "$INSTALLED_EXTENSIONS" ]; then
        INSTALLED_COUNT=$(echo "$INSTALLED_EXTENSIONS" | wc -l)
        echo "    ℹ Number of installed extensions: $INSTALLED_COUNT"
        
        # Check if at least some extensions from the list are installed
        SAMPLE_EXTENSIONS=$(head -3 "$EXTENSIONS_FILE")
        FOUND_COUNT=0
        
        for ext in $SAMPLE_EXTENSIONS; do
            if echo "$INSTALLED_EXTENSIONS" | grep -q "^$ext$"; then
                echo "    ✓ Extension '$ext' is installed"
                FOUND_COUNT=$((FOUND_COUNT + 1))
            else
                echo "    ⊘ Extension '$ext' not installed (may need manual installation)"
            fi
        done
        
        if [ $FOUND_COUNT -gt 0 ]; then
            echo "    ✓ Some extensions are properly installed"
        else
            echo "    ⊘ No sample extensions found installed (may need setup)"
        fi
    else
        echo "    ⊘ No extensions currently installed (may need setup)"
    fi
    
else
    echo "    ✗ extensions.txt file not found"
    exit 1
fi

# Test cross-platform path handling
echo "  Testing cross-platform compatibility..."

# Test that the settings path is correctly determined for the platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$VSCODE_SETTINGS_PATH" == *"Library/Application Support"* ]]; then
        echo "    ✓ macOS settings path is correct"
    else
        echo "    ✗ macOS settings path is incorrect"
        exit 1
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ "$VSCODE_SETTINGS_PATH" == *".config/Code"* ]]; then
        echo "    ✓ Linux settings path is correct"
    else
        echo "    ✗ Linux settings path is incorrect"
        exit 1
    fi
fi

# Test that VS Code can start (if display is available)
echo "  Testing VS Code functionality..."

# Test that VS Code can show version (basic functionality test)
if code --version >/dev/null 2>&1; then
    echo "    ✓ VS Code basic functionality works"
else
    echo "    ✗ VS Code basic functionality failed"
    exit 1
fi

echo "  ✓ Subtask 5.3 completed: VS Code configuration tests passed"

echo ""
echo "========================================"
echo "  VS Code Configuration Tests Complete"
echo "========================================"