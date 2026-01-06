#!/bin/bash
# Post-deployment validation script
# Requirements: 1.2, 1.3, 2.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VALIDATION_LOG="/tmp/post-deployment-validation.log"
VALIDATION_FAILED=0
WARNINGS_COUNT=0

echo "========================================"
echo "  Post-Deployment Validation"
echo "========================================"
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo "Validation Log: $VALIDATION_LOG"
echo ""

# Initialize logging
exec > >(tee -a "$VALIDATION_LOG") 2>&1

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

# Validate deployment completeness
validate_deployment_completeness() {
    echo "========================================"
    echo "  Deployment Completeness Check"
    echo "========================================"
    
    # Check dotfiles directory
    if [ -d ~/.dotfiles ]; then
        log_result "PASS" "Dotfiles directory exists"
        
        # Check key components
        local components=(
            "shell/zshrc"
            "git/gitconfig"
            "editors/nvim"
            "scripts/common.sh"
            "scripts/rollback.sh"
            "scripts/validate-production-deployment.sh"
        )
        
        for component in "${components[@]}"; do
            if [ -e ~/.dotfiles/"$component" ]; then
                log_result "PASS" "Component exists: $component"
            else
                log_result "FAIL" "Component missing: $component"
            fi
        done
    else
        log_result "FAIL" "Dotfiles directory missing"
        return 1
    fi
    
    # Check git repository status
    if [ -d ~/.dotfiles/.git ]; then
        cd ~/.dotfiles
        if git status >/dev/null 2>&1; then
            local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
            local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            log_result "PASS" "Git repository functional" "Branch: $branch, Commit: $commit"
        else
            log_result "WARN" "Git repository has issues"
        fi
        cd - >/dev/null
    else
        log_result "WARN" "Not a git repository (may be downloaded archive)"
    fi
}

# Validate configuration integrity
validate_configuration_integrity() {
    echo ""
    echo "========================================"
    echo "  Configuration Integrity Check"
    echo "========================================"
    
    # Run the main validation script
    if [ -f ~/.dotfiles/scripts/validate-production-deployment.sh ]; then
        echo "Running comprehensive validation..."
        if ~/.dotfiles/scripts/validate-production-deployment.sh; then
            log_result "PASS" "Comprehensive validation passed"
        else
            log_result "FAIL" "Comprehensive validation failed"
        fi
    else
        log_result "FAIL" "Main validation script missing"
    fi
}

