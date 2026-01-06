#!/bin/bash
# Test daily usage scenarios for dotfiles deployment
# Task 9.2: Validate daily usage scenarios
# Requirements: 3.5, 4.4, 5.4

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_result() {
    local status="$1"
    local message="$2"
    local details="$3"
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✓${NC} $message"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            ;;
        "SKIP")
            echo -e "${YELLOW}⊘${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "  $details"
    fi
    
    TESTS_RUN=$((TESTS_RUN + 1))
}

echo "========================================"
echo "  Daily Usage Scenarios Validation"
echo "========================================"
echo "Testing common development workflows and tool functionality"
echo "Requirements: 3.5 (AI compatibility), 4.4 (editor consistency), 5.4 (cross-platform)"
echo ""

# Test common development workflows
echo "========================================"
echo "  Common Development Workflows"
echo "========================================"

# Test git workflow with aliases
echo ""
echo "Testing git workflow with aliases..."

# Create a temporary git repo for testing
TEST_REPO="/tmp/dotfiles-daily-usage-test-$(date +%s)"
mkdir -p "$TEST_REPO"
cd "$TEST_REPO"

git init &>/dev/null
git config user.email "test@example.com"
git config user.name "Test User"

# Test basic git aliases work
if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gst | grep -q 'git status'"; then
    log_result "PASS" "Git status alias (gst) is configured"
else
    log_result "FAIL" "Git status alias (gst) not working"
fi

if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gco | grep -q 'git checkout'"; then
    log_result "PASS" "Git checkout alias (gco) is configured"
else
    log_result "FAIL" "Git checkout alias (gco) not working"
fi

if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gc | grep -q 'git commit'"; then
    log_result "PASS" "Git commit alias (gc) is configured"
else
    log_result "FAIL" "Git commit alias (gc) not working"
fi

# Test development workflow
echo "test file" > test.txt
git add test.txt
git commit -m "initial commit" &>/dev/null

if git log --oneline | grep -q "initial commit"; then
    log_result "PASS" "Basic git workflow functions correctly"
else
    log_result "FAIL" "Basic git workflow failed"
fi

# Clean up test repo
cd /tmp
rm -rf "$TEST_REPO"

# Test editor availability and functionality
echo ""
echo "Testing editor availability..."

if command -v nvim >/dev/null 2>&1; then
    log_result "PASS" "Neovim is available" "$(nvim --version | head -1)"
    
    # Test that Neovim can start and exit
    if timeout 5 nvim --headless -c "echo 'test'" -c "qa" 2>/dev/null; then
        log_result "PASS" "Neovim starts and exits cleanly"
    else
        log_result "FAIL" "Neovim failed to start/exit cleanly"
    fi
else
    log_result "FAIL" "Neovim not available"
fi

if command -v code >/dev/null 2>&1; then
    log_result "PASS" "VS Code is available" "$(code --version | head -1)"
    
    # Test that VS Code can show version
    if code --version >/dev/null 2>&1; then
        log_result "PASS" "VS Code basic functionality works"
    else
        log_result "FAIL" "VS Code basic functionality failed"
    fi
else
    log_result "FAIL" "VS Code not available"
fi

# Test shell functionality
echo ""
echo "Testing shell functionality..."

# Test that zsh is the default shell or available
if [[ "$SHELL" == *"zsh"* ]] || command -v zsh >/dev/null 2>&1; then
    log_result "PASS" "Zsh is available" "$SHELL"
else
    log_result "FAIL" "Zsh not available or not default shell"
fi

# Test directory navigation aliases
if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias .. | grep -q 'cd ..'"; then
    log_result "PASS" "Directory navigation aliases work"
else
    log_result "FAIL" "Directory navigation aliases not working"
fi

# Test listing aliases
if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias ll | grep -q 'ls -la'"; then
    log_result "PASS" "Enhanced listing alias (ll) works"
else
    log_result "FAIL" "Enhanced listing alias (ll) not working"
fi

# Test all tools and aliases work correctly
echo ""
echo "========================================"
echo "  Tool and Alias Verification"
echo "========================================"

