# Dotfiles Plan

Cross-platform (macOS + Ubuntu/Debian) development environment for enterprise web, backend, cloud/terraform, and general development.

## Design Principles

- Minimal dependencies
- One-liner install: `curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/install.sh | bash`
- No cloud/AI dependencies in shell tooling
- Secrets kept out of repo (manual/gitignore)
- Existing configs preserved (nvim, vscode, kiro)

---

## Repository Structure

```
dotfiles/
├── install.sh                    # Entry point - detects OS, runs appropriate installer
├── Brewfile                      # macOS packages (Homebrew)
├── scripts/
│   ├── install-mac.sh            # macOS-specific setup
│   ├── install-linux.sh          # Ubuntu/Debian setup (apt)
│   └── common.sh                 # Shared functions (symlinks, backups)
├── shell/
│   ├── zshrc                     # Main zsh config
│   ├── aliases.zsh               # Git aliases (oh-my-zsh style)
│   └── starship.toml             # Prompt configuration
├── git/
│   └── gitconfig                 # Git configuration
├── editors/
│   ├── nvim/                     # Neovim config (lazy.nvim)
│   │   ├── init.lua
│   │   ├── lazy-lock.json
│   │   └── lua/
│   │       ├── vim-options.lua
│   │       └── plugins/
│   │           ├── lsp-config.lua
│   │           ├── git.lua
│   │           ├── telescope.lua
│   │           ├── debugging.lua
│   │           ├── theme.lua
│   │           ├── lualine.lua
│   │           ├── none-ls.lua
│   │           ├── utils.lua
│   │           ├── treesitter.lua
│   │           ├── harpoon.lua
│   │           ├── completions.lua
│   │           └── neotree.lua
│   ├── vscode/
│   │   ├── settings.json         # VS Code settings
│   │   └── extensions.txt        # Extension list for reinstall
│   └── kiro/
│       └── settings/
│           └── mcp.json          # Kiro MCP configuration
├── tmux/
│   └── tmux.conf                 # Minimal tmux config
└── claude/
    └── settings.json             # Claude Code config (MCP examples commented)
```

---

## Shell Setup

### Replacing Powerlevel10k with Starship

**Why:** Powerlevel10k's fancy rendering breaks AI code assistant terminal parsing. Starship outputs clean ANSI.

**starship.toml:**
```toml
# Minimal but powerful prompt
format = """
$directory\
$git_branch\
$git_status\
$nodejs\
$python\
$golang\
$dotnet\
$terraform\
$aws\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[❯](green)"
error_symbol = "[❯](red)"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "
format = "[$symbol$branch]($style) "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[nodejs]
symbol = " "
format = "[$symbol$version]($style) "

[python]
symbol = " "
format = "[$symbol$version]($style) "

[golang]
symbol = " "
format = "[$symbol$version]($style) "

[dotnet]
symbol = " "
format = "[$symbol$version]($style) "

[terraform]
symbol = "󱁢 "
format = "[$symbol$version]($style) "

[aws]
symbol = " "
format = "[$symbol$profile]($style) "

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "
```

### zshrc

```zsh
# Starship prompt
eval "$(starship init zsh)"

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Load aliases
source ~/.config/dotfiles/shell/aliases.zsh

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Editor
export EDITOR="nvim"
export VISUAL="code"

# Path additions
export PATH="$HOME/.local/bin:$PATH"

# Kiro shell integration (when in Kiro terminal)
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
```

### aliases.zsh (oh-my-zsh git style)

```zsh
# Git aliases (matching oh-my-zsh git plugin)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias glog='git log --oneline --decorate --graph'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gst='git status'
alias gsw='git switch'
alias gswc='git switch -c'

# Directory shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -la'

# Editor shortcuts
alias v='nvim'
alias c='code .'

# Kubernetes (matching existing alias style)
alias k='kubectl'

# Common dev commands
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
```

---

## Git Configuration

### gitconfig