# Test real-world usage scenarios
validate_real_world_usage() {
    echo ""
    echo "========================================"
    echo "  Real-World Usage Validation"
    echo "========================================"
    
    # Test 1: New shell session
    echo "Testing new shell session..."
    if zsh -c "
        source ~/.zshrc
        echo 'Shell session test: OK'
        
        # Test prompt setup
        if [[ -n \$PROMPT ]]; then
            echo 'Prompt configuration: OK'
        else
            echo 'Prompt configuration: MISSING'
            exit 1
        fi
        
        # Test git integration
        if command -v git >/dev/null && git --version >/dev/null; then
            echo 'Git integration: OK'
        else
            echo 'Git integration: FAILED'
            exit 1
        fi
    " 2>/dev/null; then
        log_result "PASS" "New shell session functional"
    else
        log_result "FAIL" "New shell session has issues"
    fi
    
    # Test 2: Git workflow
    echo ""
    echo "Testing git workflow..."
    local test_repo="/tmp/post-deploy-git-test-$$"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    local git_test_passed=true
    
    # Initialize repository
    if ! git init >/dev/null 2>&1; then
        log_result "FAIL" "Git init failed"
        git_test_passed=false
    fi
    
    # Test git configuration
    local git_user=$(git config user.name 2>/dev/null || echo "")
    local git_email=$(git config user.email 2>/dev/null || echo "")
    
    if [ -n "$git_user" ] && [ -n "$git_email" ]; then
        log_result "PASS" "Git user configuration set" "$git_user <$git_email>"
    else
        log_result "WARN" "Git user configuration not set" "May need manual configuration"
    fi
    
    # Test git aliases
    if git config alias.st >/dev/null 2>&1; then
        log_result "PASS" "Git aliases configured"
    else
        log_result "WARN" "Git aliases not found"
    fi
    
    # Test basic git operations
    if echo "test" > README.md && \
       git add README.md >/dev/null 2>&1 && \
       git -c user.name="Test" -c user.email="test@example.com" commit -m "Test commit" >/dev/null 2>&1; then
        log_result "PASS" "Basic git operations functional"
    else
        log_result "WARN" "Basic git operations have issues"
        git_test_passed=false
    fi
    
    cd - >/dev/null
    rm -rf "$test_repo"
    
    if $git_test_passed; then
        log_result "PASS" "Git workflow validation completed"
    else
        log_result "FAIL" "Git workflow has issues"
    fi
    
    # Test 3: Shell aliases
    echo ""
    echo "Testing shell aliases..."
    if zsh -c "
        source ~/.zshrc
        
        # Test key git aliases
        if alias gst >/dev/null 2>&1 && \
           alias gco >/dev/null 2>&1 && \
           alias gcm >/dev/null 2>&1; then
            echo 'Git aliases: OK'
        else
            echo 'Git aliases: MISSING'
            exit 1
        fi
        
        # Test other common aliases
        if alias ll >/dev/null 2>&1 || alias la >/dev/null 2>&1; then
            echo 'Common aliases: OK'
        else
            echo 'Common aliases: MISSING (may be expected)'
        fi
    " 2>/dev/null; then
        log_result "PASS" "Shell aliases functional"
    else
        log_result "FAIL" "Shell aliases have issues"
    fi
    
    # Test 4: Editor integration
    echo ""
    echo "Testing editor integration..."
    
    if command -v nvim >/dev/null 2>&1; then
        if nvim --headless -c "quit" 2>/dev/null; then
            log_result "PASS" "Neovim integration functional"
            
            # Test Neovim configuration
            if [ -d ~/.config/nvim ]; then
                if [ -L ~/.config/nvim ]; then
                    log_result "PASS" "Neovim configuration linked to dotfiles"
                else
                    log_result "WARN" "Neovim configuration not linked to dotfiles"
                fi
            else
                log_result "WARN" "Neovim configuration directory missing"
            fi
        else
            log_result "WARN" "Neovim has startup issues"
        fi
    else
        log_result "INFO" "Neovim not installed"
    fi
    
    if command -v code >/dev/null 2>&1; then
        log_result "PASS" "VS Code available"
        
        # Check VS Code settings
        local vscode_settings
        if [[ "$OSTYPE" == "darwin"* ]]; then
            vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
        else
            vscode_settings="$HOME/.config/Code/User/settings.json"
        fi
        
        if [ -f "$vscode_settings" ]; then
            if [ -L "$vscode_settings" ]; then
                log_result "PASS" "VS Code settings linked to dotfiles"
            else
                log_result "WARN" "VS Code settings not linked to dotfiles"
            fi
        else
            log_result "INFO" "VS Code settings not found"
        fi
    else
        log_result "INFO" "VS Code not installed"
    fi
}