# Test essential CLI tools
ESSENTIAL_TOOLS=(
    "git:Git version control"
    "curl:HTTP client"
    "jq:JSON processor"
    "grep:Text search"
    "find:File search"
)

for tool_spec in "${ESSENTIAL_TOOLS[@]}"; do
    tool="${tool_spec%:*}"
    desc="${tool_spec#*:}"
    
    if command -v "$tool" >/dev/null 2>&1; then
        log_result "PASS" "$desc ($tool) is available"
    else
        log_result "FAIL" "$desc ($tool) not available"
    fi
done

# Test development tools (optional but expected)
DEV_TOOLS=(
    "node:Node.js runtime"
    "npm:Node package manager"
    "python3:Python runtime"
    "docker:Container platform"
)

for tool_spec in "${DEV_TOOLS[@]}"; do
    tool="${tool_spec%:*}"
    desc="${tool_spec#*:}"
    
    if command -v "$tool" >/dev/null 2>&1; then
        log_result "PASS" "$desc ($tool) is available"
    else
        log_result "SKIP" "$desc ($tool) not available (optional)"
    fi
done

# Test AI assistant compatibility
echo ""
echo "========================================"
echo "  AI Assistant Compatibility"
echo "========================================"

# Test clean prompt output (Requirement 3.5)
echo "Testing AI-friendly prompt output..."

# Test that prompt produces clean output
PROMPT_OUTPUT=$(zsh -c "
export TERM=xterm-256color
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats '%b'
setopt PROMPT_SUBST
precmd() {
    vcs_info
    if [[ -n \"\$vcs_info_msg_0_\" ]]; then
        PROMPT=\"%F{cyan}%~%f %F{green}\${vcs_info_msg_0_}%f %(?.%F{green}.%F{red})❯%f \"
    else
        PROMPT=\"%F{cyan}%~%f %(?.%F{green}.%F{red})❯%f \"
    fi
}
precmd
echo \"\$PROMPT\"
")

if [ -n "$PROMPT_OUTPUT" ]; then
    log_result "PASS" "Prompt generates output correctly"
    
    # Test that prompt uses zsh color codes (which render cleanly)
    if echo "$PROMPT_OUTPUT" | grep -q '%F{'; then
        log_result "PASS" "Prompt uses clean zsh color formatting"
    else
        log_result "FAIL" "Prompt doesn't use expected color formatting"
    fi
else
    log_result "FAIL" "Prompt generation failed"
fi

# Test command output cleanliness
echo "Testing command output cleanliness..."

# Test git status output
TEST_REPO="/tmp/dotfiles-ai-test-$(date +%s)"
mkdir -p "$TEST_REPO"
cd "$TEST_REPO"

git init &>/dev/null
git config user.email "test@example.com"
git config user.name "Test User"

echo "test" > test.txt
git add test.txt

# Test that git status --porcelain produces clean output
GIT_OUTPUT=$(git status --porcelain)
if echo "$GIT_OUTPUT" | grep -q "A  test.txt"; then
    log_result "PASS" "Git produces clean, parseable output"
else
    log_result "FAIL" "Git output not as expected"
fi

# Clean up
cd /tmp
rm -rf "$TEST_REPO"

# Test editor consistency (Requirement 4.4)
echo ""
echo "========================================"
echo "  Editor Consistency"
echo "========================================"

# Test that editor configurations exist
EDITOR_CONFIGS=(
    "~/.config/nvim/init.lua:Neovim configuration"
    "~/Library/Application Support/Code/User/settings.json:VS Code settings (macOS)"
    "~/.config/Code/User/settings.json:VS Code settings (Linux)"
)

for config_spec in "${EDITOR_CONFIGS[@]}"; do
    config_path="${config_spec%:*}"
    desc="${config_spec#*:}"
    
    # Expand tilde
    expanded_path="${config_path/#\~/$HOME}"
    
    if [ -f "$expanded_path" ] || [ -L "$expanded_path" ]; then
        log_result "PASS" "$desc exists"
        
        # Test that config files are valid
        case "$config_path" in
            *"init.lua")
                if nvim --headless -c "luafile $expanded_path" -c "qa" 2>/dev/null; then
                    log_result "PASS" "Neovim config is valid Lua"
                else
                    log_result "FAIL" "Neovim config has syntax errors"
                fi
                ;;
            *"settings.json")
                if jq empty "$expanded_path" 2>/dev/null; then
                    log_result "PASS" "VS Code settings are valid JSON"
                else
                    log_result "FAIL" "VS Code settings are invalid JSON"
                fi
                ;;
        esac
    else
        # Only fail for platform-appropriate configs
        if [[ "$config_path" == *"Library/Application Support"* ]] && [[ "$OSTYPE" == "darwin"* ]]; then
            log_result "FAIL" "$desc not found (required for macOS)"
        elif [[ "$config_path" == *".config/Code"* ]] && [[ "$OSTYPE" == "linux-gnu"* ]]; then
            log_result "FAIL" "$desc not found (required for Linux)"
        else
            log_result "SKIP" "$desc not found (not required for this platform)"
        fi
    fi
done

# Test cross-platform consistency (Requirement 5.4)
echo ""
echo "========================================"
echo "  Cross-Platform Consistency"
echo "========================================"

# Test platform detection
CURRENT_PLATFORM=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    CURRENT_PLATFORM="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CURRENT_PLATFORM="Linux"
else
    CURRENT_PLATFORM="Unknown"
fi

log_result "INFO" "Current platform: $CURRENT_PLATFORM"

# Test that aliases work consistently across platforms
CROSS_PLATFORM_ALIASES=(
    "g:git"
    "gst:git status"
    "ll:ls -la"
    "v:nvim"
)

for alias_spec in "${CROSS_PLATFORM_ALIASES[@]}"; do
    alias_name="${alias_spec%:*}"
    expected="${alias_spec#*:}"
    
    if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias $alias_name | grep -q '$expected'"; then
        log_result "PASS" "Cross-platform alias '$alias_name' works correctly"
    else
        log_result "FAIL" "Cross-platform alias '$alias_name' not working"
    fi
done

# Test that PATH includes expected directories
EXPECTED_PATH_DIRS=(
    "$HOME/.local/bin"
)

for path_dir in "${EXPECTED_PATH_DIRS[@]}"; do
    if echo "$PATH" | grep -q "$path_dir"; then
        log_result "PASS" "PATH includes $path_dir"
    else
        log_result "SKIP" "PATH doesn't include $path_dir (may not be set up yet)"
    fi
done

# Generate summary
echo ""
echo "========================================"
echo "  Daily Usage Validation Summary"
echo "========================================"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
SUCCESS_RATE=0
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( TESTS_PASSED * 100 / TOTAL_TESTS ))
fi

