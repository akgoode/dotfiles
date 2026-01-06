# Production Deployment Checklist

This comprehensive checklist ensures safe and successful deployment of the dotfiles system to production environments.

## Table of Contents

- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Deployment Execution](#deployment-execution)
- [Post-Deployment Validation](#post-deployment-validation)
- [Rollback Procedures](#rollback-procedures)
- [Emergency Recovery](#emergency-recovery)

## Pre-Deployment Checklist

### System Requirements Verification

**Run the automated requirements check first:**

```bash
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/scripts/check-requirements.sh | bash
```

**Manual verification checklist:**

#### Operating System Support

- [ ] **macOS**: Version 10.15 (Catalina) or later
- [ ] **Linux**: Ubuntu 20.04+ or Debian 11+
- [ ] Architecture: x86_64 or aarch64/arm64

#### System Resources

- [ ] **Disk Space**: Minimum 2GB free space in home directory
- [ ] **Memory**: At least 1GB available RAM during installation
- [ ] **Network**: Stable internet connection (test with `ping github.com`)

#### User Permissions

- [ ] **Not running as root** (recommended for security)
- [ ] **Sudo access available** (Linux only - test with `sudo -v`)
- [ ] **Home directory writable** (test with `touch ~/.test && rm ~/.test`)

#### Essential Tools Present

- [ ] **curl** installed and functional
- [ ] **git** installed and functional
- [ ] **Xcode Command Line Tools** (macOS only - run `xcode-select --install` if missing)
- [ ] **Package manager access** (Homebrew on macOS, apt on Linux)

### Network and Security Verification

#### Internet Connectivity Test

Test access to all required domains:

```bash
# Core domains
curl -I --connect-timeout 10 https://github.com
curl -I --connect-timeout 10 https://raw.githubusercontent.com

# Package sources
curl -I --connect-timeout 10 https://archive.ubuntu.com  # Linux
curl -I --connect-timeout 10 https://brew.sh             # macOS

# Tool downloads
curl -I --connect-timeout 10 https://releases.hashicorp.com
curl -I --connect-timeout 10 https://awscli.amazonaws.com
curl -I --connect-timeout 10 https://dl.k8s.io
curl -I --connect-timeout 10 https://go.dev
```

#### Security Considerations

- [ ] **Firewall rules** allow outbound HTTPS (port 443)
- [ ] **Proxy configuration** set if required (`http_proxy`, `https_proxy` environment variables)
- [ ] **Corporate security policies** reviewed and approved
- [ ] **SSH access configured** (for remote deployments)

### Backup Strategy

#### Pre-Installation Backup

- [ ] **Create manual backup directory**: `mkdir -p ~/.dotfiles-manual-backup-$(date +%Y%m%d-%H%M%S)`
- [ ] **Backup existing configurations**:

  ```bash
  BACKUP_DIR=~/.dotfiles-manual-backup-$(date +%Y%m%d-%H%M%S)
  mkdir -p "$BACKUP_DIR"

  # Backup key configuration files
  [ -f ~/.zshrc ] && cp ~/.zshrc "$BACKUP_DIR/"
  [ -f ~/.gitconfig ] && cp ~/.gitconfig "$BACKUP_DIR/"
  [ -d ~/.config/nvim ] && cp -r ~/.config/nvim "$BACKUP_DIR/"
  [ -f ~/.tmux.conf ] && cp ~/.tmux.conf "$BACKUP_DIR/"

  # Backup editor settings
  if [[ "$OSTYPE" == "darwin"* ]]; then
      [ -f "$HOME/Library/Application Support/Code/User/settings.json" ] && \
          cp "$HOME/Library/Application Support/Code/User/settings.json" "$BACKUP_DIR/"
  else
      [ -f ~/.config/Code/User/settings.json ] && \
          cp ~/.config/Code/User/settings.json "$BACKUP_DIR/"
  fi

  echo "Manual backup created in: $BACKUP_DIR"
  ```

#### System State Documentation

- [ ] **Document current shell**: `echo $SHELL`
- [ ] **List installed packages** (for comparison):

  ```bash
  # macOS
  brew list > ~/pre-install-packages.txt

  # Linux
  dpkg -l > ~/pre-install-packages.txt
  ```

- [ ] **Document current PATH**: `echo $PATH > ~/pre-install-path.txt`

### Change Management

#### Approval and Communication

- [ ] **Change request approved** (if required by organization)
- [ ] **Stakeholders notified** of deployment window
- [ ] **Rollback plan communicated** to relevant teams
- [ ] **Emergency contacts identified** and available

#### Testing Environment Validation

- [ ] **Docker testing completed** successfully
- [ ] **Similar environment tested** (staging/development)
- [ ] **Known issues documented** and mitigation planned

## Deployment Execution

### Local Deployment

#### Standard Installation Process

1. **Execute installation command**:

   ```bash
   # Method 1: One-line installation (recommended)
   curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash

   # Method 2: Manual clone (for debugging)
   git clone https://github.com/akgoode/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./install.sh
   ```

2. **Monitor installation progress**:

   - [ ] Watch for **green checkmarks** (✓) indicating success
   - [ ] Note any **yellow warnings** (⚠) - usually non-critical
   - [ ] Stop immediately on **red errors** (✗) and investigate

3. **Installation log monitoring**:
   ```bash
   # In another terminal, monitor the log
   tail -f /tmp/dotfiles-install.log
   ```

#### Installation Phases Checklist

- [ ] **Phase 1**: OS detection and repository setup
- [ ] **Phase 2**: Package manager setup (Homebrew/apt)
- [ ] **Phase 3**: Package installation (CLI tools, development tools)
- [ ] **Phase 4**: Configuration file backup and symlink creation
- [ ] **Phase 5**: Editor configuration (Neovim, VS Code, Kiro)
- [ ] **Phase 6**: Shell configuration and default shell setup
- [ ] **Phase 7**: Final validation and cleanup

### Remote Deployment

#### SSH Connection Preparation

- [ ] **Test SSH connection**: `ssh user@remote-host`
- [ ] **Verify SSH key authentication** or password access
- [ ] **Test sudo access on remote**: `ssh user@remote-host 'sudo -v'`

#### Remote Execution Options

**Option 1: Direct remote execution**

```bash
ssh user@remote-host 'curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'
```

**Option 2: Screen/tmux session (recommended for stability)**

```bash
ssh user@remote-host
screen -S dotfiles-install
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash
# Ctrl+A, D to detach; screen -r dotfiles-install to reattach
```

**Option 3: Background execution with logging**

```bash
ssh user@remote-host 'nohup curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash > ~/dotfiles-install.log 2>&1 &'
```

#### Remote Monitoring

- [ ] **Monitor SSH connection stability**
- [ ] **Check installation progress**: `ssh user@remote-host 'tail -f /tmp/dotfiles-install.log'`
- [ ] **Verify no interactive prompts** are blocking installation

### Multi-System Deployment

#### Batch Deployment Script

For deploying to multiple systems, use this template:

```bash
#!/bin/bash
# multi-system-deployment.sh

HOSTS=(
    "user1@server1.example.com"
    "user2@server2.example.com"
    "user3@server3.example.com"
)

INSTALL_COMMAND='curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash'
LOG_DIR="./deployment-logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

echo "Starting deployment to ${#HOSTS[@]} systems..."
echo "Logs will be saved to: $LOG_DIR"

for host in "${HOSTS[@]}"; do
    echo "================================================"
    echo "Deploying to: $host"
    echo "================================================"

    # Create log file for this host
    log_file="$LOG_DIR/${host//[@:]/_}.log"

    # Execute deployment
    if ssh "$host" "$INSTALL_COMMAND" 2>&1 | tee "$log_file"; then
        echo "✓ $host deployment successful"
        echo "$host SUCCESS" >> "$LOG_DIR/summary.log"
    else
        echo "✗ $host deployment failed"
        echo "$host FAILED" >> "$LOG_DIR/summary.log"
        echo "$host" >> "$LOG_DIR/failed-hosts.txt"
    fi

    echo ""
done

echo "================================================"
echo "Deployment Summary"
echo "================================================"
cat "$LOG_DIR/summary.log"

if [ -f "$LOG_DIR/failed-hosts.txt" ]; then
    echo ""
    echo "Failed deployments:"
    cat "$LOG_DIR/failed-hosts.txt"
fi
```

#### Batch Deployment Checklist

- [ ] **Test script on single system** first
- [ ] **Verify SSH key authentication** for all hosts
- [ ] **Check network connectivity** to all hosts
- [ ] **Plan deployment order** (critical systems last)
- [ ] **Monitor deployment progress** for each system
- [ ] **Document any failures** for later investigation

## Post-Deployment Validation

### Automated Validation

**Run the comprehensive validation script:**

```bash
cd ~/.dotfiles
./scripts/validate-production-deployment.sh
```

### Manual Validation Checklist

#### Core Functionality

- [ ] **New shell session works**: `exec zsh`
- [ ] **Custom prompt displays**: Should show path and git branch
- [ ] **Git aliases functional**: Test `gst`, `gco`, `gcm`, `gd`, `gl`, `gp`
- [ ] **Essential tools available**: `git --version`, `nvim --version`, `tmux -V`

#### Configuration Integrity

- [ ] **Symlinks created correctly**:
  ```bash
  ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.tmux.conf
  ```
- [ ] **Symlinks point to dotfiles**:
  ```bash
  readlink ~/.zshrc ~/.gitconfig ~/.config/nvim
  ```
- [ ] **No broken symlinks**: `find ~ -maxdepth 3 -type l -exec test ! -e {} \; -print`

#### Editor Configuration

- [ ] **Neovim starts without errors**: `nvim --headless -c "quit"`
- [ ] **VS Code settings applied** (if VS Code installed)
- [ ] **Kiro MCP configuration valid** (if Kiro installed)

#### Development Workflow

- [ ] **Git workflow test**:
  ```bash
  cd /tmp
  mkdir test-repo && cd test-repo
  git init
  echo "test" > README.md
  git add README.md
  git commit -m "Initial commit"
  cd .. && rm -rf test-repo
  ```
- [ ] **Shell aliases work**: Test common development aliases
- [ ] **PATH includes new tools**: `echo $PATH | grep -E "(go|terraform|aws)"`

### Performance and Stability

- [ ] **Shell startup time acceptable**: Time `zsh -c "exit"` (should be < 1 second)
- [ ] **No memory leaks**: Monitor memory usage during normal operations
- [ ] **No error messages**: Check for errors in shell startup

### Cross-Platform Consistency (if applicable)

- [ ] **Compare with reference system**: Ensure identical functionality
- [ ] **Platform-specific features work**: Test macOS/Linux specific tools
- [ ] **File paths resolve correctly**: No hardcoded path issues

## Rollback Procedures

### Automatic Rollback

**If installation fails, use the built-in rollback:**

```bash
cd ~/.dotfiles
./scripts/rollback.sh
```

### Manual Rollback Steps

#### Quick Rollback (restore from .backup files)

```bash
# Restore individual files
[ -f ~/.zshrc.backup ] && mv ~/.zshrc.backup ~/.zshrc
[ -f ~/.gitconfig.backup ] && mv ~/.gitconfig.backup ~/.gitconfig
[ -f ~/.tmux.conf.backup ] && mv ~/.tmux.conf.backup ~/.tmux.conf

# Restore directories
[ -d ~/.config/nvim.backup ] && rm -rf ~/.config/nvim && mv ~/.config/nvim.backup ~/.config/nvim

# Restore editor settings
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
else
    VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
fi
[ -f "$VSCODE_SETTINGS.backup" ] && mv "$VSCODE_SETTINGS.backup" "$VSCODE_SETTINGS"
```

#### Complete Rollback (remove all dotfiles changes)

```bash
# Remove dotfiles symlinks
find ~ -maxdepth 3 -type l -exec sh -c '
    for link; do
        if readlink "$link" | grep -q "/.dotfiles/"; then
            echo "Removing: $link"
            rm "$link"
        fi
    done
' sh {} +

# Restore from manual backup
BACKUP_DIR=$(ls -td ~/.dotfiles-manual-backup-* 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Restoring from: $BACKUP_DIR"
    cp -r "$BACKUP_DIR"/* ~ 2>/dev/null || true
fi

# Reset shell to bash
chsh -s /bin/bash

# Remove dotfiles directory
rm -rf ~/.dotfiles
```

### Rollback Validation

- [ ] **Shell functions normally**: Test basic shell operations
- [ ] **Original configurations restored**: Verify files match pre-installation state
- [ ] **No broken symlinks remain**: `find ~ -type l -exec test ! -e {} \; -print`
- [ ] **System stability confirmed**: No errors or crashes

### Remote Rollback

For remote systems, execute rollback via SSH:

```bash
ssh user@remote-host 'cd ~/.dotfiles && ./scripts/rollback.sh'
```

## Emergency Recovery

### System Recovery Scenarios

#### Scenario 1: Shell becomes unusable

```bash
# Connect with bash explicitly
ssh -t user@remote-host bash

# Or use emergency shell reset
ssh user@remote-host 'chsh -s /bin/bash && rm ~/.zshrc'
```

#### Scenario 2: SSH connection broken

- **Use console access** (physical or virtual console)
- **Boot from recovery mode** if system won't start
- **Use single-user mode** to access filesystem

#### Scenario 3: System won't boot

```bash
# Boot from recovery/rescue mode
# Mount filesystem
# Remove problematic configurations
rm -f /home/user/.zshrc /home/user/.config/nvim
# Restore from backup
cp /home/user/.dotfiles-manual-backup-*/* /home/user/
```

### Emergency Contact Information

- **Repository Issues**: https://github.com/akgoode/dotfiles/issues
- **Documentation**: https://github.com/akgoode/dotfiles/blob/main/README.md
- **Emergency Procedures**: This document

### Recovery Validation Checklist

- [ ] **System boots successfully**
- [ ] **User can log in**
- [ ] **Basic shell functionality works**
- [ ] **Critical applications accessible**
- [ ] **Network connectivity restored**

## Troubleshooting Quick Reference

### Common Issues and Solutions

| Issue                   | Symptoms                                  | Quick Fix                                       |
| ----------------------- | ----------------------------------------- | ----------------------------------------------- |
| Permission denied       | Installation fails with permission errors | Check sudo access: `sudo -v`                    |
| Network timeout         | Downloads fail or hang                    | Test connectivity: `curl -I https://github.com` |
| Symlink conflicts       | "File exists" errors                      | Backup manually: `mv ~/.zshrc ~/.zshrc.manual`  |
| Shell errors            | zsh won't start or has errors             | Check syntax: `zsh -n ~/.zshrc`                 |
| Missing tools           | Commands not found after install          | Check PATH: `echo $PATH`                        |
| Homebrew issues (macOS) | Package installation fails                | Install Xcode tools: `xcode-select --install`   |

### Diagnostic Commands

```bash
# System information
uname -a && cat /etc/os-release

# Installation status
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim

# Shell configuration test
zsh -c "source ~/.zshrc && echo 'Config OK'"

# Tool availability
command -v git nvim tmux zsh

# Network connectivity
curl -I https://github.com

# Disk space
df -h $HOME

# Process status
ps aux | grep -E "(install|brew|apt)"
```

## Final Checklist

### Deployment Success Criteria

- [ ] **All validation tests pass**
- [ ] **No critical errors in logs**
- [ ] **User can perform daily development tasks**
- [ ] **System performance is acceptable**
- [ ] **Backup and rollback procedures tested**

### Documentation and Handoff

- [ ] **Deployment log saved** and accessible
- [ ] **Any issues documented** for future reference
- [ ] **User training completed** (if required)
- [ ] **Support contacts provided**
- [ ] **Monitoring setup** (if applicable)

### Post-Deployment Tasks

- [ ] **Remove temporary files** and old backups (after confirmation)
- [ ] **Update deployment documentation** with lessons learned
- [ ] **Schedule follow-up validation** (24-48 hours later)
- [ ] **Collect user feedback** on deployment experience

---

**Remember**: Always test in a non-production environment first, maintain current backups, and have a rollback plan ready before deploying to critical systems.
