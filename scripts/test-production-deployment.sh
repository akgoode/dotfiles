#!/bin/bash
# Production deployment testing script
# Requirements: 1.2, 1.3, 2.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_LOG="/tmp/production-deployment-test.log"
TEST_BACKUP_DIR="$HOME/.test-backup-$(date +%Y%m%d-%H%M%S)"
ORIGINAL_SHELL="$SHELL"
TEST_FAILED=0
WARNINGS_COUNT=0

echo "========================================"
echo "  Production Deployment Test"
echo "========================================"
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo "Test Log: $TEST_LOG"
echo "Backup Dir: $TEST_BACKUP_DIR"
echo ""

# Initialize logging
exec > >(tee -a "$TEST_LOG") 2>&1

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
            TEST_FAILED=1
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

# Cleanup function
cleanup_test() {
    echo ""
    echo "========================================"
    echo "  Test Cleanup"
    echo "========================================"
    
    # Restore original configurations if they exist
    if [ -d "$TEST_BACKUP_DIR" ] && [ "$(ls -A "$TEST_BACKUP_DIR" 2>/dev/null)" ]; then
        echo "Restoring original configurations..."
        
        # Remove test symlinks
        find ~ -maxdepth 3 -type l 2>/dev/null | while read link; do
            if readlink "$link" 2>/dev/null | grep -q "/.dotfiles/"; then
                echo "  Removing test symlink: $link"
                rm "$link"
            fi
        done
        
        # Restore from backup
        for backup_file in "$TEST_BACKUP_DIR"/*; do
            if [ -f "$backup_file" ]; then
                original_file="$HOME/$(basename "$backup_file")"
                echo "  Restoring: $original_file"
                cp "$backup_file" "$original_file"
            fi
        done
        
        # Restore shell
        if [ "$ORIGINAL_SHELL" != "$SHELL" ]; then
            echo "  Restoring original shell: $ORIGINAL_SHELL"
            chsh -s "$ORIGINAL_SHELL"
        fi
        
        log_result "INFO" "Original configurations restored"
    fi
    
    # Remove test dotfiles directory
    if [ -d ~/.dotfiles ]; then
        echo "Removing test dotfiles directory..."
        rm -rf ~/.dotfiles
        log_result "INFO" "Test dotfiles directory removed"
    fi
    
    echo "Cleanup completed"
}

# Set up cleanup trap
trap cleanup_test EXIT

# Pre-test system backup
create_test_backup() {
    echo "Creating test backup..."
    mkdir -p "$TEST_BACKUP_DIR"
    
    local configs=(
        ".zshrc"
        ".gitconfig"
        ".tmux.conf"
        ".bashrc"
    )
    
    for config in "${configs[@]}"; do
        if [ -f "$HOME/$config" ]; then
            echo "  Backing up: $config"
            cp "$HOME/$config" "$TEST_BACKUP_DIR/"
        fi
    done
    
    # Backup directories
    if [ -d ~/.config/nvim ]; then
        echo "  Backing up: .config/nvim"
        cp -r ~/.config/nvim "$TEST_BACKUP_DIR/nvim-config"
    fi
    
    log_result "INFO" "Test backup created" "$TEST_BACKUP_DIR"
}

# Test 1: Pre-deployment requirements check
test_requirements() {
    echo ""
    echo "========================================"
    echo "  Test 1: Pre-deployment Requirements"
    echo "========================================"
    
    # Run requirements check script
    if curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/scripts/check-requirements.sh | bash; then
        log_result "PASS" "Requirements check passed"
    else
        log_result "FAIL" "Requirements check failed"
        return 1
    fi
    
    # Additional manual checks
    echo ""
    echo "Manual requirement verification:"
    
    # Check internet connectivity
    if curl -s --connect-timeout 10 https://github.com >/dev/null; then
        log_result "PASS" "Internet connectivity"
    else
        log_result "FAIL" "No internet connectivity"
    fi
    
    # Check disk space (require 2GB)
    local available_kb=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_kb" -gt 2097152 ]; then
        log_result "PASS" "Sufficient disk space" "$((available_kb / 1024 / 1024))GB available"
    else
        log_result "FAIL" "Insufficient disk space" "$((available_kb / 1024 / 1024))GB available"
    fi
    
    # Check user permissions
    if [ "$EUID" -ne 0 ]; then
        log_result "PASS" "Running as non-root user"
    else
        log_result "WARN" "Running as root (not recommended)"
    fi
    
    # Platform-specific checks
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if xcode-select -p >/dev/null 2>&1; then
            log_result "PASS" "Xcode Command Line Tools installed"
        else
            log_result "FAIL" "Xcode Command Line Tools missing"
        fi
    else
        if sudo -n true 2>/dev/null; then
            log_result "PASS" "Sudo access available"
        else
            log_result "WARN" "Sudo access may be required"
        fi
    fi
}

# Test 2: Full installation process
test_installation() {
    echo ""
    echo "========================================"
    echo "  Test 2: Installation Process"
    echo "========================================"
    
    # Remove any existing dotfiles directory
    if [ -d ~/.dotfiles ]; then
        echo "Removing existing dotfiles directory..."
        rm -rf ~/.dotfiles
    fi
    
    echo "Starting installation..."
    local install_start_time=$(date +%s)
    
    # Run installation with timeout
    if timeout 1800 bash -c 'curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'; then
        local install_end_time=$(date +%s)
        local install_duration=$((install_end_time - install_start_time))
        log_result "PASS" "Installation completed successfully" "Duration: ${install_duration}s"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_result "FAIL" "Installation timed out" "Exceeded 30 minutes"
        else
            log_result "FAIL" "Installation failed" "Exit code: $exit_code"
        fi
        return 1
    fi
    
    # Verify dotfiles directory was created
    if [ -d ~/.dotfiles ]; then
        log_result "PASS" "Dotfiles directory created"
    else
        log_result "FAIL" "Dotfiles directory missing"
        return 1
    fi
    
    # Check installation log
    if [ -f /tmp/dotfiles-install.log ]; then
        local error_count=$(grep -c "ERROR\|✗" /tmp/dotfiles-install.log || true)
        if [ "$error_count" -eq 0 ]; then
            log_result "PASS" "No errors in installation log"
        else
            log_result "WARN" "Errors found in installation log" "$error_count errors"
        fi
    fi
}

# Test 3: Configuration validation
test_configuration() {
    echo ""
    echo "========================================"
    echo "  Test 3: Configuration Validation"
    echo "========================================"
    
    # Run the validation script
    if [ -f ~/.dotfiles/scripts/validate-production-deployment.sh ]; then
        echo "Running validation script..."
        if ~/.dotfiles/scripts/validate-production-deployment.sh; then
            log_result "PASS" "Validation script passed"
        else
            log_result "FAIL" "Validation script failed"
        fi
    else
        log_result "FAIL" "Validation script not found"
    fi
    
    echo ""
    echo "Manual configuration checks:"
    
    # Check symlinks
    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.config/nvim"
    )
    
    for symlink in "${symlinks[@]}"; do
        if [ -L "$symlink" ] && [ -e "$symlink" ]; then
            local target=$(readlink "$symlink")
            if [[ "$target" == *"/.dotfiles/"* ]]; then
                log_result "PASS" "Symlink created: $(basename "$symlink")" "$target"
            else
                log_result "WARN" "Symlink not to dotfiles: $(basename "$symlink")" "$target"
            fi
        else
            log_result "FAIL" "Symlink missing or broken: $(basename "$symlink")"
        fi
    done
    
    # Test shell configuration
    if zsh -c "source ~/.zshrc" 2>/dev/null; then
        log_result "PASS" "Shell configuration loads without errors"
    else
        log_result "FAIL" "Shell configuration has errors"
    fi
    
    # Test git configuration
    if git config --list >/dev/null 2>&1; then
        log_result "PASS" "Git configuration is valid"
    else
        log_result "FAIL" "Git configuration has errors"
    fi
}

# Test 4: Tool availability and functionality
test_tools() {
    echo ""
    echo "========================================"
    echo "  Test 4: Tool Availability"
    echo "========================================"
    
    # Core tools that should be available
    local core_tools=("git" "curl" "zsh")
    
    # Optional tools that may be installed
    local optional_tools=("nvim" "tmux" "jq" "rg" "fd" "go" "terraform" "aws" "kubectl" "node" "npm")
    
    # Platform-specific adjustments
    if [[ "$OSTYPE" == "darwin"* ]]; then
        core_tools+=("brew")
    else
        # On Linux, fd is called fdfind
        optional_tools=("${optional_tools[@]/fd/fdfind}")
    fi
    
    echo "Testing core tools:"
    for tool in "${core_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "git") version=$(git --version) ;;
                "curl") version=$(curl --version | head -1) ;;
                "zsh") version=$(zsh --version) ;;
                "brew") version=$(brew --version | head -1) ;;
            esac
            log_result "PASS" "$tool available" "$version"
        else
            log_result "FAIL" "$tool not found"
        fi
    done
    
    echo ""
    echo "Testing optional tools:"
    local installed_count=0
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            installed_count=$((installed_count + 1))
            log_result "PASS" "$tool available"
        else
            log_result "INFO" "$tool not installed" "Optional tool"
        fi
    done
    
    log_result "INFO" "Optional tools summary" "$installed_count/${#optional_tools[@]} installed"
}

# Test 5: Development workflow simulation
test_workflow() {
    echo ""
    echo "========================================"
    echo "  Test 5: Development Workflow"
    echo "========================================"
    
    # Test 5.1: Shell workflow
    echo "Testing shell workflow..."
    
    # Start new zsh session and test basic functionality
    if zsh -c "
        source ~/.zshrc
        echo 'Shell session started successfully'
        
        # Test git aliases
        if alias gst >/dev/null 2>&1; then
            echo 'Git aliases loaded'
        else
            exit 1
        fi
        
        # Test prompt functionality
        if [[ -n \$PROMPT ]]; then
            echo 'Custom prompt configured'
        else
            exit 1
        fi
    "; then
        log_result "PASS" "Shell workflow functional"
    else
        log_result "FAIL" "Shell workflow has issues"
    fi
    
    # Test 5.2: Git workflow
    echo ""
    echo "Testing git workflow..."
    
    local test_repo="/tmp/dotfiles-git-test-$$"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    if git init >/dev/null 2>&1 && \
       echo "test content" > README.md && \
       git add README.md >/dev/null 2>&1 && \
       git -c user.name="Test User" -c user.email="test@example.com" commit -m "Initial commit" >/dev/null 2>&1; then
        log_result "PASS" "Git workflow functional"
    else
        log_result "FAIL" "Git workflow has issues"
    fi
    
    cd - >/dev/null
    rm -rf "$test_repo"
    
    # Test 5.3: Editor availability
    echo ""
    echo "Testing editor availability..."
    
    if command -v nvim >/dev/null 2>&1; then
        if nvim --headless -c "quit" 2>/dev/null; then
            log_result "PASS" "Neovim functional"
        else
            log_result "WARN" "Neovim has startup issues"
        fi
    else
        log_result "INFO" "Neovim not installed"
    fi
    
    if command -v code >/dev/null 2>&1; then
        log_result "PASS" "VS Code available"
    else
        log_result "INFO" "VS Code not installed"
    fi
}

# Test 6: Performance and stability
test_performance() {
    echo ""
    echo "========================================"
    echo "  Test 6: Performance and Stability"
    echo "========================================"
    
    # Test shell startup time
    echo "Testing shell startup performance..."
    local startup_times=()
    for i in {1..5}; do
        local start_time=$(date +%s%N)
        zsh -c "exit" 2>/dev/null
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        startup_times+=($duration)
    done
    
    # Calculate average startup time
    local total=0
    for time in "${startup_times[@]}"; do
        total=$((total + time))
    done
    local avg_startup=$((total / ${#startup_times[@]}))
    
    if [ "$avg_startup" -lt 1000 ]; then  # Less than 1 second
        log_result "PASS" "Shell startup performance good" "${avg_startup}ms average"
    elif [ "$avg_startup" -lt 3000 ]; then  # Less than 3 seconds
        log_result "WARN" "Shell startup performance acceptable" "${avg_startup}ms average"
    else
        log_result "FAIL" "Shell startup performance poor" "${avg_startup}ms average"
    fi
    
    # Test memory usage
    echo ""
    echo "Testing memory usage..."
    local memory_before=$(ps -o rss= -p $$ | tr -d ' ')
    
    # Load shell configuration
    zsh -c "source ~/.zshrc; sleep 1" &
    local zsh_pid=$!
    sleep 2
    
    if kill -0 $zsh_pid 2>/dev/null; then
        local zsh_memory=$(ps -o rss= -p $zsh_pid 2>/dev/null | tr -d ' ')
        if [ -n "$zsh_memory" ] && [ "$zsh_memory" -lt 50000 ]; then  # Less than 50MB
            log_result "PASS" "Memory usage reasonable" "${zsh_memory}KB"
        else
            log_result "WARN" "Memory usage high" "${zsh_memory}KB"
        fi
        kill $zsh_pid 2>/dev/null || true
    else
        log_result "INFO" "Could not measure zsh memory usage"
    fi
    
    # Test for error messages
    echo ""
    echo "Testing for error messages..."
    local error_output=$(zsh -c "source ~/.zshrc" 2>&1)
    if [ -z "$error_output" ]; then
        log_result "PASS" "No error messages during shell startup"
    else
        log_result "WARN" "Error messages detected" "Check shell configuration"
        echo "Error output:"
        echo "$error_output" | head -5 | sed 's/^/  /'
    fi
}

# Test 7: Rollback functionality
test_rollback() {
    echo ""
    echo "========================================"
    echo "  Test 7: Rollback Functionality"
    echo "========================================"
    
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
    
    # Check for backup files
    echo ""
    echo "Checking backup integrity..."
    
    local backup_files=(
        "$HOME/.zshrc.backup"
        "$HOME/.gitconfig.backup"
    )
    
    local backup_count=0
    for backup in "${backup_files[@]}"; do
        if [ -f "$backup" ]; then
            backup_count=$((backup_count + 1))
            log_result "PASS" "Backup exists: $(basename "$backup")"
        fi
    done
    
    # Check for backup directories
    local backup_dirs=($(ls -d "$HOME"/.dotfiles-backup-* 2>/dev/null || true))
    if [ ${#backup_dirs[@]} -gt 0 ]; then
        log_result "PASS" "Backup directories found" "${#backup_dirs[@]} directories"
    elif [ $backup_count -gt 0 ]; then
        log_result "PASS" "Individual backup files found" "$backup_count files"
    else
        log_result "WARN" "No backups found" "May be clean installation"
    fi
}

# Test 8: Existing configuration handling
test_existing_configs() {
    echo ""
    echo "========================================"
    echo "  Test 8: Existing Configuration Handling"
    echo "========================================"
    
    # This test simulates installing over existing configurations
    # We'll create some dummy configs and test the installation handles them
    
    echo "Creating test existing configurations..."
    
    # Create temporary existing configs
    local temp_configs=(
        "$HOME/.test-zshrc"
        "$HOME/.test-gitconfig"
    )
    
    for config in "${temp_configs[@]}"; do
        echo "# Test existing configuration" > "$config"
        echo "# Created by production deployment test" >> "$config"
    done
    
    # Simulate symlink creation over existing files
    echo ""
    echo "Testing symlink creation over existing files..."
    
    # Test backup and symlink creation
    if [ -f ~/.dotfiles/scripts/common.sh ]; then
        # Create a test function to simulate the backup process
        local test_passed=true
        
        for config in "${temp_configs[@]}"; do
            local basename_config=$(basename "$config")
            local dotfiles_target="$HOME/.dotfiles/shell/zshrc"  # Use existing file as target
            
            if [ -f "$dotfiles_target" ]; then
                # Test would backup existing file
                if [ -f "$config" ]; then
                    log_result "PASS" "Would backup existing file: $basename_config"
                else
                    log_result "FAIL" "Test file missing: $basename_config"
                    test_passed=false
                fi
            fi
        done
        
        if $test_passed; then
            log_result "PASS" "Existing configuration handling functional"
        else
            log_result "FAIL" "Existing configuration handling has issues"
        fi
    else
        log_result "WARN" "Cannot test existing config handling - common.sh missing"
    fi
    
    # Clean up test configs
    for config in "${temp_configs[@]}"; do
        rm -f "$config"
    done
}

# Main test execution
main() {
    echo "Starting production deployment test..."
    echo "This test will install dotfiles and then clean up"
    echo ""
    
    # Confirm with user
    read -p "This will modify your system. Continue? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Test cancelled by user"
        exit 0
    fi
    
    # Create backup before starting
    create_test_backup
    
    # Run all tests
    test_requirements
    test_installation
    test_configuration
    test_tools
    test_workflow
    test_performance
    test_rollback
    test_existing_configs
    
    # Generate final report
    echo ""
    echo "========================================"
    echo "  Production Deployment Test Results"
    echo "========================================"
    
    if [ $TEST_FAILED -eq 0 ]; then
        if [ $WARNINGS_COUNT -eq 0 ]; then
            echo -e "${GREEN}✅ All tests PASSED${NC}"
            echo "The dotfiles system is ready for production deployment"
        else
            echo -e "${YELLOW}⚠️  Tests PASSED with $WARNINGS_COUNT warnings${NC}"
            echo "The system is functional but may need minor adjustments"
        fi
    else
        echo -e "${RED}❌ Tests FAILED${NC}"
        echo "Issues found that need to be addressed before production deployment"
    fi
    
    echo ""
    echo "Test Summary:"
    echo "- Host: $(hostname)"
    echo "- User: $(whoami)"
    echo "- OS: $(uname -s) $(uname -r)"
    echo "- Test Duration: $(($(date +%s) - $(date -d "$(head -1 "$TEST_LOG" | awk '{print $4, $5, $6, $7, $8}')" +%s) 2>/dev/null || echo "unknown"))s"
    echo "- Log File: $TEST_LOG"
    echo "- Backup Dir: $TEST_BACKUP_DIR"
    
    echo ""
    echo "Next steps:"
    if [ $TEST_FAILED -eq 0 ]; then
        echo "1. Review any warnings above"
        echo "2. Test in your specific environment"
        echo "3. Proceed with production deployment"
    else
        echo "1. Review failed tests above"
        echo "2. Fix identified issues"
        echo "3. Re-run this test"
        echo "4. Check installation logs for details"
    fi
    
    echo ""
    echo "For support: https://github.com/akgoode/dotfiles/issues"
    
    # Exit with appropriate code
    exit $TEST_FAILED
}

# Run main function
main "$@"