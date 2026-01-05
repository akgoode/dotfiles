# Production Deployment Guide

This guide covers deploying the dotfiles system to production environments, including remote systems accessed via SSH.

## Table of Contents

- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Remote Deployment Process](#remote-deployment-process)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Post-Deployment Validation](#post-deployment-validation)
- [Emergency Recovery](#emergency-recovery)

## Pre-Deployment Checklist

### System Requirements

Before deploying to any production system, verify these requirements:

#### macOS Systems

- [ ] macOS 10.15 (Catalina) or later
- [ ] At least 2GB free disk space
- [ ] Internet connectivity for package downloads
- [ ] Admin privileges (for Homebrew installation)
- [ ] Xcode Command Line Tools installed: `xcode-select --install`

#### Linux Systems (Ubuntu/Debian)

- [ ] Ubuntu 20.04+ or Debian 11+
- [ ] At least 2GB free disk space
- [ ] Internet connectivity for package downloads
- [ ] sudo privileges
- [ ] curl and git installed: `sudo apt update && sudo apt install -y curl git`

### Network and Security

- [ ] Verify internet access to required domains:

  - `github.com` (repository access)
  - `raw.githubusercontent.com` (installation script)
  - `brew.sh` (macOS - Homebrew)
  - `archive.ubuntu.com` (Linux - APT packages)
  - `releases.hashicorp.com` (Terraform)
  - `awscli.amazonaws.com` (AWS CLI)
  - `dl.k8s.io` (kubectl)
  - `go.dev` (Go language)

- [ ] SSH access configured (for remote deployments)
- [ ] Backup strategy in place for existing configurations
- [ ] Change management approval (if required by organization)

### Pre-Deployment Testing

Run these commands to verify system readiness:

```bash
# Check disk space (require at least 2GB)
df -h $HOME

# Check internet connectivity
curl -s --connect-timeout 10 https://github.com >/dev/null && echo "✓ Internet OK" || echo "✗ No internet"

# Check if running as root (not recommended)
[ "$EUID" -eq 0 ] && echo "⚠ Running as root" || echo "✓ Not root"

# macOS: Check Xcode Command Line Tools
xcode-select -p >/dev/null 2>&1 && echo "✓ Xcode tools OK" || echo "⚠ Install: xcode-select --install"

# Linux: Check sudo access
sudo -n true 2>/dev/null && echo "✓ Sudo OK" || echo "⚠ Sudo required"
```

## Remote Deployment Process

### SSH-Based Deployment

For deploying to remote systems via SSH:

#### 1. Prepare Remote System

```bash
# Connect to remote system
ssh user@remote-host

# Verify system requirements
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/scripts/check-requirements.sh | bash

# Create backup of existing configurations (optional but recommended)
mkdir -p ~/.dotfiles-manual-backup-$(date +%Y%m%d-%H%M%S)
cp ~/.zshrc ~/.dotfiles-manual-backup-* 2>/dev/null || true
cp ~/.gitconfig ~/.dotfiles-manual-backup-* 2>/dev/null || true
cp -r ~/.config/nvim ~/.dotfiles-manual-backup-* 2>/dev/null || true
```

#### 2. Execute Installation

```bash
# Method 1: One-line installation (recommended)
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash

# Method 2: Manual clone and install (for debugging)
git clone https://github.com/akgoode/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

#### 3. Monitor Installation

The installation process includes comprehensive logging. Monitor for:

- **Success indicators**: Green checkmarks (✓) and "SUCCESS" messages
- **Warning indicators**: Yellow warnings (⚠) - usually non-critical
- **Error indicators**: Red X marks (✗) and "ERROR" messages

Installation logs are saved to `/tmp/dotfiles-install.log` for review.

### Automated Remote Deployment

For deploying to multiple systems:

```bash
#!/bin/bash
# deploy-to-multiple.sh

HOSTS=(
    "user1@server1.example.com"
    "user2@server2.example.com"
    "user3@server3.example.com"
)

INSTALL_COMMAND='curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'

for host in "${HOSTS[@]}"; do
    echo "Deploying to $host..."

    if ssh "$host" "$INSTALL_COMMAND"; then
        echo "✓ $host deployment successful"
    else
        echo "✗ $host deployment failed"
        # Log failure for later review
        echo "$host" >> failed-deployments.log
    fi

    echo "---"
done

echo "Deployment complete. Check failed-deployments.log for any issues."
```

## Rollback Procedures

### Automatic Rollback

The installation system includes automatic rollback capabilities:

```bash
# If installation fails, the system offers automatic rollback
# Follow the prompts to restore previous configurations

# Manual rollback using the built-in script
cd ~/.dotfiles
./scripts/rollback.sh
```

### Manual Rollback Steps

If automatic rollback fails or is unavailable:

#### 1. Restore from .backup files

```bash
# Restore individual configuration files
[ -f ~/.zshrc.backup ] && mv ~/.zshrc.backup ~/.zshrc
[ -f ~/.gitconfig.backup ] && mv ~/.gitconfig.backup ~/.gitconfig
[ -f ~/.tmux.conf.backup ] && mv ~/.tmux.conf.backup ~/.tmux.conf

# Restore Neovim configuration
[ -d ~/.config/nvim.backup ] && rm -rf ~/.config/nvim && mv ~/.config/nvim.backup ~/.config/nvim

# Restore VS Code settings (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
    [ -f "$VSCODE_SETTINGS.backup" ] && mv "$VSCODE_SETTINGS.backup" "$VSCODE_SETTINGS"
else
    # Linux
    VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
    [ -f "$VSCODE_SETTINGS.backup" ] && mv "$VSCODE_SETTINGS.backup" "$VSCODE_SETTINGS"
fi

# Restore Kiro settings
[ -f ~/.kiro/settings/mcp.json.backup ] && mv ~/.kiro/settings/mcp.json.backup ~/.kiro/settings/mcp.json

# Restore Claude settings
[ -f ~/.claude/settings.json.backup ] && mv ~/.claude/settings.json.backup ~/.claude/settings.json
```

#### 2. Remove dotfiles symlinks

```bash
# Remove symlinks that point to ~/.dotfiles
find ~ -maxdepth 3 -type l -exec sh -c '
    for link; do
        if readlink "$link" | grep -q "/.dotfiles/"; then
            echo "Removing dotfiles symlink: $link"
            rm "$link"
        fi
    done
' sh {} +

# Specifically check common locations
for link in ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.tmux.conf; do
    if [ -L "$link" ] && readlink "$link" | grep -q "/.dotfiles/"; then
        rm "$link"
        echo "Removed: $link"
    fi
done
```

#### 3. Reset shell configuration

```bash
# If zsh was set as default shell, consider reverting
if [ "$SHELL" = "$(which zsh)" ]; then
    echo "Current shell is zsh. To revert to bash:"
    echo "  chsh -s /bin/bash"
fi

# Remove zsh from login shells (if added by installation)
# This requires admin privileges and should be done carefully
```

### Emergency Rollback Script

For critical situations, use this emergency rollback:

```bash
#!/bin/bash
# emergency-rollback.sh

echo "EMERGENCY ROLLBACK - Restoring system to pre-dotfiles state"

# Find and restore all .backup files
find ~ -maxdepth 3 -name "*.backup" -type f | while read backup; do
    original="${backup%.backup}"
    if [ -f "$backup" ]; then
        echo "Restoring: $original"
        cp "$backup" "$original"
    fi
done

# Remove all dotfiles symlinks
find ~ -maxdepth 3 -type l | while read link; do
    if readlink "$link" 2>/dev/null | grep -q "/.dotfiles/"; then
        echo "Removing dotfiles symlink: $link"
        rm "$link"
    fi
done

# Restore from backup directory if available
BACKUP_DIR=$(ls -td ~/.dotfiles-backup-* 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Restoring from backup directory: $BACKUP_DIR"
    cp -r "$BACKUP_DIR"/* ~ 2>/dev/null || true
fi

echo "Emergency rollback complete. Restart your terminal."
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Installation Fails with "Permission Denied"

**Symptoms**: Installation stops with permission errors
**Cause**: Insufficient privileges or running as root
**Solution**:

```bash
# If not root, ensure you have sudo access
sudo -v

# If running as root (not recommended), create a regular user:
useradd -m -s /bin/bash newuser
su - newuser
# Then run installation as the new user
```

#### Network Connectivity Issues

**Symptoms**: Downloads fail, "curl: (6) Could not resolve host"
**Cause**: Network connectivity or DNS issues
**Solution**:

```bash
# Test connectivity
ping -c 3 github.com
nslookup github.com

# Try alternative DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Use alternative installation method
git clone https://github.com/akgoode/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

#### Homebrew Installation Fails (macOS)

**Symptoms**: "Failed to install Homebrew" or Xcode tools missing
**Cause**: Missing Xcode Command Line Tools
**Solution**:

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Wait for installation to complete, then retry
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash
```

#### Package Installation Fails (Linux)

**Symptoms**: APT packages fail to install
**Cause**: Outdated package lists or repository issues
**Solution**:

```bash
# Update package lists
sudo apt update

# Fix broken packages
sudo apt --fix-broken install

# Retry installation
cd ~/.dotfiles
./scripts/install-linux.sh
```

#### Symlink Creation Fails

**Symptoms**: "File exists" errors during symlink creation
**Cause**: Existing files that couldn't be backed up
**Solution**:

```bash
# Manually backup and remove conflicting files
mv ~/.zshrc ~/.zshrc.manual-backup
mv ~/.gitconfig ~/.gitconfig.manual-backup

# Re-run common setup
cd ~/.dotfiles
./scripts/common.sh
```

#### Shell Configuration Doesn't Load

**Symptoms**: Aliases not available, prompt unchanged after installation
**Cause**: Shell not restarted or configuration errors
**Solution**:

```bash
# Restart shell
exec zsh

# Or source configuration manually
source ~/.zshrc

# Check for syntax errors
zsh -n ~/.zshrc
```

### Remote Deployment Specific Issues

#### SSH Connection Issues

**Symptoms**: Cannot connect to remote host
**Solution**:

```bash
# Test SSH connection
ssh -v user@remote-host

# Check SSH key authentication
ssh-add -l

# Use password authentication if keys fail
ssh -o PreferredAuthentications=password user@remote-host
```

#### Remote Installation Hangs

**Symptoms**: Installation appears to freeze on remote system
**Cause**: Interactive prompts or network timeouts
**Solution**:

```bash
# Use non-interactive installation
ssh user@remote-host 'export DEBIAN_FRONTEND=noninteractive && curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'

# Monitor with verbose SSH
ssh -v user@remote-host 'curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'
```

### Diagnostic Commands

Use these commands to diagnose issues:

```bash
# Check installation log
tail -f /tmp/dotfiles-install.log

# Verify symlinks
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim

# Test shell configuration
zsh -c "source ~/.zshrc && echo 'Config loaded successfully'"

# Check installed tools
command -v git nvim tmux zsh

# Verify PATH
echo $PATH | tr ':' '\n'

# Check for conflicting configurations
find ~ -maxdepth 2 -name ".*rc" -o -name ".*profile"
```

## Post-Deployment Validation

### Automated Validation Script

```bash
#!/bin/bash
# validate-deployment.sh

echo "Validating dotfiles deployment..."

VALIDATION_FAILED=0

validate_symlink() {
    if [ -L "$1" ] && [ -e "$1" ]; then
        echo "✓ $1 -> $(readlink "$1")"
    else
        echo "✗ $1 is missing or broken"
        VALIDATION_FAILED=1
    fi
}

validate_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✓ $1 available"
    else
        echo "✗ $1 not found"
        VALIDATION_FAILED=1
    fi
}

# Validate symlinks
echo "Checking symlinks..."
validate_symlink ~/.zshrc
validate_symlink ~/.gitconfig
validate_symlink ~/.config/nvim
validate_symlink ~/.tmux.conf

# Validate commands
echo "Checking commands..."
validate_command git
validate_command nvim
validate_command tmux
validate_command zsh

# Test shell configuration
echo "Testing shell configuration..."
if zsh -c "source ~/.zshrc" 2>/dev/null; then
    echo "✓ Shell configuration loads"
else
    echo "✗ Shell configuration has errors"
    VALIDATION_FAILED=1
fi

# Test git aliases
if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gst" >/dev/null 2>&1; then
    echo "✓ Git aliases available"
else
    echo "✗ Git aliases not working"
    VALIDATION_FAILED=1
fi

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo "✅ Deployment validation successful"
    exit 0
else
    echo "❌ Deployment validation failed"
    exit 1
fi
```

### Manual Validation Steps

1. **Test shell functionality**:

   ```bash
   # Start new shell session
   exec zsh

   # Test prompt appears correctly
   # Test git aliases work
   gst  # Should show git status
   ```

2. **Test editor configurations**:

   ```bash
   # Test Neovim
   nvim --version
   nvim +checkhealth +quit

   # Test tmux
   tmux new-session -d -s test
   tmux kill-session -t test
   ```

3. **Verify development tools**:
   ```bash
   # Test installed tools
   git --version
   go version          # If installed
   terraform version   # If installed
   aws --version       # If installed
   kubectl version --client  # If installed
   ```

## Emergency Recovery

### Complete System Recovery

If the dotfiles installation causes system instability:

1. **Boot from recovery mode** (if system won't start)
2. **Access single-user mode** or **rescue shell**
3. **Remove dotfiles directory**:
   ```bash
   rm -rf ~/.dotfiles
   ```
4. **Restore shell configuration**:
   ```bash
   # Reset to system defaults
   cp /etc/skel/.bashrc ~/.bashrc
   cp /etc/skel/.profile ~/.profile
   chsh -s /bin/bash  # Reset shell to bash
   ```
5. **Remove broken symlinks**:
   ```bash
   find ~ -type l -exec test ! -e {} \; -delete
   ```

### Contact Information

For emergency support or complex recovery scenarios:

- **Repository Issues**: https://github.com/akgoode/dotfiles/issues
- **Documentation**: https://github.com/akgoode/dotfiles/blob/main/README.md
- **Backup Strategy**: Always maintain system backups before deployment

### Recovery Checklist

- [ ] System boots and is accessible
- [ ] User can log in successfully
- [ ] Basic shell functionality works
- [ ] Critical applications are accessible
- [ ] Network connectivity is restored
- [ ] Backup configurations are restored if needed

---

**Remember**: Always test deployments in a non-production environment first, and maintain current backups of critical systems before deploying to production.