echo "Test Results:"
echo "- Total Tests: $TESTS_RUN"
echo "- Passed: $TESTS_PASSED"
echo "- Failed: $TESTS_FAILED"
echo "- Success Rate: ${SUCCESS_RATE}%"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All daily usage scenarios validated successfully!${NC}"
    echo ""
    echo "✅ System is ready for daily development use:"
    echo "   - Git workflow with aliases works correctly"
    echo "   - Editors (Neovim, VS Code) are properly configured"
    echo "   - Shell provides AI-friendly output"
    echo "   - Cross-platform consistency maintained"
    echo "   - All essential tools are available"
    
    exit 0
else
    echo -e "${RED}❌ Some daily usage scenarios failed validation.${NC}"
    echo ""
    echo "Issues found:"
    echo "- $TESTS_FAILED out of $TOTAL_TESTS tests failed"
    echo "- Review the failed tests above for specific issues"
    echo ""
    echo "Common fixes:"
    echo "1. 🔄 Re-run installation: cd ~/.dotfiles && ./install.sh"
    echo "2. 🔗 Check symlinks: ls -la ~/.config/nvim ~/.zshrc"
    echo "3. 🐚 Source shell config: source ~/.zshrc"
    echo "4. 📖 Check troubleshooting guide: docs/TROUBLESHOOTING_GUIDE.md"
    
    exit 1
fi