# Comprehensive Troubleshooting Guide

This guide provides systematic troubleshooting procedures for all aspects of the dotfiles deployment system.

## Table of Contents

- [Quick Diagnostic Commands](#quick-diagnostic-commands)
- [Installation Issues](#installation-issues)
- [Configuration Problems](#configuration-problems)
- [Remote Deployment Issues](#remote-deployment-issues)
- [Platform-Specific Problems](#platform-specific-problems)
- [Recovery Procedures](#recovery-procedures)
- [Advanced Debugging](#advanced-debugging)

## Quick Diagnostic Commands

### System Information Collection

```bash
# Collect comprehensive system information
echo "=== System Information ===" > ~/dotfiles-debug.txt
uname -a >> ~/dotfiles-debug.txt
echo "" >> ~/dotfiles-debug.txt

# OS-specific information
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "=== macOS Information ===" >> ~/dotfiles-debug.txt
    sw_vers >> ~/dotfiles-debug.txt
    system_profiler SPSoftwareDataType >> ~/dotfiles-debug.txt
else
    echo "=== Linux Information ===" >> ~/dotfiles-debug.txt
    cat /etc/os-release >> ~/dotfiles-debug.txt
    lsb_release -a 2>/dev/null >> ~/dotfiles-debug.txt || true
fi

echo "" >> ~/dotfiles-debug.txt
echo "=== Environment ===" >> ~/dotfiles-debug.txt
env | sort >> ~/dotfiles-debug.txt

echo "" >> ~/dotfiles-debug.txt
echo "=== Disk Space ===" >> ~/dotfiles-debug.txt
df -h >> ~/dotfiles-debug.txt

echo "" >> ~/dotfiles-debug.txt
echo "=== Network ===" >> ~/dotfiles-debug.txt
curl -I https://github.com >> ~/dotfiles-debug.txt 2>&1

echo "Debug information saved to ~/dotfiles-debug.txt"
```

### Installation Status Check

```bash
# Quick status check
echo "=== Dotfiles Installation Status ==="

# Check if dotfiles directory exists
if [ -d ~/.dotfiles ]; then
    echo "✓ Dotfiles directory exists: ~/.dotfiles"
    echo "  Last modified: $(stat -c %y ~/.dotfiles 2>/dev/null || stat -f %Sm ~/.dotfiles)"
else
    echo "✗ Dotfiles directory missing"
fi

# Check key symlinks
echo ""
echo "=== Configuration Symlinks ==="
for link in ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.tmux.conf; do
    if [ -L "$link" ] && [ -e "$link" ]; then
        echo "✓ $link -> $(readlink "$link")"
    elif [ -e "$link" ]; then
        echo "⚠ $link exists but is not a symlink"
    else
        echo "✗ $link missing"
    fi
done

# Check shell configuration
echo ""
echo "=== Shell Configuration ==="
if zsh -c "source ~/.zshrc" 2>/dev/null; then
    echo "✓ zsh configuration loads without errors"
else
    echo "✗ zsh configuration has errors"
fi

# Check essential tools
echo ""
echo "=== Essential Tools ==="
for tool in git zsh nvim tmux; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "✓ $tool available"
    else
        echo "✗ $tool not found"
    fi
done
```

### Log Analysis

```bash
# Check installation logs
if [ -f /tmp/dotfiles-install.log ]; then
    echo "=== Recent Installation Log ==="
    tail -20 /tmp/dotfiles-install.log

    echo ""
    echo "=== Error Summary ==="
    grep -i "error\|fail\|✗" /tmp/dotfiles-install.log | tail -10
else
    echo "No installation log found at /tmp/dotfiles-install.log"
fi

# Check system logs for related errors
echo ""
echo "=== System Log Errors ==="
if [[ "$OSTYPE" == "darwin"* ]]; then
    log show --last 1h --predicate 'process CONTAINS "install" OR process CONTAINS "brew"' 2>/dev/null | tail -10
else
    journalctl --since "1 hour ago" | grep -i "dotfiles\|install" | tail -10 2>/dev/null || \
    dmesg | tail -10
fi
```

## Installation Issues

### Package Manager Problems

#### Homebrew Issues (macOS)

**Problem**: Homebrew installation fails

```bash
# Diagnosis
brew doctor

# Common fixes
# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Accept Xcode license
sudo xcodebuild -license accept

# 3. Fix Homebrew permissions
sudo chown -R $(whoami) /usr/local/Homebrew /usr/local/var/homebrew
sudo chmod -R g+rwx /usr/local/Homebrew /usr/local/var/homebrew

# 4. Reinstall Homebrew if corrupted
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Problem**: Homebrew packages fail to install

```bash
# Update Homebrew
brew update

# Fix broken packages
brew doctor
brew cleanup

# Force reinstall problematic packages
brew reinstall git curl zsh

# Check for architecture issues (Apple Silicon)
arch -arm64 brew install package_name  # For M1/M2 Macs
arch -x86_64 brew install package_name # For Intel compatibility
```

#### APT Issues (Linux)

**Problem**: Package installation fails

```bash
# Update package lists
sudo apt update

# Fix broken packages
sudo apt --fix-broken install
sudo dpkg --configure -a

# Clear package cache
sudo apt clean
sudo apt autoclean

# Fix repository issues
sudo apt update --fix-missing

# Manually install essential packages
sudo apt install -y curl git zsh build-essential
```

**Problem**: Repository access denied or not found

```bash
# Check repository configuration
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/

# Reset to default repositories (Ubuntu)
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
EOF

sudo apt update
```

### Network and Download Issues

**Problem**: Network connectivity failures

```bash
# Test basic connectivity
ping -c 3 8.8.8.8
ping -c 3 github.com

# Test DNS resolution
nslookup github.com
dig github.com

# Test HTTPS connectivity
curl -I https://github.com
curl -I https://raw.githubusercontent.com

# Check proxy settings
env | grep -i proxy

# Test with different DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
```

**Problem**: SSL/TLS certificate errors

```bash
# Update CA certificates
# macOS
brew install ca-certificates

# Linux
sudo apt update && sudo apt install ca-certificates
sudo update-ca-certificates

# Test with insecure connection (temporary workaround)
curl -k -I https://github.com

# Check system time (certificates are time-sensitive)
date
# If wrong, fix with:
sudo ntpdate -s time.nist.gov  # Linux
sudo sntp -sS time.apple.com   # macOS
```

### Permission and Access Issues

**Problem**: Permission denied errors

```bash
# Check current user and permissions
whoami
id
ls -la ~

# Fix home directory permissions
chmod 755 ~
chmod 755 ~/.config 2>/dev/null || mkdir -p ~/.config && chmod 755 ~/.config

# Check sudo access (Linux)
sudo -v

# Fix sudo configuration if needed (as root)
usermod -aG sudo $USER
# Or add to sudoers
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

**Problem**: Running as root (not recommended)

```bash
# Create regular user account
useradd -m -s /bin/bash newuser
passwd newuser
usermod -aG sudo newuser

# Switch to regular user
su - newuser

# Run installation as regular user
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash
```

### File System Issues

**Problem**: Insufficient disk space

```bash
# Check disk usage
df -h
du -sh ~ ~/.* 2>/dev/null | sort -hr

# Clean up space
# Remove old logs
sudo journalctl --vacuum-time=7d  # Linux
sudo rm -rf /var/log/*.log.1      # Old log files

# Clean package caches
sudo apt clean          # Linux
brew cleanup            # macOS

# Remove old backups
ls -la ~/.dotfiles-backup-*
# Remove old ones manually after verification
```

**Problem**: File system corruption or read-only

```bash
# Check file system status
mount | grep "$(df ~ | tail -1 | awk '{print $1}')"

# Check for file system errors
sudo fsck /dev/sda1  # Replace with actual device

# Remount as read-write
sudo mount -o remount,rw /
```

## Configuration Problems

### Shell Configuration Issues

**Problem**: zsh configuration won't load

```bash
# Test zsh syntax
zsh -n ~/.zshrc

# Load configuration step by step
zsh -c "echo 'Basic zsh works'"
zsh -c "autoload -Uz compinit && echo 'Compinit works'"
zsh -c "source ~/.zshrc && echo 'Full config works'"

# Check for missing dependencies
# vcs_info for git integration
zsh -c "autoload -Uz vcs_info && echo 'vcs_info available'"

# Reset to minimal configuration
mv ~/.zshrc ~/.zshrc.broken
echo 'export PATH="/usr/local/bin:$PATH"' > ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc
```

**Problem**: Aliases not working

```bash
# Check if aliases file exists and is sourced
ls -la ~/.config/dotfiles/shell/aliases.zsh
grep -n "aliases.zsh" ~/.zshrc

# Test alias loading manually
source ~/.config/dotfiles/shell/aliases.zsh
alias gst

# Check for conflicting aliases
alias | grep -E "^(gst|gco|gcm)="

# Reload shell configuration
exec zsh
```

**Problem**: Custom prompt not displaying

```bash
# Check prompt configuration
echo $PROMPT
echo $PS1

# Test vcs_info functionality
zsh -c "
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats '%b'
vcs_info
echo \"Git branch: \$vcs_info_msg_0_\"
"

# Reset to basic prompt
export PROMPT='%n@%m:%~$ '

# Check terminal compatibility
echo $TERM
export TERM=xterm-256color
```

### Symlink Problems

**Problem**: Symlinks not created or broken

```bash
# Check symlink status
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim

# Find broken symlinks
find ~ -maxdepth 3 -type l -exec test ! -e {} \; -print

# Recreate symlinks manually
cd ~/.dotfiles
rm -f ~/.zshrc ~/.gitconfig
ln -sf ~/.dotfiles/shell/zshrc ~/.zshrc
ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/editors/nvim ~/.config/nvim

# Check for case sensitivity issues (macOS)
ls -la ~/.dotfiles/shell/
ls -la ~/.dotfiles/git/
```

**Problem**: "File exists" errors during symlink creation

```bash
# Identify conflicting files
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim

# Backup existing files manually
mkdir -p ~/.manual-backup-$(date +%Y%m%d)
mv ~/.zshrc ~/.manual-backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv ~/.gitconfig ~/.manual-backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv ~/.config/nvim ~/.manual-backup-$(date +%Y%m%d)/ 2>/dev/null || true

# Re-run symlink creation
cd ~/.dotfiles && ./scripts/common.sh
```

### Editor Configuration Issues

**Problem**: Neovim configuration errors

```bash
# Test Neovim startup
nvim --headless -c "quit"

# Check for plugin manager
ls -la ~/.config/nvim/

# Test configuration loading
nvim --headless -c "checkhealth" -c "quit"

# Reset Neovim configuration
mv ~/.config/nvim ~/.config/nvim.broken
ln -sf ~/.dotfiles/editors/nvim ~/.config/nvim

# Clear plugin cache
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
```

**Problem**: VS Code settings not applied

```bash
# Check VS Code settings location
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
else
    VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
fi

echo "VS Code settings should be at: $VSCODE_SETTINGS"
ls -la "$VSCODE_SETTINGS"

# Check if it's a symlink to dotfiles
readlink "$VSCODE_SETTINGS"

# Recreate symlink
rm -f "$VSCODE_SETTINGS"
mkdir -p "$(dirname "$VSCODE_SETTINGS")"
ln -sf ~/.dotfiles/editors/vscode/settings.json "$VSCODE_SETTINGS"

# Validate JSON syntax
if command -v jq >/dev/null; then
    jq empty "$VSCODE_SETTINGS"
else
    python -m json.tool "$VSCODE_SETTINGS" >/dev/null
fi
```

## Remote Deployment Issues

### SSH Connection Problems

**Problem**: SSH connection refused or times out

```bash
# Test basic connectivity
ping remote-host
telnet remote-host 22

# Test SSH with verbose output
ssh -v user@remote-host

# Try different authentication methods
ssh -o PreferredAuthentications=password user@remote-host
ssh -o PreferredAuthentications=publickey user@remote-host

# Check SSH client configuration
cat ~/.ssh/config
ls -la ~/.ssh/

# Test with different port
ssh -p 2222 user@remote-host
```

**Problem**: SSH key authentication fails

```bash
# Check local SSH keys
ssh-add -l
ls -la ~/.ssh/

# Test key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub

# Copy key to remote host
ssh-copy-id user@remote-host

# Manual key installation
cat ~/.ssh/id_rsa.pub | ssh user@remote-host 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'

# Check remote SSH configuration
ssh user@remote-host 'ls -la ~/.ssh/ && cat ~/.ssh/authorized_keys'
```

### Remote Installation Problems

**Problem**: Installation hangs on remote system

```bash
# Check if process is running
ssh user@remote-host 'ps aux | grep -E "(install|curl|wget)"'

# Kill hanging processes
ssh user@remote-host 'pkill -f "install.sh"'

# Use non-interactive installation
ssh user@remote-host 'export DEBIAN_FRONTEND=noninteractive && curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'

# Use screen/tmux for stability
ssh user@remote-host
screen -S dotfiles
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash
# Ctrl+A, D to detach
```

**Problem**: Remote system lacks required tools

```bash
# Install minimal requirements
ssh user@remote-host 'sudo apt update && sudo apt install -y curl git'

# Check system compatibility
ssh user@remote-host 'curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/scripts/check-requirements.sh | bash'

# Manual tool installation
ssh user@remote-host 'which curl || sudo apt install -y curl'
ssh user@remote-host 'which git || sudo apt install -y git'
```

## Platform-Specific Problems

### macOS Issues

**Problem**: Xcode Command Line Tools missing or broken

```bash
# Check installation status
xcode-select -p

# Install Command Line Tools
xcode-select --install

# Reset Command Line Tools
sudo xcode-select --reset
sudo xcode-select --install

# Accept license
sudo xcodebuild -license accept

# Verify installation
gcc --version
make --version
```

**Problem**: Apple Silicon (M1/M2) compatibility issues

```bash
# Check architecture
uname -m
arch

# Install Rosetta 2 for Intel compatibility
sudo softwareupdate --install-rosetta

# Use architecture-specific commands
arch -arm64 brew install package_name    # Native ARM64
arch -x86_64 brew install package_name   # Intel compatibility

# Check Homebrew installation
which brew
brew --version
brew config
```

**Problem**: macOS security restrictions (Gatekeeper, SIP)

```bash
# Check Gatekeeper status
spctl --status

# Allow unsigned applications (temporary)
sudo spctl --master-disable

# Check System Integrity Protection
csrutil status

# Bypass quarantine for specific files
xattr -d com.apple.quarantine /path/to/file

# Check security settings
sudo spctl --assess --verbose /Applications/SomeApp.app
```

### Linux Distribution Issues

**Problem**: Package names differ between distributions

```bash
# Identify distribution
cat /etc/os-release
lsb_release -a

# Distribution-specific package installation
# Ubuntu/Debian
sudo apt install -y fd-find ripgrep

# CentOS/RHEL/Fedora
sudo dnf install -y fd-find ripgrep  # Fedora
sudo yum install -y fd-find ripgrep  # CentOS 7

# Arch Linux
sudo pacman -S fd ripgrep

# Alpine Linux
sudo apk add fd ripgrep

# Check package availability
apt search fd-find
dnf search fd-find
```

**Problem**: Systemd vs init system differences

```bash
# Check init system
ps -p 1 -o comm=

# Systemd commands
sudo systemctl status ssh
sudo systemctl start ssh
sudo systemctl enable ssh

# SysV init commands
sudo service ssh status
sudo service ssh start
sudo update-rc.d ssh enable

# Check service status
if command -v systemctl >/dev/null; then
    sudo systemctl status ssh
else
    sudo service ssh status
fi
```

## Recovery Procedures

### Emergency Shell Recovery

**Problem**: Shell becomes completely unusable

```bash
# Method 1: Use bash directly
bash

# Method 2: Reset shell to bash
chsh -s /bin/bash

# Method 3: Emergency zsh reset
mv ~/.zshrc ~/.zshrc.emergency-backup
echo 'export PATH="/usr/local/bin:/usr/bin:/bin"' > ~/.zshrc

# Method 4: Use system default shell
cp /etc/skel/.bashrc ~/.bashrc
export SHELL=/bin/bash
```

### Configuration Recovery

**Problem**: All configurations are broken

```bash
# Step 1: Remove all dotfiles symlinks
find ~ -maxdepth 3 -type l -exec sh -c '
    for link; do
        if readlink "$link" | grep -q "/.dotfiles/"; then
            echo "Removing: $link"
            rm "$link"
        fi
    done
' sh {} +

# Step 2: Restore from backup
BACKUP_DIR=$(ls -td ~/.dotfiles-backup-* ~/.manual-backup-* 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Restoring from: $BACKUP_DIR"
    cp -r "$BACKUP_DIR"/* ~ 2>/dev/null || true
fi

# Step 3: Reset to system defaults
cp /etc/skel/.bashrc ~/.bashrc 2>/dev/null || true
cp /etc/skel/.profile ~/.profile 2>/dev/null || true

# Step 4: Verify basic functionality
bash -c "echo 'Basic shell works'"
```

### System Recovery

**Problem**: System won't boot or is unstable

```bash
# Boot from recovery mode or live USB
# Mount the affected filesystem
sudo mount /dev/sda1 /mnt

# Remove problematic configurations
sudo rm -f /mnt/home/user/.zshrc
sudo rm -rf /mnt/home/user/.config/nvim
sudo rm -rf /mnt/home/user/.dotfiles

# Restore from backup if available
sudo cp -r /mnt/home/user/.dotfiles-backup-*/* /mnt/home/user/ 2>/dev/null || true

# Fix ownership
sudo chown -R user:user /mnt/home/user

# Unmount and reboot
sudo umount /mnt
sudo reboot
```

## Advanced Debugging

### Detailed Logging and Tracing

**Enable comprehensive logging:**

```bash
# Create debug installation script
cat > ~/debug-install.sh << 'EOF'
#!/bin/bash
set -x  # Enable command tracing
exec > >(tee ~/dotfiles-debug.log) 2>&1  # Log everything

echo "Starting debug installation at $(date)"
echo "System: $(uname -a)"
echo "User: $(whoami)"
echo "Home: $HOME"
echo "Shell: $SHELL"
echo "PATH: $PATH"

# Run installation with full debugging
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash

echo "Installation completed at $(date)"
EOF

chmod +x ~/debug-install.sh
~/debug-install.sh
```

**Analyze installation logs:**

```bash
# Search for specific error patterns
grep -n -A5 -B5 "error\|fail\|✗" ~/dotfiles-debug.log

# Check command execution
grep -n "^+" ~/dotfiles-debug.log | tail -20

# Look for permission issues
grep -n "permission\|denied\|cannot" ~/dotfiles-debug.log

# Check network issues
grep -n "curl\|wget\|download\|network" ~/dotfiles-debug.log
```

### Performance Analysis

**Identify slow operations:**

```bash
# Time shell startup
time zsh -c "exit"

# Profile zsh startup
zsh -xvs <<< "exit" 2>&1 | head -50

# Check for slow network operations
time curl -I https://github.com

# Monitor system resources during installation
top -p $(pgrep -f install) &
iostat 1 &
# Run installation
# Kill monitoring: killall top iostat
```

### Network Debugging

**Detailed network analysis:**

```bash
# Test all required domains with timing
domains=(
    "github.com"
    "raw.githubusercontent.com"
    "archive.ubuntu.com"
    "releases.hashicorp.com"
    "awscli.amazonaws.com"
    "dl.k8s.io"
    "go.dev"
)

for domain in "${domains[@]}"; do
    echo "Testing $domain..."
    time curl -I --connect-timeout 10 "https://$domain" 2>&1 | head -5
    echo "---"
done

# Check DNS resolution timing
for domain in "${domains[@]}"; do
    echo "DNS lookup for $domain:"
    time nslookup "$domain"
    echo "---"
done

# Test with different DNS servers
echo "Testing with Google DNS..."
dig @8.8.8.8 github.com

echo "Testing with Cloudflare DNS..."
dig @1.1.1.1 github.com
```

### File System Analysis

**Check file system integrity:**

```bash
# Check for file system errors
sudo fsck -n /dev/sda1  # Read-only check

# Check inode usage
df -i

# Check for immutable files
find ~ -maxdepth 2 -exec lsattr {} \; 2>/dev/null | grep -v "^-"

# Check file permissions recursively
find ~ -maxdepth 2 -type f -exec ls -la {} \; | grep -v "^-rw"

# Check for special characters in filenames
find ~ -maxdepth 2 -name "*[^a-zA-Z0-9._/-]*" 2>/dev/null
```

## Getting Help

### Information to Collect Before Seeking Help

1. **System Information**:

   ```bash
   uname -a
   cat /etc/os-release  # Linux
   sw_vers              # macOS
   ```

2. **Installation Logs**:

   ```bash
   cat /tmp/dotfiles-install.log
   cat ~/dotfiles-debug.log  # If using debug script
   ```

3. **Current State**:

   ```bash
   ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim
   zsh -n ~/.zshrc  # Syntax check
   ```

4. **Error Messages**: Copy exact error messages and commands that failed

5. **Network Status**:
   ```bash
   curl -I https://github.com
   ping -c 3 github.com
   ```

### Support Channels

- **GitHub Issues**: https://github.com/akgoode/dotfiles/issues
- **Documentation**: https://github.com/akgoode/dotfiles/blob/main/README.md
- **Deployment Guide**: https://github.com/akgoode/dotfiles/blob/main/docs/DEPLOYMENT.md

### Creating Effective Bug Reports

1. **Clear title**: Describe the problem concisely
2. **Environment**: OS, version, architecture
3. **Steps to reproduce**: Exact commands and sequence
4. **Expected behavior**: What should happen
5. **Actual behavior**: What actually happens
6. **Logs and output**: Relevant log excerpts
7. **Workarounds**: Any temporary fixes you've tried

---

**Remember**: Most issues can be resolved by following the systematic troubleshooting steps above. Always check the basics first: network connectivity, permissions, and system requirements.
