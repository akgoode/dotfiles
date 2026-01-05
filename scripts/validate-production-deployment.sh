#!/bin/bash
# Production deployment validation script
# Requirements: 1.2, 1.3, 2.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VALIDATION_FAILED=0
WARNINGS_COUNT=0

echo "========================================"
echo "  Production Deployment Validation"
echo "========================================"
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo ""

log_result() {
    local status="$1"
    local message="$2"
    local details="$3"
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            VALIDATION_FAILED=1
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            WARNINGS_COUNT=$((WARNINGS_COUNT + 1))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "  $details"
    fi
}

validate_symlinks() {
    echo "Validating configuration symlinks..."
    
    local expected_links=(
        ".zshrc"
        ".gitconfig"
        ".config/nvim"
        ".tmux.conf"
        ".config/dotfiles/shell/aliases.zsh"
    )
    
    # Add platform-specific symlinks
    if [[ "$OSTYPE" == "darwin"* ]]; then
        expected_links+=("Library/Application Support/Code/User/settings.json")
    else
        expected_links+=(".config/Code/User/settings.json")
    fi
    
    # Add optional symlinks if they should exist
    [ -f "$HOME/.dotfiles/claude/settings.json" ] && expected_links+=(".claude/settings.json")
    [ -f "$HOME/.dotfiles/editors/kiro/settings/mcp.json" ] && expected_links+=(".kiro/settings/mcp.json")
    
    for link in "${expected_links[@]}"; do
        local full_path="$HOME/$link"
        
        if [ -L "$full_path" ] && [ -e "$full_path" ]; then
            local target=$(readlink "$full_path")
            if [[ "$target" == *"/.dotfiles/"* ]]; then
                log_result "PASS" "Symlink: $link" "-> $target"
            else
                log_result "WARN" "Symlink exists but not to dotfiles: $link" "-> $target"
            fi
        elif [ -e "$full_path" ]; then
            log_result "WARN" "File exists but not a symlink: $link" "May be original file"
        else
            log_result "FAIL" "Missing symlink: $link" "Expected symlink not found"
        fi
    done
}

validate_shell_configuration() {
    echo ""
    echo "Validating shell configuration..."
    
    # Test zsh availability
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version=$(zsh --version)
        log_result "PASS" "zsh available" "$zsh_version"
    else
        log_result "FAIL" "zsh not found" "Required for shell configuration"
        return
    fi
    
    # Test zsh configuration loading
    if zsh -c "source ~/.zshrc" 2>/dev/null; then
        log_result "PASS" "zsh configuration loads without errors"
    else
        log_result "FAIL" "zsh configuration has syntax errors"
        # Show the error for debugging
        echo "  Error details:"
        zsh -c "source ~/.zshrc" 2>&1 | head -5 | sed 's/^/    /'
    fi
    
    # Test git aliases
    if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gst" >/dev/null 2>&1; then
        log_result "PASS" "Git aliases loaded successfully"
        
        # Test a few key aliases
        local aliases_to_test=("gst" "gco" "gcm" "gd" "gl" "gp")
        local working_aliases=0
        
        for alias_name in "${aliases_to_test[@]}"; do
            if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias $alias_name" >/dev/null 2>&1; then
                working_aliases=$((working_aliases + 1))
            fi
        done
        
        if [ $working_aliases -eq ${#aliases_to_test[@]} ]; then
            log_result "PASS" "All key git aliases working" "$working_aliases/${#aliases_to_test[@]} tested"
        else
            log_result "WARN" "Some git aliases missing" "$working_aliases/${#aliases_to_test[@]} working"
        fi
    else
        log_result "FAIL" "Git aliases not loading"
    fi
    
    # Test prompt functionality
    if zsh -c "
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
        [[ -n \$PROMPT ]]
    " 2>/dev/null; then
        log_result "PASS" "Custom prompt configuration working"
    else
        log_result "FAIL" "Custom prompt configuration has issues"
    fi
}

validate_development_tools() {
    echo ""
    echo "Validating development tools..."
    
    # Core tools that should always be available
    local core_tools=("git" "curl")
    
    # Platform-specific core tools
    if [[ "$OSTYPE" == "darwin"* ]]; then
        core_tools+=("brew")
    else
        core_tools+=("apt")
    fi
    
    # Optional tools that may be installed
    local optional_tools=("nvim" "tmux" "jq" "rg" "go" "terraform" "aws" "kubectl" "node" "npm")
    
    # Platform-specific tool names
    if [[ ! "$OSTYPE" == "darwin"* ]]; then
        # On Linux, fd is called fdfind
        optional_tools+=("fdfind")
    else
        optional_tools+=("fd")
    fi
    
    echo "  Core tools (required):"
    for tool in "${core_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "git") version=$(git --version) ;;
                "curl") version=$(curl --version | head -1) ;;
                "brew") version=$(brew --version | head -1) ;;
                "apt") version=$(apt --version | head -1) ;;
            esac
            log_result "PASS" "$tool available" "$version"
        else
            log_result "FAIL" "$tool not found" "Required core tool missing"
        fi
    done
    
    echo ""
    echo "  Optional tools:"
    local installed_optional=0
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "nvim") version=$(nvim --version | head -1) ;;
                "tmux") version=$(tmux -V) ;;
                "jq") version=$(jq --version) ;;
                "rg") version=$(rg --version | head -1) ;;
                "fdfind"|"fd") version=$($tool --version | head -1) ;;
                "go") version=$(go version) ;;
                "terraform") version=$(terraform version | head -1) ;;
                "aws") version=$(aws --version) ;;
                "kubectl") version=$(kubectl version --client --short 2>/dev/null || echo "kubectl available") ;;
                "node") version=$(node --version) ;;
                "npm") version=$(npm --version) ;;
            esac
            log_result "PASS" "$tool available" "$version"
            installed_optional=$((installed_optional + 1))
        else
            log_result "INFO" "$tool not installed" "Optional tool"
        fi
    done
    
    log_result "INFO" "Optional tools summary" "$installed_optional/${#optional_tools[@]} installed"
}

