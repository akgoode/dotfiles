# Rollback Procedures Guide

This guide provides comprehensive procedures for safely rolling back dotfiles installations in various scenarios.

## Table of Contents

- [Rollback Overview](#rollback-overview)
- [Automatic Rollback](#automatic-rollback)
- [Manual Rollback Procedures](#manual-rollback-procedures)
- [Emergency Rollback](#emergency-rollback)
- [Remote System Rollback](#remote-system-rollback)
- [Rollback Validation](#rollback-validation)
- [Prevention and Best Practices](#prevention-and-best-practices)

## Rollback Overview

### When to Rollback

**Immediate rollback scenarios:**

- Installation fails with critical errors
- System becomes unstable or unusable
- Shell configuration prevents login
- Critical applications stop working
- Performance degradation occurs

**Planned rollback scenarios:**

- Testing period completed
- User preference changes
- System requirements change
- Migration to different configuration

### Rollback Methods

1. **Automatic Rollback**: Using built-in rollback script
2. **Manual Rollback**: Step-by-step manual restoration
3. **Emergency Rollback**: For system recovery situations
4. **Selective Rollback**: Rolling back specific components only

## Automatic Rollback

### Using the Built-in Rollback Script

The dotfiles system includes an interactive rollback script:

```bash
cd ~/.dotfiles
./scripts/rollback.sh
```

**Rollback script options:**

1. **Restore from .backup files** (recommended first step)
2. **Restore from backup directory** (comprehensive restoration)
3. **Remove dotfiles symlinks only** (minimal rollback)
4. **Full rollback** (complete restoration and cleanup)
5. **Reset shell configuration** (shell-specific rollback)
6. **Show backup information** (diagnostic information)

### Automatic Rollback Process

**Step 1: Assess the situation**

```bash
# Check what backups are available
ls -la ~/.*.backup
ls -ld ~/.dotfiles-backup-*

# Check current symlink status
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim
```

**Step 2: Run automatic rollback**

```bash
cd ~/.dotfiles
./scripts/rollback.sh

# Follow the interactive prompts:
# - Choose option 1 for .backup file restoration
# - Choose option 4 for complete rollback if needed
```

**Step 3: Verify rollback success**

```bash
# Test shell functionality
bash -c "echo 'Shell works'"

# Check restored configurations
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim

# Test basic operations
git --version
```

## Manual Rollback Procedures

### Quick Manual Rollback

**For immediate restoration of key configurations:**

```bash
#!/bin/bash
# Quick rollback script

echo "Starting quick rollback..."

# Restore shell configuration
if [ -f ~/.zshrc.backup ]; then
    echo "Restoring ~/.zshrc"
    mv ~/.zshrc.backup ~/.zshrc
elif [ -L ~/.zshrc ]; then
    echo "Removing dotfiles zsh symlink"
    rm ~/.zshrc
    # Create basic zsh config
    echo 'export PATH="/usr/local/bin:$PATH"' > ~/.zshrc
fi

# Restore git configuration
if [ -f ~/.gitconfig.backup ]; then
    echo "Restoring ~/.gitconfig"
    mv ~/.gitconfig.backup ~/.gitconfig
elif [ -L ~/.gitconfig ]; then
    echo "Removing dotfiles git symlink"
    rm ~/.gitconfig
fi

# Restore Neovim configuration
if [ -d ~/.config/nvim.backup ]; then
    echo "Restoring ~/.config/nvim"
    rm -rf ~/.config/nvim
    mv ~/.config/nvim.backup ~/.config/nvim
elif [ -L ~/.config/nvim ]; then
    echo "Removing dotfiles nvim symlink"
    rm ~/.config/nvim
fi

# Reset shell to bash if needed
if [ "$SHELL" = "$(which zsh)" ]; then
    echo "Resetting shell to bash"
    chsh -s /bin/bash
fi

echo "Quick rollback completed"
```

### Comprehensive Manual Rollback

**For complete system restoration:**

```bash
#!/bin/bash
# Comprehensive rollback script

set -e

BACKUP_DIR=""
DOTFILES_DIR="$HOME/.dotfiles"

echo "========================================"
echo "  Comprehensive Dotfiles Rollback"
echo "========================================"

# Find the most recent backup directory
if ls ~/.dotfiles-backup-* 1> /dev/null 2>&1; then
    BACKUP_DIR=$(ls -td ~/.dotfiles-backup-* | head -n1)
    echo "Found backup directory: $BACKUP_DIR"
fi

# Step 1: Remove all dotfiles symlinks
echo ""
echo "Step 1: Removing dotfiles symlinks..."
find ~ -maxdepth 3 -type l 2>/dev/null | while read link; do
    if readlink "$link" 2>/dev/null | grep -q "/.dotfiles/"; then
        echo "  Removing: $link"
        rm "$link"
    fi
done

# Step 2: Restore from .backup files
echo ""
echo "Step 2: Restoring from .backup files..."
for backup in ~/.*.backup ~/.config/*.backup; do
    if [ -f "$backup" ]; then
        original="${backup%.backup}"
        echo "  Restoring: $original"
        mv "$backup" "$original"
    fi
done

# Step 3: Restore from backup directory
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo ""
    echo "Step 3: Restoring from backup directory..."
    for backup_file in "$BACKUP_DIR"/*; do
        if [ -f "$backup_file" ]; then
            filename="$(basename "$backup_file")"
            # Handle special path encoding
            if [[ "$filename" == *"___"* ]]; then
                # Convert ___ back to /
                original_path="${filename//___/\/}"
                full_path="$HOME/$original_path"
            else
                full_path="$HOME/$filename"
            fi

            echo "  Restoring: $full_path"
            mkdir -p "$(dirname "$full_path")"
            cp "$backup_file" "$full_path"
        fi
    done
fi

# Step 4: Reset shell configuration
echo ""
echo "Step 4: Resetting shell configuration..."
if [ "$SHELL" = "$(which zsh)" ]; then
    echo "  Changing shell back to bash"
    chsh -s /bin/bash
fi

# Create basic shell configuration if none exists
if [ ! -f ~/.bashrc ]; then
    echo "  Creating basic .bashrc"
    cp /etc/skel/.bashrc ~/.bashrc 2>/dev/null || \
    echo 'export PATH="/usr/local/bin:$PATH"' > ~/.bashrc
fi

# Step 5: Clean up dotfiles directory (optional)
echo ""
read -p "Remove dotfiles directory (~/.dotfiles)? (y/N): " remove_dotfiles
if [[ "$remove_dotfiles" =~ ^[Yy]$ ]]; then
    echo "  Removing ~/.dotfiles"
    rm -rf "$DOTFILES_DIR"
fi

echo ""
echo "========================================"
echo "  Rollback Completed Successfully"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Restart your terminal: exec bash"
echo "2. Verify configurations work correctly"
echo "3. Remove backup files when no longer needed"
```

### Selective Component Rollback

**Roll back specific components only:**

#### Shell Configuration Only

```bash
# Rollback shell configuration
if [ -f ~/.zshrc.backup ]; then
    mv ~/.zshrc.backup ~/.zshrc
else
    rm -f ~/.zshrc
    cp /etc/skel/.bashrc ~/.bashrc 2>/dev/null || \
    echo 'export PATH="/usr/local/bin:$PATH"' > ~/.bashrc
fi

# Reset shell
chsh -s /bin/bash
exec bash
```

#### Git Configuration Only

```bash
# Rollback git configuration
if [ -f ~/.gitconfig.backup ]; then
    mv ~/.gitconfig.backup ~/.gitconfig
else
    rm -f ~/.gitconfig
    # Optionally create minimal git config
    git config --global user.name "Your Name"
    git config --global user.email "your.email@example.com"
fi
```

#### Editor Configuration Only

```bash
# Rollback Neovim
if [ -d ~/.config/nvim.backup ]; then
    rm -rf ~/.config/nvim
    mv ~/.config/nvim.backup ~/.config/nvim
else
    rm -rf ~/.config/nvim
fi

# Rollback VS Code settings
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
else
    VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
fi

if [ -f "$VSCODE_SETTINGS.backup" ]; then
    mv "$VSCODE_SETTINGS.backup" "$VSCODE_SETTINGS"
else
    rm -f "$VSCODE_SETTINGS"
fi
```

## Emergency Rollback

### System Recovery Mode Rollback

**When system won't boot or shell is completely broken:**

#### Boot from Recovery/Live USB

```bash
# Mount the affected filesystem
sudo mount /dev/sda1 /mnt  # Adjust device as needed

# Navigate to user's home directory
cd /mnt/home/username

# Remove problematic dotfiles symlinks
find . -maxdepth 3 -type l -exec sh -c '
    for link; do
        if readlink "$link" | grep -q "/.dotfiles/"; then
            echo "Removing: $link"
            rm "$link"
        fi
    done
' sh {} +

# Restore from backup if available
BACKUP_DIR=$(ls -td .dotfiles-backup-* 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Restoring from: $BACKUP_DIR"
    cp -r "$BACKUP_DIR"/* . 2>/dev/null || true
fi

# Create basic shell configuration
echo 'export PATH="/usr/local/bin:/usr/bin:/bin"' > .bashrc
echo 'PS1="\u@\h:\w\$ "' >> .bashrc

# Fix ownership
chown -R username:username .

# Unmount and reboot
cd /
sudo umount /mnt
sudo reboot
```

#### Single User Mode Rollback

```bash
# Boot into single user mode
# At boot, add 'single' to kernel parameters

# Remount root as read-write
mount -o remount,rw /

# Navigate to user directory
cd /home/username

# Perform emergency rollback
rm -f .zshrc .gitconfig
rm -rf .config/nvim
rm -rf .dotfiles

# Restore basic configuration
cp /etc/skel/.bashrc .bashrc
chown username:username .bashrc

# Reboot normally
reboot
```

### Remote Emergency Rollback

**When SSH access is limited but still available:**

```bash
# Connect with bash explicitly
ssh -t user@remote-host bash

# Or force bash shell
ssh user@remote-host 'bash -c "
    # Remove problematic zsh config
    rm -f ~/.zshrc

    # Create basic bash config
    echo \"export PATH=\\\"/usr/local/bin:\$PATH\\\"\" > ~/.bashrc

    # Change shell to bash
    chsh -s /bin/bash

    echo \"Emergency rollback completed\"
"'

# Test connection with bash
ssh user@remote-host
```

## Remote System Rollback

### Standard Remote Rollback

**For remote systems with SSH access:**

```bash
# Method 1: Use the built-in rollback script
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/rollback.sh'

# Method 2: Execute manual rollback commands
ssh user@remote-host 'bash -s' << 'EOF'
    # Quick rollback
    [ -f ~/.zshrc.backup ] && mv ~/.zshrc.backup ~/.zshrc
    [ -f ~/.gitconfig.backup ] && mv ~/.gitconfig.backup ~/.gitconfig
    [ -d ~/.config/nvim.backup ] && rm -rf ~/.config/nvim && mv ~/.config/nvim.backup ~/.config/nvim

    # Reset shell
    chsh -s /bin/bash

    echo "Remote rollback completed"
EOF

# Method 3: Interactive remote rollback
ssh -t user@remote-host 'cd ~/.dotfiles && ./scripts/rollback.sh'
```

### Batch Remote Rollback

**For multiple remote systems:**

```bash
#!/bin/bash
# batch-rollback.sh

HOSTS=(
    "user1@server1.example.com"
    "user2@server2.example.com"
    "user3@server3.example.com"
)

ROLLBACK_SCRIPT='
    cd ~/.dotfiles 2>/dev/null || { echo "No dotfiles directory found"; exit 0; }
    ./scripts/rollback.sh << EOF
1
y
EOF
    echo "Rollback completed on $(hostname)"
'

echo "Starting batch rollback on ${#HOSTS[@]} systems..."

for host in "${HOSTS[@]}"; do
    echo "========================================"
    echo "Rolling back: $host"
    echo "========================================"

    if ssh "$host" "$ROLLBACK_SCRIPT"; then
        echo "✓ $host rollback successful"
    else
        echo "✗ $host rollback failed"
        echo "$host" >> failed-rollbacks.log
    fi

    echo ""
done

echo "Batch rollback completed"
if [ -f failed-rollbacks.log ]; then
    echo "Failed rollbacks logged in: failed-rollbacks.log"
fi
```

## Rollback Validation

### Post-Rollback Verification

**Automated validation script:**

```bash
#!/bin/bash
# validate-rollback.sh

echo "========================================"
echo "  Rollback Validation"
echo "========================================"

VALIDATION_FAILED=0

# Test 1: Shell functionality
echo "Testing shell functionality..."
if bash -c "echo 'Shell test successful'" >/dev/null 2>&1; then
    echo "✓ Shell works correctly"
else
    echo "✗ Shell has issues"
    VALIDATION_FAILED=1
fi

# Test 2: Configuration files
echo ""
echo "Checking configuration files..."
for config in ~/.bashrc ~/.zshrc ~/.gitconfig; do
    if [ -f "$config" ] && [ ! -L "$config" ]; then
        echo "✓ $config exists and is not a symlink"
    elif [ -L "$config" ]; then
        echo "⚠ $config is still a symlink: $(readlink "$config")"
    else
        echo "ℹ $config does not exist"
    fi
done

# Test 3: No broken symlinks
echo ""
echo "Checking for broken symlinks..."
broken_links=$(find ~ -maxdepth 3 -type l -exec test ! -e {} \; -print 2>/dev/null)
if [ -z "$broken_links" ]; then
    echo "✓ No broken symlinks found"
else
    echo "⚠ Broken symlinks found:"
    echo "$broken_links" | sed 's/^/  /'
fi

# Test 4: Dotfiles symlinks removed
echo ""
echo "Checking for remaining dotfiles symlinks..."
dotfiles_links=$(find ~ -maxdepth 3 -type l -exec readlink {} \; 2>/dev/null | grep "/.dotfiles/" | wc -l)
if [ "$dotfiles_links" -eq 0 ]; then
    echo "✓ No dotfiles symlinks remain"
else
    echo "⚠ $dotfiles_links dotfiles symlinks still exist"
fi

# Test 5: Basic git functionality
echo ""
echo "Testing git functionality..."
if command -v git >/dev/null && git --version >/dev/null 2>&1; then
    echo "✓ Git is functional"
else
    echo "⚠ Git may have issues"
fi

# Test 6: Shell change
echo ""
echo "Checking shell configuration..."
echo "Current shell: $SHELL"
if [[ "$SHELL" == */bash ]]; then
    echo "✓ Shell is set to bash"
elif [[ "$SHELL" == */zsh ]] && [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
    echo "✓ Shell is zsh with local configuration"
else
    echo "ℹ Shell configuration may need attention"
fi

# Summary
echo ""
echo "========================================"
if [ $VALIDATION_FAILED -eq 0 ]; then
    echo "✅ Rollback validation PASSED"
    echo "System has been successfully restored"
else
    echo "❌ Rollback validation FAILED"
    echo "Some issues remain - manual intervention may be needed"
fi
echo "========================================"

exit $VALIDATION_FAILED
```

### Manual Validation Steps

**Step-by-step verification:**

1. **Test shell access:**

   ```bash
   # Open new terminal session
   # Verify prompt appears correctly
   # Test basic commands
   ls
   pwd
   echo $PATH
   ```

2. **Test configuration loading:**

   ```bash
   # Source shell configuration
   source ~/.bashrc  # or ~/.zshrc if using zsh

   # Test aliases (if any were restored)
   alias

   # Test git configuration
   git config --list
   ```

3. **Test application functionality:**

   ```bash
   # Test editors
   vim --version  # or nvim --version

   # Test development tools
   git --version
   curl --version

   # Test any custom tools that were installed
   ```

4. **Verify file integrity:**

   ```bash
   # Check that restored files are not symlinks
   ls -la ~/.bashrc ~/.gitconfig ~/.config/nvim

   # Verify file contents make sense
   head -10 ~/.bashrc
   head -10 ~/.gitconfig
   ```

## Prevention and Best Practices

### Pre-Installation Backup Strategy

**Always create comprehensive backups before installation:**

```bash
#!/bin/bash
# comprehensive-backup.sh

BACKUP_DIR="$HOME/.pre-dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating comprehensive backup in: $BACKUP_DIR"

# Backup configuration files
configs=(
    ".bashrc"
    ".zshrc"
    ".gitconfig"
    ".tmux.conf"
    ".vimrc"
    ".config/nvim"
    ".config/Code/User/settings.json"
    "Library/Application Support/Code/User/settings.json"  # macOS
    ".kiro/settings/mcp.json"
    ".claude/settings.json"
)

for config in "${configs[@]}"; do
    if [ -e "$HOME/$config" ]; then
        echo "Backing up: $config"
        # Create directory structure in backup
        mkdir -p "$BACKUP_DIR/$(dirname "$config")"
        cp -r "$HOME/$config" "$BACKUP_DIR/$config"
    fi
done

# Create system state snapshot
echo "Creating system state snapshot..."
echo "Date: $(date)" > "$BACKUP_DIR/system-state.txt"
echo "User: $(whoami)" >> "$BACKUP_DIR/system-state.txt"
echo "Shell: $SHELL" >> "$BACKUP_DIR/system-state.txt"
echo "PATH: $PATH" >> "$BACKUP_DIR/system-state.txt"
echo "" >> "$BACKUP_DIR/system-state.txt"

# List installed packages
if command -v brew >/dev/null; then
    echo "Homebrew packages:" >> "$BACKUP_DIR/system-state.txt"
    brew list >> "$BACKUP_DIR/system-state.txt"
elif command -v apt >/dev/null; then
    echo "APT packages:" >> "$BACKUP_DIR/system-state.txt"
    dpkg -l >> "$BACKUP_DIR/system-state.txt"
fi

echo "Backup completed: $BACKUP_DIR"
echo "Restore command: cp -r $BACKUP_DIR/* ~/"
```

### Testing Strategy

**Always test rollback procedures:**

1. **Test in virtual machine or container first**
2. **Document rollback steps for your specific environment**
3. **Practice rollback procedures regularly**
4. **Verify rollback works with your backup strategy**

### Monitoring and Alerts

**Set up monitoring for critical configuration changes:**

```bash
# Create a configuration monitoring script
#!/bin/bash
# config-monitor.sh

CONFIGS=(~/.zshrc ~/.gitconfig ~/.config/nvim)
CHECKSUMS_FILE="$HOME/.config-checksums"

# Generate checksums for current configurations
generate_checksums() {
    for config in "${CONFIGS[@]}"; do
        if [ -e "$config" ]; then
            if [ -L "$config" ]; then
                echo "$config:SYMLINK:$(readlink "$config")" >> "$CHECKSUMS_FILE.new"
            else
                echo "$config:FILE:$(md5sum "$config" 2>/dev/null || md5 "$config")" >> "$CHECKSUMS_FILE.new"
            fi
        fi
    done
}

# Check for changes
check_changes() {
    if [ -f "$CHECKSUMS_FILE" ]; then
        if ! diff "$CHECKSUMS_FILE" "$CHECKSUMS_FILE.new" >/dev/null 2>&1; then
            echo "Configuration changes detected!"
            diff "$CHECKSUMS_FILE" "$CHECKSUMS_FILE.new"
            return 1
        fi
    fi
    return 0
}

generate_checksums
if ! check_changes; then
    echo "Consider creating a backup before proceeding"
fi
mv "$CHECKSUMS_FILE.new" "$CHECKSUMS_FILE"
```

---

**Remember**: The key to successful rollback is preparation. Always create comprehensive backups before installation and test your rollback procedures in a safe environment first.
