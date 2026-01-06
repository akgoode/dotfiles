#!/bin/bash
# Manual rollback script for dotfiles installation
# Requirements: 1.4, 6.3

set -e

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_PATTERN="$HOME/.dotfiles-backup-*"

echo "================================================"
echo "  Dotfiles Installation Rollback"
echo "================================================"

# Find the most recent backup directory
LATEST_BACKUP=""
if ls $BACKUP_PATTERN 1> /dev/null 2>&1; then
    LATEST_BACKUP=$(ls -td $BACKUP_PATTERN | head -n1)
    echo "Found backup directory: $LATEST_BACKUP"
else
    echo "No backup directories found matching pattern: $BACKUP_PATTERN"
fi

# Function to restore from .backup files
restore_backup_files() {
    echo ""
    echo "Restoring from .backup files..."
    
    local restored_count=0
    
    # Common backup locations
    local backup_files=(
        "$HOME/.zshrc.backup"
        "$HOME/.gitconfig.backup"
        "$HOME/.config/nvim.backup"
        "$HOME/.tmux.conf.backup"
        "$HOME/.claude/settings.json.backup"
        "$HOME/.kiro/settings/mcp.json.backup"
    )
    
    # Add VS Code backup (platform-specific)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        backup_files+=("$HOME/Library/Application Support/Code/User/settings.json.backup")
    else
        backup_files+=("$HOME/.config/Code/User/settings.json.backup")
    fi
    
    for backup_file in "${backup_files[@]}"; do
        if [ -f "$backup_file" ]; then
            original_file="${backup_file%.backup}"
            echo "  Restoring $original_file from backup"
            
            # Remove current symlink/file
            if [ -L "$original_file" ] || [ -f "$original_file" ]; then
                rm "$original_file"
            fi
            
            # Restore from backup
            mv "$backup_file" "$original_file"
            restored_count=$((restored_count + 1))
        fi
    done
    
    echo "  Restored $restored_count files from .backup files"
}

# Function to restore from backup directory
restore_from_backup_dir() {
    local backup_dir="$1"
    
    echo ""
    echo "Restoring from backup directory: $backup_dir"
    
    if [ ! -d "$backup_dir" ]; then
        echo "  Backup directory not found: $backup_dir"
        return 1
    fi
    
    local restored_count=0
    
    # Restore files from backup directory
    for backup_file in "$backup_dir"/*; do
        if [ -f "$backup_file" ]; then
            # Convert backup filename back to original path
            local filename="$(basename "$backup_file")"
            local original_path="${filename//___/\/}"  # Convert ___ back to /
            local full_original_path="$HOME/$original_path"
            
            echo "  Restoring $full_original_path"
            
            # Create directory if needed
            local dir_path="$(dirname "$full_original_path")"
            mkdir -p "$dir_path"
            
            # Remove current file/symlink
            if [ -e "$full_original_path" ]; then
                rm -rf "$full_original_path"
            fi
            
            # Restore from backup
            cp -r "$backup_file" "$full_original_path"
            restored_count=$((restored_count + 1))
        fi
    done
    
    echo "  Restored $restored_count files from backup directory"
}

# Function to remove dotfiles symlinks
remove_dotfiles_symlinks() {
    echo ""
    echo "Removing dotfiles symlinks..."
    
    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.config/nvim"
        "$HOME/.tmux.conf"
        "$HOME/.config/dotfiles/shell/aliases.zsh"
        "$HOME/.claude/settings.json"
        "$HOME/.kiro/settings/mcp.json"
    )
    
    # Add VS Code symlink (platform-specific)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        symlinks+=("$HOME/Library/Application Support/Code/User/settings.json")
    else
        symlinks+=("$HOME/.config/Code/User/settings.json")
    fi
    
    local removed_count=0
    
    for symlink in "${symlinks[@]}"; do
        if [ -L "$symlink" ] && [[ "$(readlink "$symlink")" == *"/.dotfiles/"* ]]; then
            echo "  Removing dotfiles symlink: $symlink"
            rm "$symlink"
            removed_count=$((removed_count + 1))
        elif [ -L "$symlink" ]; then
            echo "  Skipping non-dotfiles symlink: $symlink -> $(readlink "$symlink")"
        fi
    done
    
    echo "  Removed $removed_count dotfiles symlinks"
}

# Function to reset shell
reset_shell() {
    echo ""
    echo "Resetting shell configuration..."
    
    # Check if zsh was set by dotfiles installation
    if [ "$SHELL" = "$(which zsh)" ]; then
        echo "  Current shell is zsh, consider changing back to bash:"
        echo "  Run: chsh -s /bin/bash"
    else
        echo "  Shell is already set to: $SHELL"
    fi
}

# Main rollback menu
show_menu() {
    echo ""
    echo "Rollback options:"
    echo "1. Restore from .backup files (recommended)"
    echo "2. Restore from backup directory"
    echo "3. Remove dotfiles symlinks only"
    echo "4. Full rollback (restore + remove symlinks)"
    echo "5. Reset shell configuration"
    echo "6. Show backup information"
    echo "7. Exit"
    echo ""
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1)
            restore_backup_files
            echo ""
            echo "✓ Restored from .backup files"
            ;;
        2)
            if [ -n "$LATEST_BACKUP" ]; then
                restore_from_backup_dir "$LATEST_BACKUP"
                echo ""
                echo "✓ Restored from backup directory"
            else
                echo "No backup directory available"
            fi
            ;;
        3)
            remove_dotfiles_symlinks
            echo ""
            echo "✓ Removed dotfiles symlinks"
            ;;
        4)
            restore_backup_files
            if [ -n "$LATEST_BACKUP" ]; then
                restore_from_backup_dir "$LATEST_BACKUP"
            fi
            remove_dotfiles_symlinks
            echo ""
            echo "✓ Full rollback completed"
            ;;
        5)
            reset_shell
            ;;
        6)
            echo ""
            echo "Backup information:"
            echo "  Latest backup directory: ${LATEST_BACKUP:-"None found"}"
            echo "  Available .backup files:"
            find "$HOME" -maxdepth 3 -name "*.backup" 2>/dev/null | head -10 | sed 's/^/    /' || echo "    None found"
            ;;
        7)
            echo "Exiting rollback script"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-7."
            ;;
    esac
}

# Main loop
while true; do
    show_menu
    echo ""
    read -p "Perform another rollback operation? (y/N): " continue_choice
    if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
        break
    fi
done

echo ""
echo "================================================"
echo "  Rollback operations completed"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Restart your terminal to apply changes"
echo "2. Verify your configuration is working correctly"
echo "3. Remove backup files when no longer needed"
echo ""