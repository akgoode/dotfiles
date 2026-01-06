#!/bin/bash
# Test deployment over existing configurations
# Requirements: 1.2, 1.3, 2.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TEST_LOG="/tmp/existing-config-deployment-test.log"
TEST_FAILED=0
WARNINGS_COUNT=0

echo "========================================"
echo "  Existing Configuration Deployment Test"
echo "========================================"
echo "This test simulates installing dotfiles over existing configurations"
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
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

# Create realistic existing configurations
create_existing_configs() {
    echo "========================================"
    echo "  Creating Existing Configurations"
    echo "========================================"
    
    # Create existing .zshrc
    cat > ~/.zshrc << 'EOF'
# Existing zsh configuration
export PATH="/usr/local/bin:$PATH"
export EDITOR=vim

# Custom prompt
PS1="%n@%m:%~$ "

# Some aliases
alias ll='ls -la'
alias grep='grep --color=auto'

# Custom function
myfunction() {
    echo "This is my custom function"
}

# Load custom settings
if [ -f ~/.zsh_custom ]; then
    source ~/.zsh_custom
fi
EOF
    
    # Create existing .gitconfig
    cat > ~/.gitconfig << 'EOF'
[user]
    name = Test User
    email = test@example.com

[core]
    editor = vim
    autocrlf = input

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit

[push]
    default = simple

[pull]
    rebase = false
EOF
    
    # Create existing .tmux.conf
    cat > ~/.tmux.conf << 'EOF'
# Existing tmux configuration
set -g default-terminal "screen-256color"
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Window splitting
bind | split-window -h
bind - split-window -v

# Pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
EOF
    
    # Create existing Neovim configuration
    mkdir -p ~/.config/nvim
    cat > ~/.config/nvim/init.vim << 'EOF'
" Existing Neovim configuration
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

" Key mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Color scheme
colorscheme default
syntax on
EOF
    
    # Create existing VS Code settings
    local vscode_dir
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vscode_dir="$HOME/Library/Application Support/Code/User"
    else
        vscode_dir="$HOME/.config/Code/User"
    fi
    
    if command -v code >/dev/null 2>&1; then
        mkdir -p "$vscode_dir"
        cat > "$vscode_dir/settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "workbench.colorTheme": "Default Dark+",
    "files.autoSave": "afterDelay",
    "terminal.integrated.shell.osx": "/bin/zsh",
    "git.enableSmartCommit": true
}
EOF
        log_result "INFO" "Created existing VS Code settings"
    fi
    
    # Create some custom files that shouldn't be overwritten
    echo "# Custom zsh additions" > ~/.zsh_custom
    echo "alias mycustomalias='echo custom'" >> ~/.zsh_custom
    
    log_result "INFO" "Created realistic existing configurations"
    
    # Document what we created
    echo ""
    echo "Existing configurations created:"
    echo "  ~/.zshrc (custom prompt and aliases)"
    echo "  ~/.gitconfig (user settings and aliases)"
    echo "  ~/.tmux.conf (custom key bindings)"
    echo "  ~/.config/nvim/init.vim (basic vim settings)"
    echo "  ~/.zsh_custom (custom additions)"
    if [ -f "$vscode_dir/settings.json" ]; then
        echo "  VS Code settings.json"
    fi
}

# Test backup functionality
test_backup_creation() {
    echo ""
    echo "========================================"
    echo "  Testing Backup Creation"
    echo "========================================"
    
    # Record checksums of existing files before installation
    local checksums_before=""
    for file in ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/nvim/init.vim; do
        if [ -f "$file" ]; then
            local checksum=$(md5sum "$file" 2>/dev/null || md5 "$file" 2>/dev/null || echo "unknown")
            checksums_before="$checksums_before$file:$checksum\n"
        fi
    done
    
    echo "Recorded checksums of existing files"
    log_result "INFO" "Pre-installation state documented"
    
    # Store checksums for later verification
    echo -e "$checksums_before" > /tmp/pre-install-checksums.txt
}

# Run the installation
test_installation_over_existing() {
    echo ""
    echo "========================================"
    echo "  Testing Installation Over Existing Configs"
    echo "========================================"
    
    echo "Running dotfiles installation..."
    local install_start=$(date +%s)
    
    # Run installation
    if curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash; then
        local install_end=$(date +%s)
        local duration=$((install_end - install_start))
        log_result "PASS" "Installation completed successfully" "Duration: ${duration}s"
    else
        log_result "FAIL" "Installation failed over existing configurations"
        return 1
    fi
    
    # Verify dotfiles directory exists
    if [ -d ~/.dotfiles ]; then
        log_result "PASS" "Dotfiles directory created"
    else
        log_result "FAIL" "Dotfiles directory missing"
    fi
}