```ini
[user]
    name = Andrew
    email = akgoode@gmail.com

[init]
    defaultBranch = main

[core]
    editor = nvim
    autocrlf = input
    excludesfile = ~/.gitignore_global

[pull]
    rebase = true

[push]
    default = current
    autoSetupRemote = true

[fetch]
    prune = true

[diff]
    colorMoved = default

[merge]
    conflictstyle = diff3

[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    lg = log --oneline --decorate --graph --all
```

---

## Package Management

### Brewfile (macOS)

```ruby
# Taps
tap "homebrew/bundle"

# CLI Tools
brew "awscli"
brew "coreutils"
brew "fd"
brew "git"
brew "go"
brew "jq"
brew "kubernetes-cli"
brew "neovim"
brew "nvm"
brew "postgresql@16"
brew "ripgrep"
brew "starship"
brew "terraform"
brew "tmux"
brew "tree"

# Casks (GUI Apps)
cask "claude"
cask "docker"
cask "firefox"
cask "google-chrome"
cask "iterm2"
cask "kiro"
cask "pgadmin4"
cask "postman"
cask "raycast"
cask "slack"
cask "visual-studio-code"
cask "zoom"
```

### install-linux.sh (Ubuntu/Debian)

```bash
#!/bin/bash
set -e

echo "Installing packages for Ubuntu/Debian..."

# Update package list
sudo apt update

# Essential tools
sudo apt install -y \
    build-essential \
    curl \
    fd-find \
    git \
    jq \
    neovim \
    postgresql-client \
    ripgrep \
    tmux \
    tree \
    unzip \
    wget \
    zsh

# Starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y

# NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Go (latest stable)
GO_VERSION="1.23.4"
wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"
export PATH=$PATH:/usr/local/go/bin

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# .NET SDK (optional - uncomment if needed)
# wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
# chmod +x dotnet-install.sh
# ./dotnet-install.sh --channel 8.0

echo "Linux package installation complete!"
```

---

## tmux Configuration

### tmux.conf (minimal)

```tmux
# Better prefix
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Mouse support
set -g mouse on

# Better split bindings
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Reload config
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# 256 colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# History
set -g history-limit 10000

# Faster escape time
set -sg escape-time 0

# Status bar
set -g status-style bg=default,fg=white
set -g status-left "#[fg=green]#S "
set -g status-right "#[fg=yellow]%H:%M"
```

---

## Claude Code Configuration

### claude/settings.json

```json
{
  // Core settings
  "theme": "dark",

  // Permissions - adjust as needed
  // "autoApproveTools": ["Read", "Glob", "Grep"],

  // MCP Servers (examples - uncomment and configure as needed)
  // "mcpServers": {
  //   "github": {
  //     "command": "npx",
  //     "args": ["-y", "@modelcontextprotocol/server-github"],
  //     "env": {
  //       "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token>"
  //     }
  //   },
  //   "filesystem": {
  //     "command": "npx",
  //     "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
  //   },
  //   "postgres": {
  //     "command": "npx",
  //     "args": ["-y", "@modelcontextprotocol/server-postgres"],
  //     "env": {
  //       "DATABASE_URL": "postgresql://user:pass@localhost:5432/db"
  //     }
  //   }
  // }

  // Deny specific MCP servers if needed
  // "deniedMcpServers": [
  //   { "serverName": "trello" }
  // ]
}
```

---

## VS Code Extensions

### vscode/extensions.txt

```
ahmadawais.shades-of-purple
alexcvzz.vscode-sqlite
amazonwebservices.aws-toolkit-vscode
bierner.color-info
bradlc.vscode-tailwindcss
dbaeumer.vscode-eslint
docker.docker
eamodio.gitlens
editorconfig.editorconfig
esbenp.prettier-vscode
formulahendry.auto-rename-tag
golang.go
hashicorp.terraform
ms-azuretools.vscode-containers
ms-azuretools.vscode-docker
ms-dotnettools.csharp
ms-dotnettools.vscode-dotnet-runtime
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-python.vscode-python-envs
ms-vscode-remote.remote-containers
ms-vscode-remote.remote-ssh
ms-vscode-remote.remote-ssh-edit
ms-vscode-remote.remote-wsl
ms-vscode-remote.vscode-remote-extensionpack
ms-vscode.remote-explorer
ms-vscode.remote-server
orta.vscode-jest
patcx.vscode-nuget-gallery
```