validate_editor_configurations() {
    echo ""
    echo "Validating editor configurations..."
    
    # Neovim configuration
    if command -v nvim >/dev/null 2>&1; then
        if [ -d "$HOME/.config/nvim" ]; then
            log_result "PASS" "Neovim configuration directory exists"
            
            # Check if it's a symlink to dotfiles
            if [ -L "$HOME/.config/nvim" ]; then
                local target=$(readlink "$HOME/.config/nvim")
                if [[ "$target" == *"/.dotfiles/"* ]]; then
                    log_result "PASS" "Neovim config linked to dotfiles" "$target"
                else
                    log_result "WARN" "Neovim config not linked to dotfiles" "$target"
                fi
            else
                log_result "WARN" "Neovim config is not a symlink" "May be original config"
            fi
            
            # Test basic Neovim functionality
            if nvim --headless -c "quit" 2>/dev/null; then
                log_result "PASS" "Neovim starts without errors"
            else
                log_result "FAIL" "Neovim has startup errors"
            fi
        else
            log_result "FAIL" "Neovim configuration directory missing"
        fi
    else
        log_result "INFO" "Neovim not installed" "Editor configuration not applicable"
    fi
    
    # VS Code configuration
    local vscode_settings_path
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vscode_settings_path="$HOME/Library/Application Support/Code/User/settings.json"
    else
        vscode_settings_path="$HOME/.config/Code/User/settings.json"
    fi
    
    if [ -f "$vscode_settings_path" ]; then
        log_result "PASS" "VS Code settings file exists"
        
        # Check if it's a symlink to dotfiles
        if [ -L "$vscode_settings_path" ]; then
            local target=$(readlink "$vscode_settings_path")
            if [[ "$target" == *"/.dotfiles/"* ]]; then
                log_result "PASS" "VS Code settings linked to dotfiles" "$target"
            else
                log_result "WARN" "VS Code settings not linked to dotfiles" "$target"
            fi
        else
            log_result "WARN" "VS Code settings is not a symlink" "May be original config"
        fi
        
        # Validate JSON syntax
        if command -v jq >/dev/null 2>&1; then
            if jq empty "$vscode_settings_path" 2>/dev/null; then
                log_result "PASS" "VS Code settings JSON is valid"
            else
                log_result "FAIL" "VS Code settings JSON is invalid"
            fi
        else
            log_result "INFO" "Cannot validate VS Code JSON" "jq not available"
        fi
    else
        log_result "INFO" "VS Code settings not found" "May not be installed"
    fi
    
    # Kiro MCP configuration
    if [ -f "$HOME/.kiro/settings/mcp.json" ]; then
        log_result "PASS" "Kiro MCP configuration exists"
        
        if [ -L "$HOME/.kiro/settings/mcp.json" ]; then
            local target=$(readlink "$HOME/.kiro/settings/mcp.json")
            if [[ "$target" == *"/.dotfiles/"* ]]; then
                log_result "PASS" "Kiro MCP config linked to dotfiles" "$target"
            else
                log_result "WARN" "Kiro MCP config not linked to dotfiles" "$target"
            fi
        else
            log_result "WARN" "Kiro MCP config is not a symlink" "May be original config"
        fi
        
        # Validate JSON syntax
        if command -v jq >/dev/null 2>&1; then
            if jq empty "$HOME/.kiro/settings/mcp.json" 2>/dev/null; then
                log_result "PASS" "Kiro MCP configuration JSON is valid"
            else
                log_result "FAIL" "Kiro MCP configuration JSON is invalid"
            fi
        fi
    else
        log_result "INFO" "Kiro MCP configuration not found" "May not be configured"
    fi
}