# Verify backup integrity
test_backup_integrity() {
    echo ""
    echo "========================================"
    echo "  Testing Backup Integrity"
    echo "========================================"
    
    # Check for .backup files
    local backup_files=(
        "$HOME/.zshrc.backup"
        "$HOME/.gitconfig.backup"
        "$HOME/.tmux.conf.backup"
    )
    
    local backup_count=0
    for backup in "${backup_files[@]}"; do
        if [ -f "$backup" ]; then
            backup_count=$((backup_count + 1))
            log_result "PASS" "Backup created: $(basename "$backup")"
            
            # Verify backup content matches original
            local original_file="${backup%.backup}"
            if [ -f "/tmp/pre-install-checksums.txt" ]; then
                local original_checksum=$(grep "$original_file:" /tmp/pre-install-checksums.txt | cut -d: -f2- || echo "")
                local backup_checksum=$(md5sum "$backup" 2>/dev/null || md5 "$backup" 2>/dev/null || echo "unknown")
                
                if [[ "$backup_checksum" == *"$original_checksum"* ]] && [ -n "$original_checksum" ]; then
                    log_result "PASS" "Backup content verified: $(basename "$backup")"
                else
                    log_result "WARN" "Backup content differs: $(basename "$backup")" "May be expected"
                fi
            fi
        else
            log_result "INFO" "No backup for: $(basename "${backup%.backup}")" "File may not have existed"
        fi
    done
    
    # Check for backup directories
    local backup_dirs=($(ls -d "$HOME"/.dotfiles-backup-* 2>/dev/null || true))
    if [ ${#backup_dirs[@]} -gt 0 ]; then
        log_result "PASS" "Backup directories created" "${#backup_dirs[@]} directories"
        
        # Check latest backup directory content
        local latest_backup=$(ls -td "$HOME"/.dotfiles-backup-* | head -1)
        if [ -d "$latest_backup" ]; then
            local file_count=$(find "$latest_backup" -type f | wc -l)
            log_result "INFO" "Latest backup contains $file_count files" "$latest_backup"
        fi
    fi
    
    if [ $backup_count -eq 0 ] && [ ${#backup_dirs[@]} -eq 0 ]; then
        log_result "WARN" "No backups found" "Unexpected for existing configurations"
    fi
}

# Test configuration merging/preservation
test_config_preservation() {
    echo ""
    echo "========================================"
    echo "  Testing Configuration Preservation"
    echo "========================================"
    
    # Check if custom files are preserved
    if [ -f ~/.zsh_custom ]; then
        log_result "PASS" "Custom zsh file preserved"
        
        # Check if custom alias still works
        if grep -q "mycustomalias" ~/.zsh_custom; then
            log_result "PASS" "Custom alias preserved in ~/.zsh_custom"
        else
            log_result "WARN" "Custom alias missing from ~/.zsh_custom"
        fi
    else
        log_result "WARN" "Custom zsh file not preserved"
    fi
    
    # Test that new configuration is active
    if [ -L ~/.zshrc ]; then
        local target=$(readlink ~/.zshrc)
        if [[ "$target" == *"/.dotfiles/"* ]]; then
            log_result "PASS" "New zsh configuration is active"
        else
            log_result "FAIL" "zsh symlink points to wrong location" "$target"
        fi
    else
        log_result "FAIL" "zsh configuration is not a symlink to dotfiles"
    fi
    
    # Test git configuration
    if [ -L ~/.gitconfig ]; then
        local target=$(readlink ~/.gitconfig)
        if [[ "$target" == *"/.dotfiles/"* ]]; then
            log_result "PASS" "New git configuration is active"
        else
            log_result "FAIL" "git symlink points to wrong location" "$target"
        fi
    else
        log_result "FAIL" "git configuration is not a symlink to dotfiles"
    fi
    
    # Check if we can still access backed up configurations
    if [ -f ~/.gitconfig.backup ]; then
        local old_email=$(grep "email" ~/.gitconfig.backup | head -1 | awk '{print $3}')
        if [ "$old_email" = "test@example.com" ]; then
            log_result "PASS" "Original git configuration accessible in backup"
        else
            log_result "WARN" "Original git configuration may be corrupted"
        fi
    fi
}

# Test rollback with existing configurations
test_rollback_with_existing() {
    echo ""
    echo "========================================"
    echo "  Testing Rollback with Existing Configs"
    echo "========================================"
    
    # Test rollback script functionality
    if [ -f ~/.dotfiles/scripts/rollback.sh ]; then
        log_result "PASS" "Rollback script available"
        
        # Test rollback script can handle existing configurations
        echo "Testing rollback restore functionality..."
        
        # Simulate rollback (option 1 - restore from .backup files)
        if ~/.dotfiles/scripts/rollback.sh << 'EOF'
1
y
EOF
        then
            log_result "PASS" "Rollback script executed successfully"
            
            # Verify rollback restored original configurations
            if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
                if grep -q "myfunction" ~/.zshrc; then
                    log_result "PASS" "Original zsh configuration restored"
                else
                    log_result "WARN" "zsh configuration restored but content differs"
                fi
            else
                log_result "FAIL" "zsh configuration not properly restored"
            fi
            
            if [ -f ~/.gitconfig ] && [ ! -L ~/.gitconfig ]; then
                if grep -q "test@example.com" ~/.gitconfig; then
                    log_result "PASS" "Original git configuration restored"
                else
                    log_result "WARN" "git configuration restored but content differs"
                fi
            else
                log_result "FAIL" "git configuration not properly restored"
            fi
        else
            log_result "FAIL" "Rollback script failed"
        fi
    else
        log_result "FAIL" "Rollback script not available"
    fi
}

# Test re-installation after rollback
test_reinstallation() {
    echo ""
    echo "========================================"
    echo "  Testing Re-installation After Rollback"
    echo "========================================"
    
    echo "Testing re-installation over restored configurations..."
    
    # Re-run installation
    if curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash; then
        log_result "PASS" "Re-installation successful"
        
        # Verify configurations are properly linked again
        if [ -L ~/.zshrc ] && [ -L ~/.gitconfig ]; then
            log_result "PASS" "Configurations properly linked after re-installation"
        else
            log_result "FAIL" "Configurations not properly linked after re-installation"
        fi
        
        # Verify backups were created again
        if [ -f ~/.zshrc.backup ] && [ -f ~/.gitconfig.backup ]; then
            log_result "PASS" "New backups created during re-installation"
        else
            log_result "WARN" "Backups not created during re-installation"
        fi
    else
        log_result "FAIL" "Re-installation failed"
    fi
}

# Cleanup function
cleanup_test() {
    echo ""
    echo "========================================"
    echo "  Test Cleanup"
    echo "========================================"
    
    # Remove test configurations and dotfiles
    echo "Removing test configurations..."
    
    # Remove dotfiles symlinks
    find ~ -maxdepth 3 -type l 2>/dev/null | while read link; do
        if readlink "$link" 2>/dev/null | grep -q "/.dotfiles/"; then
            echo "  Removing: $link"
            rm "$link"
        fi
    done
    
    # Remove dotfiles directory
    if [ -d ~/.dotfiles ]; then
        rm -rf ~/.dotfiles
        echo "  Removed: ~/.dotfiles"
    fi
    
    # Remove backup files
    rm -f ~/.*.backup
    rm -rf ~/.dotfiles-backup-*
    
    # Remove test files
    rm -f ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.zsh_custom
    rm -rf ~/.config/nvim
    rm -f /tmp/pre-install-checksums.txt
    
    # Remove VS Code test settings
    local vscode_dir
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vscode_dir="$HOME/Library/Application Support/Code/User"
    else
        vscode_dir="$HOME/.config/Code/User"
    fi
    
    if [ -f "$vscode_dir/settings.json" ]; then
        rm -f "$vscode_dir/settings.json"
        echo "  Removed: VS Code test settings"
    fi
    
    log_result "INFO" "Test cleanup completed"
}

# Set up cleanup trap
trap cleanup_test EXIT

# Main test execution
main() {
    echo "This test will create existing configurations, install dotfiles over them,"
    echo "test backup functionality, and then clean up everything."
    echo ""
    
    # Confirm with user
    read -p "Continue with existing configuration test? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Test cancelled by user"
        exit 0
    fi
    
    # Run test sequence
    create_existing_configs
    test_backup_creation
    test_installation_over_existing
    test_backup_integrity
    test_config_preservation
    test_rollback_with_existing
    test_reinstallation
    
    # Generate final report
    echo ""
    echo "========================================"
    echo "  Existing Configuration Test Results"
    echo "========================================"
    
    if [ $TEST_FAILED -eq 0 ]; then
        if [ $WARNINGS_COUNT -eq 0 ]; then
            echo -e "${GREEN}✅ All tests PASSED${NC}"
            echo "Dotfiles installation handles existing configurations correctly"
        else
            echo -e "${YELLOW}⚠️  Tests PASSED with $WARNINGS_COUNT warnings${NC}"
            echo "Installation works but some edge cases may need attention"
        fi
    else
        echo -e "${RED}❌ Tests FAILED${NC}"
        echo "Issues found with existing configuration handling"
    fi
    
    echo ""
    echo "Test Summary:"
    echo "- Tested installation over existing configurations"
    echo "- Verified backup creation and integrity"
    echo "- Tested rollback functionality"
    echo "- Verified re-installation capability"
    echo "- Log File: $TEST_LOG"
    
    echo ""
    echo "Key findings:"
    echo "- Backup system: $([ -f ~/.zshrc.backup ] && echo "Working" || echo "Needs attention")"
    echo "- Configuration preservation: $([ -f ~/.zsh_custom ] && echo "Working" || echo "Needs attention")"
    echo "- Rollback functionality: $([ $TEST_FAILED -eq 0 ] && echo "Working" || echo "Needs attention")"
    
    exit $TEST_FAILED
}

# Run main function
main "$@"