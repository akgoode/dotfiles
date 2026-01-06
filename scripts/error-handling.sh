#!/bin/bash
# Error handling and recovery functions for dotfiles installation
# Requirements: 1.4, 6.3

# Global variables for tracking installation state
INSTALLATION_LOG="/tmp/dotfiles-install.log"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
ROLLBACK_COMMANDS=()

# Initialize logging
init_logging() {
    echo "Dotfiles installation started at $(date)" > "$INSTALLATION_LOG"
    echo "Backup directory: $BACKUP_DIR" >> "$INSTALLATION_LOG"
    mkdir -p "$BACKUP_DIR"
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    echo "[$level $(date '+%H:%M:%S')] $message" | tee -a "$INSTALLATION_LOG"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command="$2"
    
    log_message "ERROR" "Command failed with exit code $exit_code at line $line_number: $command"
    
    echo ""
    echo "================================================"
    echo "  INSTALLATION FAILED"
    echo "================================================"
    echo "Error: Command failed with exit code $exit_code"
    echo "Line: $line_number"
    echo "Command: $command"
    echo ""
    echo "Installation log: $INSTALLATION_LOG"
    echo "Backup directory: $BACKUP_DIR"
    echo ""
    echo "Recovery options:"
    echo "1. Check the installation log for details"
    echo "2. Run 'rollback_installation' to undo changes"
    echo "3. Fix the issue and re-run the installation"
    echo ""
    
    # Offer automatic rollback
    if [ ${#ROLLBACK_COMMANDS[@]} -gt 0 ]; then
        echo "Would you like to automatically rollback changes? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rollback_installation
        fi
    fi
    
    exit $exit_code
}

# Set up error trap
setup_error_handling() {
    set -eE  # Exit on error and inherit ERR trap
    trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
}

# Add a rollback command to the stack
add_rollback_command() {
    local command="$1"
    ROLLBACK_COMMANDS+=("$command")
    log_message "INFO" "Added rollback command: $command"
}

# Execute rollback commands in reverse order
rollback_installation() {
    log_message "INFO" "Starting rollback process..."
    
    echo ""
    echo "================================================"
    echo "  ROLLING BACK INSTALLATION"
    echo "================================================"
    
    # Execute rollback commands in reverse order
    for ((i=${#ROLLBACK_COMMANDS[@]}-1; i>=0; i--)); do
        local cmd="${ROLLBACK_COMMANDS[i]}"
        echo "Executing rollback: $cmd"
        
        if eval "$cmd"; then
            log_message "INFO" "Rollback command succeeded: $cmd"
        else
            log_message "WARN" "Rollback command failed: $cmd"
        fi
    done
    
    # Restore from backup directory if it exists
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        echo "Restoring files from backup..."
        for backup_file in "$BACKUP_DIR"/*; do
            if [ -f "$backup_file" ]; then
                original_path="${backup_file#$BACKUP_DIR/}"
                original_path="${original_path//___/\/}"  # Convert ___ back to /
                
                if [ -e "$HOME/$original_path" ]; then
                    echo "Restoring $HOME/$original_path"
                    cp "$backup_file" "$HOME/$original_path"
                    log_message "INFO" "Restored $HOME/$original_path from backup"
                fi
            fi
        done
    fi
    
    echo ""
    echo "Rollback complete. Check $INSTALLATION_LOG for details."
    log_message "INFO" "Rollback process completed"
}

# Safe command execution with retry capability
safe_execute() {
    local command="$1"
    local description="$2"
    local max_retries="${3:-1}"
    local retry_delay="${4:-5}"
    
    log_message "INFO" "Executing: $description"
    
    for ((attempt=1; attempt<=max_retries; attempt++)); do
        if [ $attempt -gt 1 ]; then
            log_message "INFO" "Retry attempt $attempt/$max_retries for: $description"
            sleep $retry_delay
        fi
        
        if eval "$command"; then
            log_message "INFO" "Success: $description"
            return 0
        else
            local exit_code=$?
            log_message "WARN" "Attempt $attempt failed for: $description (exit code: $exit_code)"
            
            if [ $attempt -eq $max_retries ]; then
                log_message "ERROR" "All attempts failed for: $description"
                return $exit_code
            fi
        fi
    done
}

# Check prerequisites before installation
check_prerequisites() {
    log_message "INFO" "Checking prerequisites..."
    
    # Check internet connectivity
    if ! safe_execute "curl -s --connect-timeout 10 https://github.com >/dev/null" "Internet connectivity check" 3 5; then
        echo "Error: No internet connection. Please check your network and try again."
        exit 1
    fi
    
    # Check available disk space (require at least 1GB)
    local available_space
    if command -v df >/dev/null; then
        available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
        if [ "$available_space" -lt 1048576 ]; then  # 1GB in KB
            echo "Warning: Low disk space. Installation may fail."
            log_message "WARN" "Low disk space detected: ${available_space}KB available"
        fi
    fi
    
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        echo "Warning: Running as root is not recommended."
        echo "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        log_message "WARN" "Installation running as root user"
    fi
    
    log_message "INFO" "Prerequisites check completed"
}

# Backup existing file with safe path handling
safe_backup() {
    local file_path="$1"
    
    if [ -e "$file_path" ]; then
        # Create safe filename for backup (replace / with ___)
        local backup_name="$(basename "$file_path")"
        local backup_path="$BACKUP_DIR/$backup_name"
        
        if cp -r "$file_path" "$backup_path" 2>/dev/null; then
            log_message "INFO" "Backed up $file_path to $backup_path"
            add_rollback_command "cp -r '$backup_path' '$file_path'"
            return 0
        else
            log_message "ERROR" "Failed to backup $file_path"
            return 1
        fi
    fi
    
    return 0
}

# Verify installation success
verify_installation() {
    log_message "INFO" "Verifying installation..."
    
    local verification_failed=0
    
    # Check that essential symlinks exist
    local essential_links=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.config/nvim"
    )
    
    for link in "${essential_links[@]}"; do
        if [ -L "$link" ] && [ -e "$link" ]; then
            log_message "INFO" "Verified symlink: $link"
        else
            log_message "ERROR" "Missing or broken symlink: $link"
            verification_failed=1
        fi
    done
    
    # Check that shell configuration loads without errors
    if zsh -c "source ~/.zshrc" 2>/dev/null; then
        log_message "INFO" "Shell configuration loads successfully"
    else
        log_message "ERROR" "Shell configuration has errors"
        verification_failed=1
    fi
    
    if [ $verification_failed -eq 1 ]; then
        echo "Installation verification failed. Check $INSTALLATION_LOG for details."
        return 1
    fi
    
    log_message "INFO" "Installation verification completed successfully"
    return 0
}

# Cleanup function
cleanup_installation() {
    log_message "INFO" "Cleaning up temporary files..."
    
    # Remove temporary downloads
    rm -f /tmp/go*.tar.gz /tmp/awscliv2.zip /tmp/kubectl 2>/dev/null || true
    
    # Clean up old backup directories (keep only last 5)
    if [ -d "$HOME" ]; then
        find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*" -type d | sort | head -n -5 | xargs rm -rf 2>/dev/null || true
    fi
    
    log_message "INFO" "Cleanup completed"
}

# Print installation summary
print_summary() {
    local success="$1"
    
    echo ""
    echo "================================================"
    if [ "$success" = "true" ]; then
        echo "  INSTALLATION COMPLETED SUCCESSFULLY"
    else
        echo "  INSTALLATION FAILED"
    fi
    echo "================================================"
    echo "Installation log: $INSTALLATION_LOG"
    echo "Backup directory: $BACKUP_DIR"
    
    if [ "$success" = "true" ]; then
        echo ""
        echo "Next steps:"
        echo "1. Restart your terminal or run: source ~/.zshrc"
        echo "2. Verify everything works as expected"
        echo "3. Remove backup directory if no longer needed: rm -rf $BACKUP_DIR"
    else
        echo ""
        echo "Troubleshooting:"
        echo "1. Check the installation log for error details"
        echo "2. Run 'rollback_installation' to undo changes"
        echo "3. Fix any issues and re-run the installation"
    fi
    
    echo ""
}

# Export functions for use in other scripts
export -f log_message handle_error setup_error_handling add_rollback_command
export -f rollback_installation safe_execute check_prerequisites safe_backup
export -f verify_installation cleanup_installation print_summary