Install with: `cat extensions.txt | xargs -L 1 code --install-extension`

---

## Install Script

### install.sh

```bash
#!/bin/bash
set -e

DOTFILES_REPO="https://github.com/<user>/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

echo "================================================"
echo "  Dotfiles Installer"
echo "================================================"

# Clone or update repo
if [ -d "$DOTFILES_DIR" ]; then
    echo "Updating existing dotfiles..."
    cd "$DOTFILES_DIR" && git pull
else
    echo "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Detect OS and run appropriate installer
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"
    ./scripts/install-mac.sh
elif [[ -f /etc/debian_version ]]; then
    echo "Detected Debian/Ubuntu"
    ./scripts/install-linux.sh
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Run common setup (symlinks)
./scripts/common.sh

echo ""
echo "================================================"
echo "  Installation complete!"
echo "  Please restart your terminal."
echo "================================================"
```

### scripts/common.sh

```bash
#!/bin/bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"

backup_and_link() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    echo "Linking $dest -> $src"
    ln -s "$src" "$dest"
}

echo "Setting up symlinks..."

# Shell
mkdir -p ~/.config
backup_and_link "$DOTFILES_DIR/shell/zshrc" ~/.zshrc
backup_and_link "$DOTFILES_DIR/shell/starship.toml" ~/.config/starship.toml

# Git
backup_and_link "$DOTFILES_DIR/git/gitconfig" ~/.gitconfig

# Neovim
backup_and_link "$DOTFILES_DIR/editors/nvim" ~/.config/nvim

# VS Code (macOS path - adjust for Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_DIR="$HOME/.config/Code/User"
fi
mkdir -p "$VSCODE_DIR"
backup_and_link "$DOTFILES_DIR/editors/vscode/settings.json" "$VSCODE_DIR/settings.json"

# Kiro
mkdir -p ~/.kiro/settings
backup_and_link "$DOTFILES_DIR/editors/kiro/settings/mcp.json" ~/.kiro/settings/mcp.json

# tmux
backup_and_link "$DOTFILES_DIR/tmux/tmux.conf" ~/.tmux.conf

# Claude Code
mkdir -p ~/.claude
backup_and_link "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json

echo "Symlinks complete!"

# Install VS Code extensions
if command -v code &> /dev/null; then
    echo "Installing VS Code extensions..."
    cat "$DOTFILES_DIR/editors/vscode/extensions.txt" | xargs -L 1 code --install-extension || true
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi
```

### scripts/install-mac.sh

```bash
#!/bin/bash
set -e

echo "Running macOS setup..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install packages from Brewfile
echo "Installing Homebrew packages..."
brew bundle --file="$HOME/.dotfiles/Brewfile"

# Install Node via NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
nvm install --lts
nvm use --lts

echo "macOS setup complete!"
```

---

## Files to Copy from Current Machine

These files should be copied directly from the current machine:

1. **Neovim config:** `~/.config/nvim/` → `editors/nvim/`
2. **VS Code settings:** `~/Library/Application Support/Code/User/settings.json` → `editors/vscode/settings.json`
3. **Kiro MCP config:** `~/.kiro/settings/mcp.json` → `editors/kiro/settings/mcp.json`

---

## Post-Install Manual Steps

1. **Set up Git credentials:** `git config --global credential.helper osxkeychain` (macOS) or configure SSH keys
2. **Configure AWS:** `aws configure`
3. **Log in to Docker:** `docker login`
4. **Install Kiro extensions:** Open Kiro and sync extensions
5. **Configure Claude Code MCP servers:** Edit `~/.claude/settings.json` and uncomment desired servers

---

## Future Considerations

- [ ] Add dev container support (`.devcontainer/`)
- [ ] Add GitHub Codespaces config
- [ ] Consider chezmoi for templating (machine-specific configs)
- [ ] Add Ansible playbook as alternative to shell scripts
- [ ] Add pre-commit hooks config