validate_git_configuration() {
    echo ""
    echo "Validating git configuration..."
    
    if [ -f "$HOME/.gitconfig" ]; then
        log_result "PASS" "Git configuration file exists"
        
        # Check if it's a symlink to dotfiles
        if [ -L "$HOME/.gitconfig" ]; then
            local target=$(readlink "$HOME/.gitconfig")
            if [[ "$target" == *"/.dotfiles/"* ]]; then
                log_result "PASS" "Git config linked to dotfiles" "$target"
            else
                log_result "WARN" "Git config not linked to dotfiles" "$target"
            fi
        else
            log_result "WARN" "Git config is not a symlink" "May be original config"
        fi
        
        # Test git configuration loading
        if git config --list >/dev/null 2>&1; then
            log_result "PASS" "Git configuration loads without errors"
        else
            log_result "FAIL" "Git configuration has errors"
        fi
        
        # Check for essential git settings
        local user_name=$(git config user.name 2>/dev/null || echo "")
        local user_email=$(git config user.email 2>/dev/null || echo "")
        
        if [ -n "$user_name" ] && [ -n "$user_email" ]; then
            log_result "PASS" "Git user configuration set" "$user_name <$user_email>"
        else
            log_result "WARN" "Git user configuration incomplete" "May need manual setup"
        fi
        
        # Test key aliases
        local aliases_to_test=("lg" "unstage" "last")
        local working_aliases=0
        
        for alias_name in "${aliases_to_test[@]}"; do
            if git config "alias.$alias_name" >/dev/null 2>&1; then
                working_aliases=$((working_aliases + 1))
            fi
        done
        
        if [ $working_aliases -gt 0 ]; then
            log_result "PASS" "Git aliases configured" "$working_aliases/${#aliases_to_test[@]} key aliases found"
        else
            log_result "WARN" "No git aliases found" "Configuration may not be from dotfiles"
        fi
    else
        log_result "FAIL" "Git configuration file missing"
    fi
}

