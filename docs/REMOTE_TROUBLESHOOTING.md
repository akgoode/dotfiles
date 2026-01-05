# Remote Deployment Troubleshooting Guide

This guide covers troubleshooting issues specific to remote deployments via SSH and production environments.

## Table of Contents

- [SSH Connection Issues](#ssh-connection-issues)
- [Remote Installation Problems](#remote-installation-problems)
- [Network and Connectivity](#network-and-connectivity)
- [Permission and Security Issues](#permission-and-security-issues)
- [Platform-Specific Problems](#platform-specific-problems)
- [Validation Failures](#validation-failures)
- [Recovery Procedures](#recovery-procedures)

## SSH Connection Issues

### Cannot Connect to Remote Host

**Symptoms**: `ssh: connect to host X port 22: Connection refused`

**Diagnosis**:

```bash
# Test basic connectivity
ping remote-host

# Test SSH port
telnet remote-host 22
# or
nc -zv remote-host 22

# Check SSH service status (on remote host)
sudo systemctl status ssh  # Ubuntu/Debian
sudo systemctl status sshd # CentOS/RHEL
```

**Solutions**:

```bash
# Start SSH service (on remote host)
sudo systemctl start ssh
sudo systemctl enable ssh

# Check firewall (on remote host)
sudo ufw status
sudo ufw allow ssh

# Alternative port connection
ssh -p 2222 user@remote-host
```

### SSH Key Authentication Fails

**Symptoms**: `Permission denied (publickey)`

**Diagnosis**:

```bash
# Test with verbose output
ssh -v user@remote-host

# Check local SSH keys
ssh-add -l

# Check key permissions
ls -la ~/.ssh/
```

**Solutions**:

```bash
# Generate new SSH key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy key to remote host
ssh-copy-id user@remote-host

# Fix key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub

# Use password authentication temporarily
ssh -o PreferredAuthentications=password user@remote-host
```

### SSH Session Hangs or Drops

**Symptoms**: Connection freezes during installation

**Diagnosis**:

```bash
# Check for network issues
ssh -o ServerAliveInterval=60 user@remote-host

# Monitor connection
ssh -v -o LogLevel=DEBUG user@remote-host
```

**Solutions**:

```bash
# Use persistent connection
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 user@remote-host

# Use screen/tmux for long-running processes
ssh user@remote-host
screen -S dotfiles-install
# Run installation inside screen session

# Alternative: Use nohup for background execution
ssh user@remote-host 'nohup curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash > install.log 2>&1 &'
```

## Remote Installation Problems

### Installation Hangs on Interactive Prompts

**Symptoms**: Installation stops waiting for input

**Diagnosis**:

```bash
# Check if process is waiting for input
ssh user@remote-host 'ps aux | grep -E "(install|apt|brew)"'

# Check installation log
ssh user@remote-host 'tail -f /tmp/dotfiles-install.log'
```

**Solutions**:

```bash
# Use non-interactive mode
ssh user@remote-host 'export DEBIAN_FRONTEND=noninteractive && curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'

# Pre-configure debconf (Ubuntu/Debian)
ssh user@remote-host 'echo "debconf debconf/frontend select Noninteractive" | sudo debconf-set-selections'

# Use expect for interactive prompts
ssh user@remote-host 'expect -c "
spawn curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash
expect \"Do you want to continue?\" { send \"y\r\" }
expect eof
"'
```

### Package Installation Fails Remotely

**Symptoms**: Packages fail to install on remote system

**Diagnosis**:

```bash
# Check package manager status
ssh user@remote-host 'sudo apt update && apt list --upgradable'  # Ubuntu/Debian
ssh user@remote-host 'brew doctor'  # macOS

# Check available disk space
ssh user@remote-host 'df -h'

# Check internet connectivity from remote host
ssh user@remote-host 'curl -I https://github.com'
```

**Solutions**:

```bash
# Fix package manager issues (Ubuntu/Debian)
ssh user@remote-host 'sudo apt update --fix-missing'
ssh user@remote-host 'sudo apt --fix-broken install'
ssh user@remote-host 'sudo dpkg --configure -a'

# Clear package cache
ssh user@remote-host 'sudo apt clean && sudo apt autoclean'

# Fix Homebrew issues (macOS)
ssh user@remote-host 'brew update && brew doctor'
ssh user@remote-host 'brew cleanup'

# Manual package installation
ssh user@remote-host 'sudo apt install -y git curl zsh neovim'
```

### Symlink Creation Fails

**Symptoms**: "File exists" or permission errors during symlink creation

**Diagnosis**:

```bash
# Check existing files
ssh user@remote-host 'ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim'

# Check permissions
ssh user@remote-host 'ls -ld ~ ~/.config'

# Check for immutable files
ssh user@remote-host 'lsattr ~/.zshrc 2>/dev/null || echo "lsattr not available"'
```

**Solutions**:

```bash
# Backup and remove existing files
ssh user@remote-host '
    mkdir -p ~/.manual-backup-$(date +%Y%m%d)
    cp ~/.zshrc ~/.manual-backup-* 2>/dev/null || true
    cp ~/.gitconfig ~/.manual-backup-* 2>/dev/null || true
    rm -f ~/.zshrc ~/.gitconfig
'

# Fix permissions
ssh user@remote-host 'chmod 755 ~ && mkdir -p ~/.config && chmod 755 ~/.config'

# Remove immutable attribute if set
ssh user@remote-host 'sudo chattr -i ~/.zshrc 2>/dev/null || true'

# Re-run symlink creation
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/common.sh'
```

## Network and Connectivity

### DNS Resolution Issues

**Symptoms**: Cannot resolve hostnames during installation

**Diagnosis**:

```bash
# Test DNS resolution
ssh user@remote-host 'nslookup github.com'
ssh user@remote-host 'dig github.com'

# Check DNS configuration
ssh user@remote-host 'cat /etc/resolv.conf'
```

**Solutions**:

```bash
# Use alternative DNS servers
ssh user@remote-host 'echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf'
ssh user@remote-host 'echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf'

# Flush DNS cache
ssh user@remote-host 'sudo systemctl restart systemd-resolved'  # Ubuntu 18.04+
ssh user@remote-host 'sudo dscacheutil -flushcache'  # macOS
```

### Proxy and Firewall Issues

**Symptoms**: Downloads fail with connection timeouts

**Diagnosis**:

```bash
# Check proxy settings
ssh user@remote-host 'env | grep -i proxy'

# Test direct connection
ssh user@remote-host 'curl -I --connect-timeout 10 https://github.com'

# Check firewall rules
ssh user@remote-host 'sudo iptables -L'  # Linux
ssh user@remote-host 'sudo ufw status'   # Ubuntu
```

**Solutions**:

```bash
# Configure proxy if needed
ssh user@remote-host 'export http_proxy=http://proxy.company.com:8080'
ssh user@remote-host 'export https_proxy=http://proxy.company.com:8080'

# Bypass proxy for specific domains
ssh user@remote-host 'export no_proxy=localhost,127.0.0.1,github.com'

# Allow outbound HTTPS traffic
ssh user@remote-host 'sudo ufw allow out 443'
```

### Slow Download Speeds

**Symptoms**: Installation takes very long due to slow downloads

**Diagnosis**:

```bash
# Test download speed
ssh user@remote-host 'curl -o /dev/null -s -w "%{speed_download}\n" https://github.com/akgoode/dotfiles/archive/main.zip'

# Check bandwidth usage
ssh user@remote-host 'iftop -t -s 10'  # If available
```

**Solutions**:

```bash
# Use alternative mirrors or CDNs
ssh user@remote-host 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles'

# Download large files separately
ssh user@remote-host 'wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz'

# Use compression for SSH
ssh -C user@remote-host
```

## Permission and Security Issues

### Sudo Access Problems

**Symptoms**: "sudo: command not found" or permission denied

**Diagnosis**:

```bash
# Check sudo availability
ssh user@remote-host 'which sudo'

# Check user groups
ssh user@remote-host 'groups'
ssh user@remote-host 'id'

# Check sudoers configuration
ssh user@remote-host 'sudo -l'
```

**Solutions**:

```bash
# Add user to sudo group (as root)
ssh root@remote-host 'usermod -aG sudo username'

# Alternative: Use su for root access
ssh user@remote-host 'su -c "apt update"'

# Configure passwordless sudo (if appropriate)
ssh root@remote-host 'echo "username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/username'
```

### SELinux/AppArmor Restrictions

**Symptoms**: Permission denied despite correct file permissions

**Diagnosis**:

```bash
# Check SELinux status
ssh user@remote-host 'sestatus'
ssh user@remote-host 'getenforce'

# Check AppArmor status
ssh user@remote-host 'sudo aa-status'

# Check for denials
ssh user@remote-host 'sudo ausearch -m AVC -ts recent'  # SELinux
ssh user@remote-host 'sudo dmesg | grep -i apparmor'    # AppArmor
```

**Solutions**:

```bash
# Temporarily disable SELinux (not recommended for production)
ssh user@remote-host 'sudo setenforce 0'

# Set correct SELinux contexts
ssh user@remote-host 'sudo restorecon -R ~/.dotfiles'

# Disable AppArmor profile temporarily
ssh user@remote-host 'sudo aa-disable /usr/bin/program'

# Create custom SELinux policy (advanced)
ssh user@remote-host 'sudo audit2allow -a -M dotfiles_policy'
ssh user@remote-host 'sudo semodule -i dotfiles_policy.pp'
```

## Platform-Specific Problems

### macOS Remote Issues

**Symptoms**: Homebrew or Xcode tools issues on remote Mac

**Diagnosis**:

```bash
# Check Xcode Command Line Tools
ssh user@remote-mac 'xcode-select -p'

# Check Homebrew installation
ssh user@remote-mac 'brew --version'

# Check macOS version
ssh user@remote-mac 'sw_vers'
```

**Solutions**:

```bash
# Install Xcode Command Line Tools
ssh user@remote-mac 'xcode-select --install'

# Accept Xcode license
ssh user@remote-mac 'sudo xcodebuild -license accept'

# Install Homebrew manually
ssh user@remote-mac '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Fix Homebrew permissions
ssh user@remote-mac 'sudo chown -R $(whoami) /usr/local/Homebrew'
```

### Linux Distribution Differences

**Symptoms**: Package names or paths differ between distributions

**Diagnosis**:

```bash
# Identify distribution
ssh user@remote-host 'cat /etc/os-release'
ssh user@remote-host 'lsb_release -a'

# Check package manager
ssh user@remote-host 'which apt yum dnf pacman'
```

**Solutions**:

```bash
# CentOS/RHEL/Fedora adaptations
ssh user@remote-host 'sudo yum install -y git curl zsh neovim'  # CentOS 7
ssh user@remote-host 'sudo dnf install -y git curl zsh neovim'  # Fedora/CentOS 8+

# Arch Linux adaptations
ssh user@remote-host 'sudo pacman -S git curl zsh neovim'

# Alpine Linux adaptations
ssh user@remote-host 'sudo apk add git curl zsh neovim'

# Use distribution-specific package names
# fd-find (Ubuntu) vs fd (other distros)
# ripgrep vs rg package names
```

## Validation Failures

### Symlink Validation Fails

**Symptoms**: Validation script reports broken or missing symlinks

**Diagnosis**:

```bash
# Run validation script
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/validate-production-deployment.sh'

# Check specific symlinks
ssh user@remote-host 'ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim'

# Check symlink targets
ssh user@remote-host 'readlink ~/.zshrc'
```

**Solutions**:

```bash
# Re-create symlinks
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/common.sh'

# Fix broken symlinks manually
ssh user@remote-host 'ln -sf ~/.dotfiles/shell/zshrc ~/.zshrc'
ssh user@remote-host 'ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig'

# Check for case sensitivity issues
ssh user@remote-host 'ls -la ~/.dotfiles/shell/'
```

### Shell Configuration Validation Fails

**Symptoms**: zsh configuration doesn't load or has errors

**Diagnosis**:

```bash
# Test zsh configuration syntax
ssh user@remote-host 'zsh -n ~/.zshrc'

# Check for missing dependencies
ssh user@remote-host 'zsh -c "autoload -Uz vcs_info"'

# Test alias loading
ssh user@remote-host 'zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gst"'
```

**Solutions**:

```bash
# Fix zsh configuration
ssh user@remote-host 'cd ~/.dotfiles && git pull'  # Get latest fixes

# Install missing zsh
ssh user@remote-host 'sudo apt install -y zsh'

# Reset zsh configuration
ssh user@remote-host 'rm ~/.zshrc && ln -s ~/.dotfiles/shell/zshrc ~/.zshrc'

# Test step by step
ssh user@remote-host 'zsh -c "echo test"'  # Basic zsh
ssh user@remote-host 'zsh -c "source ~/.zshrc && echo loaded"'  # Config loading
```

## Recovery Procedures

### Emergency Remote Recovery

If the remote system becomes unusable:

```bash
# 1. Connect and assess damage
ssh user@remote-host

# 2. Check if shell works
bash  # Use bash if zsh is broken

# 3. Quick rollback
cd ~/.dotfiles
./scripts/rollback.sh

# 4. Manual restoration if rollback fails
mv ~/.zshrc.backup ~/.zshrc 2>/dev/null || true
mv ~/.gitconfig.backup ~/.gitconfig 2>/dev/null || true
rm -f ~/.config/nvim && mv ~/.config/nvim.backup ~/.config/nvim 2>/dev/null || true

# 5. Reset shell to bash
chsh -s /bin/bash

# 6. Remove dotfiles if necessary
rm -rf ~/.dotfiles
```

### Partial Recovery

For partial failures where some components work:

```bash
# Identify working components
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/validate-production-deployment.sh'

# Fix only broken components
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/common.sh'  # Re-run symlinks
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/install-linux.sh'  # Re-run packages

# Test incrementally
ssh user@remote-host 'zsh -c "echo test"'  # Test shell
ssh user@remote-host 'git --version'       # Test git
ssh user@remote-host 'nvim --version'      # Test neovim
```

### Remote Debugging Session

For complex issues requiring investigation:

```bash
# Start debugging session with logging
ssh user@remote-host 'script -a debug-session.log'

# Enable verbose logging
ssh user@remote-host 'set -x'

# Re-run problematic commands
ssh user@remote-host 'cd ~/.dotfiles && ./install.sh'

# Collect system information
ssh user@remote-host '
echo "=== System Info ===" >> debug-info.txt
uname -a >> debug-info.txt
cat /etc/os-release >> debug-info.txt
df -h >> debug-info.txt
free -h >> debug-info.txt
env >> debug-info.txt
'

# Download logs for analysis
scp user@remote-host:debug-session.log ./
scp user@remote-host:debug-info.txt ./
scp user@remote-host:/tmp/dotfiles-install.log ./
```

## Getting Help

### Information to Collect

When seeking help, collect this information:

```bash
# System information
ssh user@remote-host 'uname -a && cat /etc/os-release'

# Installation logs
ssh user@remote-host 'cat /tmp/dotfiles-install.log'

# Validation results
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/validate-production-deployment.sh'

# Network connectivity
ssh user@remote-host 'curl -I https://github.com'

# Permissions and ownership
ssh user@remote-host 'ls -la ~ ~/.config ~/.dotfiles'
```

### Support Channels

- **GitHub Issues**: https://github.com/akgoode/dotfiles/issues
- **Documentation**: https://github.com/akgoode/dotfiles/blob/main/README.md
- **Deployment Guide**: https://github.com/akgoode/dotfiles/blob/main/docs/DEPLOYMENT.md

### Creating Reproducible Bug Reports

1. **Minimal reproduction case**: Simplest steps to reproduce the issue
2. **Environment details**: OS, version, network setup
3. **Complete logs**: Installation and validation logs
4. **Expected vs actual behavior**: What should happen vs what happens
5. **Workarounds attempted**: What you've already tried

---

**Remember**: Always maintain backups and test recovery procedures before deploying to critical production systems.