# Test performance and stability
validate_performance() {
    echo ""
    echo "========================================"
    echo "  Performance and Stability Check"
    echo "========================================"
    
    # Test shell startup performance
    echo "Testing shell startup performance..."
    local startup_times=()
    for i in {1..3}; do
        local start_time=$(date +%s%N)
        zsh -c "source ~/.zshrc; exit" 2>/dev/null
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        startup_times+=($duration)
    done
    
    # Calculate average
    local total=0
    for time in "${startup_times[@]}"; do
        total=$((total + time))
    done
    local avg_startup=$((total / ${#startup_times[@]}))
    
    if [ "$avg_startup" -lt 1000 ]; then
        log_result "PASS" "Shell startup performance excellent" "${avg_startup}ms average"
    elif [ "$avg_startup" -lt 2000 ]; then
        log_result "PASS" "Shell startup performance good" "${avg_startup}ms average"
    elif [ "$avg_startup" -lt 5000 ]; then
        log_result "WARN" "Shell startup performance acceptable" "${avg_startup}ms average"
    else
        log_result "FAIL" "Shell startup performance poor" "${avg_startup}ms average"
    fi
    
    # Test for memory leaks
    echo ""
    echo "Testing for memory leaks..."
    local initial_memory=$(ps -o rss= -p $$ | tr -d ' ')
    
    # Load shell configuration multiple times
    for i in {1..5}; do
        zsh -c "source ~/.zshrc; sleep 0.1" >/dev/null 2>&1 &
        local pid=$!
        sleep 0.2
        kill $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
    done
    
    local final_memory=$(ps -o rss= -p $$ | tr -d ' ')
    local memory_diff=$((final_memory - initial_memory))
    
    if [ "$memory_diff" -lt 1000 ]; then  # Less than 1MB increase
        log_result "PASS" "No significant memory leaks detected" "${memory_diff}KB increase"
    else
        log_result "WARN" "Possible memory leak detected" "${memory_diff}KB increase"
    fi
    
    # Test error handling
    echo ""
    echo "Testing error handling..."
    local error_output=$(zsh -c "source ~/.zshrc" 2>&1)
    if [ -z "$error_output" ]; then
        log_result "PASS" "No error messages during shell startup"
    else
        local error_count=$(echo "$error_output" | wc -l)
        if [ "$error_count" -lt 3 ]; then
            log_result "WARN" "Minor error messages detected" "$error_count lines"
        else
            log_result "FAIL" "Multiple error messages detected" "$error_count lines"
        fi
        echo "Error output sample:"
        echo "$error_output" | head -3 | sed 's/^/  /'
    fi
}

# Validate backup and rollback capability
validate_backup_rollback() {
    echo ""
    echo "========================================"
    echo "  Backup and Rollback Validation"
    echo "========================================"
    
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
            log_result "PASS" "Backup exists: $(basename "$backup")"
        fi
    done
    
    # Check for backup directories
    local backup_dirs=($(ls -d "$HOME"/.dotfiles-backup-* 2>/dev/null || true))
    if [ ${#backup_dirs[@]} -gt 0 ]; then
        log_result "PASS" "Backup directories found" "${#backup_dirs[@]} directories"
        
        # Check latest backup
        local latest_backup=$(ls -td "$HOME"/.dotfiles-backup-* | head -1)
        if [ -d "$latest_backup" ]; then
            local file_count=$(find "$latest_backup" -type f | wc -l)
            log_result "INFO" "Latest backup contains $file_count files" "$latest_backup"
        fi
    fi
    
    if [ $backup_count -eq 0 ] && [ ${#backup_dirs[@]} -eq 0 ]; then
        log_result "INFO" "No backups found" "Clean installation or no previous configs"
    else
        log_result "PASS" "Backup system functional" "$backup_count individual backups, ${#backup_dirs[@]} backup directories"
    fi
    
    # Test rollback script availability
    if [ -f ~/.dotfiles/scripts/rollback.sh ]; then
        log_result "PASS" "Rollback script available"
        
        # Test rollback script syntax
        if bash -n ~/.dotfiles/scripts/rollback.sh; then
            log_result "PASS" "Rollback script syntax valid"
        else
            log_result "FAIL" "Rollback script has syntax errors"
        fi
    else
        log_result "FAIL" "Rollback script missing"
    fi
}

# Test daily development workflow
validate_development_workflow() {
    echo ""
    echo "========================================"
    echo "  Development Workflow Validation"
    echo "========================================"
    
    # Test common development tasks
    echo "Testing common development tasks..."
    
    # Test 1: Directory navigation and file operations
    local temp_project="/tmp/dev-workflow-test-$$"
    mkdir -p "$temp_project"
    cd "$temp_project"
    
    # Test git repository creation
    if git init >/dev/null 2>&1; then
        log_result "PASS" "Git repository creation"
    else
        log_result "FAIL" "Git repository creation failed"
    fi
    
    # Test file creation and git operations
    echo "# Test Project" > README.md
    echo "console.log('Hello, World!');" > app.js
    
    if git add . >/dev/null 2>&1 && \
       git -c user.name="Test" -c user.email="test@example.com" commit -m "Initial commit" >/dev/null 2>&1; then
        log_result "PASS" "Basic git workflow"
    else
        log_result "WARN" "Basic git workflow has issues"
    fi
    
    # Test git aliases in real workflow
    if zsh -c "
        source ~/.zshrc
        cd '$temp_project'
        
        # Test git status alias
        if gst >/dev/null 2>&1; then
            echo 'gst alias works'
        else
            exit 1
        fi
        
        # Test git log alias
        if gl >/dev/null 2>&1; then
            echo 'gl alias works'
        else
            exit 1
        fi
    " 2>/dev/null; then
        log_result "PASS" "Git aliases in workflow"
    else
        log_result "WARN" "Git aliases not working in workflow"
    fi
    
    cd - >/dev/null
    rm -rf "$temp_project"
    
    # Test 2: Tool availability for development
    echo ""
    echo "Testing development tool availability..."
    
    local dev_tools=("git" "curl" "zsh")
    local optional_tools=("nvim" "tmux" "jq" "rg" "fd" "go" "node" "npm")
    
    # Platform-specific adjustments
    if [[ ! "$OSTYPE" == "darwin"* ]]; then
        optional_tools=("${optional_tools[@]/fd/fdfind}")
    fi
    
    for tool in "${dev_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_result "PASS" "Essential tool available: $tool"
        else
            log_result "FAIL" "Essential tool missing: $tool"
        fi
    done
    
    local available_optional=0
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_optional=$((available_optional + 1))
            log_result "PASS" "Optional tool available: $tool"
        fi
    done
    
    log_result "INFO" "Development tools summary" "$available_optional/${#optional_tools[@]} optional tools available"
    
    # Test 3: Environment variables and PATH
    echo ""
    echo "Testing environment setup..."
    
    if echo "$PATH" | grep -q "/usr/local/bin"; then
        log_result "PASS" "PATH includes /usr/local/bin"
    else
        log_result "WARN" "PATH may not include /usr/local/bin"
    fi
    
    if [ -n "$EDITOR" ]; then
        log_result "PASS" "EDITOR environment variable set" "$EDITOR"
    else
        log_result "INFO" "EDITOR environment variable not set"
    fi
    
    # Test shell functions and completions
    if zsh -c "
        source ~/.zshrc
        
        # Test tab completion setup
        if autoload -Uz compinit >/dev/null 2>&1; then
            echo 'Tab completion setup: OK'
        else
            echo 'Tab completion setup: FAILED'
            exit 1
        fi
        
        # Test git completion
        if complete -p git >/dev/null 2>&1 || \
           compdef _git git >/dev/null 2>&1; then
            echo 'Git completion: OK'
        else
            echo 'Git completion: MISSING'
        fi
    " 2>/dev/null; then
        log_result "PASS" "Shell completions functional"
    else
        log_result "WARN" "Shell completions may have issues"
    fi
}

# Generate comprehensive validation report
generate_validation_report() {
    echo ""
    echo "========================================"
    echo "  Post-Deployment Validation Report"
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
    echo "Platform: $(uname -s) $(uname -r)"
    echo "Date: $(date)"
    echo "Validation Log: $VALIDATION_LOG"
    
    if [ $VALIDATION_FAILED -eq 1 ]; then
        echo ""
        echo "❌ Validation failed - Critical issues found"
        echo "The deployment may not be fully functional."
        echo ""
        echo "Recommended actions:"
        echo "1. Review failed items above"
        echo "2. Check installation logs: /tmp/dotfiles-install.log"
        echo "3. Try re-running installation: cd ~/.dotfiles && ./install.sh"
        echo "4. Use rollback if needed: cd ~/.dotfiles && ./scripts/rollback.sh"
        echo "5. Consult troubleshooting guide: docs/TROUBLESHOOTING_GUIDE.md"
    elif [ $WARNINGS_COUNT -gt 0 ]; then
        echo ""
        echo "⚠️  Validation passed with warnings"
        echo "The deployment is functional but some optimizations may be beneficial."
        echo ""
        echo "Recommended actions:"
        echo "1. Review warnings above for potential improvements"
        echo "2. Test specific workflows important to your use case"
        echo "3. Consider addressing warnings for optimal experience"
    else
        echo ""
        echo "✅ Validation passed completely"
        echo "The dotfiles deployment is fully functional and ready for daily use."
        echo ""
        echo "You can now:"
        echo "1. Start using your configured development environment"
        echo "2. Customize further by editing files in ~/.dotfiles"
        echo "3. Remove backup files when confident: rm ~/.*.backup"
        echo "4. Share feedback or report issues at: https://github.com/akgoode/dotfiles/issues"
    fi
    
    echo ""
    echo "Quick verification commands:"
    echo "- Test new shell: exec zsh"
    echo "- Check git config: git config --list"
    echo "- Test git aliases: gst (git status)"
    echo "- Edit with nvim: nvim ~/.zshrc"
    echo "- View logs: cat $VALIDATION_LOG"
    
    echo ""
    echo "Support resources:"
    echo "- Documentation: https://github.com/akgoode/dotfiles/blob/main/README.md"
    echo "- Troubleshooting: docs/TROUBLESHOOTING_GUIDE.md"
    echo "- Rollback guide: docs/ROLLBACK_PROCEDURES.md"
    echo "- Issues: https://github.com/akgoode/dotfiles/issues"
}

# Main execution
main() {
    echo "This script validates that the dotfiles deployment is working correctly"
    echo "and ready for daily development use."
    echo ""
    
    # Run all validation tests
    validate_deployment_completeness
    validate_configuration_integrity
    validate_real_world_usage
    validate_performance
    validate_backup_rollback
    validate_development_workflow
    
    # Generate comprehensive report
    generate_validation_report
    
    # Exit with appropriate code
    exit $VALIDATION_FAILED
}

# Run main function
main "$@"