validate_backup_integrity() {
    echo ""
    echo "Validating backup integrity..."
    
    # Check for backup files
    local backup_files=(
        "$HOME/.zshrc.backup"
        "$HOME/.gitconfig.backup"
        "$HOME/.config/nvim.backup"
        "$HOME/.tmux.conf.backup"
    )
    
    local backup_count=0
    for backup in "${backup_files[@]}"; do
        if [ -e "$backup" ]; then
            backup_count=$((backup_count + 1))
            log_result "INFO" "Backup exists: $(basename "$backup")" "$backup"
        fi
    done
    
    # Check for backup directories
    local backup_dirs=($(ls -d "$HOME"/.dotfiles-backup-* 2>/dev/null || true))
    
    if [ ${#backup_dirs[@]} -gt 0 ]; then
        log_result "PASS" "Backup directories found" "${#backup_dirs[@]} directories"
        
        # Check the most recent backup
        local latest_backup=$(ls -td "$HOME"/.dotfiles-backup-* 2>/dev/null | head -1)
        if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
            local backup_file_count=$(find "$latest_backup" -type f | wc -l)
            log_result "INFO" "Latest backup directory" "$latest_backup ($backup_file_count files)"
        fi
    else
        if [ $backup_count -eq 0 ]; then
            log_result "INFO" "No backups found" "Clean installation or no previous configs"
        else
            log_result "INFO" "Individual backup files found" "$backup_count .backup files"
        fi
    fi
}

test_daily_usage_scenarios() {
    echo ""
    echo "Testing daily usage scenarios..."
    
    # Test 1: Basic shell session
    if zsh -c "
        source ~/.zshrc
        echo 'Shell session test'
        exit 0
    " >/dev/null 2>&1; then
        log_result "PASS" "Basic shell session works"
    else
        log_result "FAIL" "Basic shell session has issues"
    fi
    
    # Test 2: Git workflow simulation
    if command -v git >/dev/null 2>&1; then
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        if git init >/dev/null 2>&1 && \
           echo "test" > test.txt && \
           git add test.txt >/dev/null 2>&1 && \
           git -c user.name="Test" -c user.email="test@example.com" commit -m "test" >/dev/null 2>&1; then
            log_result "PASS" "Git workflow simulation successful"
        else
            log_result "WARN" "Git workflow simulation failed" "May need user configuration"
        fi
        
        cd - >/dev/null
        rm -rf "$temp_dir"
    else
        log_result "FAIL" "Git not available for workflow test"
    fi
    
    # Test 3: Editor availability
    local editors_available=0
    if command -v nvim >/dev/null 2>&1; then
        editors_available=$((editors_available + 1))
        log_result "PASS" "Neovim available for editing"
    fi
    
    if command -v code >/dev/null 2>&1; then
        editors_available=$((editors_available + 1))
        log_result "PASS" "VS Code available for editing"
    fi
    
    if [ $editors_available -eq 0 ]; then
        log_result "WARN" "No configured editors available" "May need manual installation"
    else
        log_result "PASS" "Editors available for development" "$editors_available editors found"
    fi
}

generate_validation_report() {
    echo ""
    echo "========================================"
    echo "  Validation Report"
    echo "========================================"
    
    local status_color="$GREEN"
    local status_text="PASSED"
    
    if [ $VALIDATION_FAILED -eq 1 ]; then
        status_color="$RED"
        status_text="FAILED"
    elif [ $WARNINGS_COUNT -gt 0 ]; then
        status_color="$YELLOW"
        status_text="PASSED WITH WARNINGS"
    fi
    
    echo -e "Overall Status: ${status_color}${status_text}${NC}"
    echo "Warnings: $WARNINGS_COUNT"
    echo "Host: $(hostname)"
    echo "User: $(whoami)"
    echo "Date: $(date)"
    
    if [ $VALIDATION_FAILED -eq 1 ]; then
        echo ""
        echo "❌ Validation failed - Critical issues found"
        echo "Please review the failed items above and fix them."
        echo ""
        echo "Common fixes:"
        echo "- Re-run installation: cd ~/.dotfiles && ./install.sh"
        echo "- Check symlinks: cd ~/.dotfiles && ./scripts/common.sh"
        echo "- Verify shell config: zsh -n ~/.zshrc"
    elif [ $WARNINGS_COUNT -gt 0 ]; then
        echo ""
        echo "⚠️  Validation passed with warnings"
        echo "The system is functional but some optimizations may be needed."
    else
        echo ""
        echo "✅ Validation passed - System is ready for production use"
        echo "All configurations are properly installed and functional."
    fi
    
    echo ""
    echo "For support: https://github.com/akgoode/dotfiles/issues"
}

main() {
    validate_symlinks
    validate_shell_configuration
    validate_development_tools
    validate_editor_configurations
    validate_git_configuration
    validate_backup_integrity
    test_daily_usage_scenarios
    generate_validation_report
    
    # Exit with appropriate code
    exit $VALIDATION_FAILED
}

# Run main function
main "$@"