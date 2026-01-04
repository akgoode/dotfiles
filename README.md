# Dotfiles

Cross-platform (macOS + Ubuntu/Debian) development environment for enterprise web, backend, cloud/terraform, and general development.

## Quick Start

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/akgoode/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## What's Included

### Shell
- **Zsh** with [Starship](https://starship.rs/) prompt (clean ANSI output, works well with AI assistants)
- Git aliases matching oh-my-zsh style (`gst`, `gco`, `gcm`, etc.)
- NVM for Node.js version management

### Editors
- **Neovim** with lazy.nvim plugin manager
  - LSP support (TypeScript, Python, Go, Lua, Terraform, Rego)
  - Treesitter for syntax highlighting
  - Telescope for fuzzy finding
  - Neo-tree for file explorer
  - Harpoon for quick file navigation
  - Git integration (Gitsigns, Fugitive)
  - Debugging support (DAP)
- **VS Code** settings and extensions
- **Kiro** MCP configuration

### Git
- Sensible defaults (rebase on pull, prune on fetch)
- Useful aliases (`lg`, `unstage`, `last`)

### Terminal Multiplexer
- **tmux** with vim-style navigation and sensible keybindings

### Package Management
- **Homebrew** (macOS) - CLI tools and GUI apps
- **apt** (Ubuntu/Debian) - System packages with manual installs for latest versions

## Repository Structure

```
dotfiles/
├── install.sh                    # Entry point - detects OS, runs installer
├── Brewfile                      # macOS packages (Homebrew)
├── scripts/
│   ├── install-mac.sh            # macOS-specific setup
│   ├── install-linux.sh          # Ubuntu/Debian setup (apt)
│   └── common.sh                 # Shared functions (symlinks, backups)
├── shell/
│   ├── zshrc                     # Main zsh config
│   ├── aliases.zsh               # Git and command aliases
│   └── starship.toml             # Prompt configuration
├── git/
│   └── gitconfig                 # Git configuration
├── editors/
│   ├── nvim/                     # Neovim config (lazy.nvim)
│   ├── vscode/
│   │   ├── settings.json         # VS Code settings
│   │   └── extensions.txt        # Extension list
│   └── kiro/
│       └── settings/
│           └── mcp.json          # Kiro MCP configuration
├── tmux/
│   └── tmux.conf                 # tmux configuration
└── claude/
    └── settings.json             # Claude Code config
```

## Installed Software

### macOS (via Homebrew)

**CLI Tools:**
- awscli, coreutils, fd, git, go, jq
- kubernetes-cli, neovim, nvm, postgresql@16
- ripgrep, starship, terraform, tmux, tree

**GUI Apps:**
- Claude, Docker, Firefox, Google Chrome
- iTerm2, Kiro, pgAdmin4, Postman
- Raycast, Slack, VS Code, Zoom

### Ubuntu/Debian

**System Packages:**
- build-essential, curl, fd-find, git, jq
- neovim, postgresql-client, ripgrep
- tmux, tree, unzip, wget, zsh

**Manual Installs:**
- Starship prompt
- NVM + Node.js LTS
- Go 1.23.4
- Terraform
- AWS CLI v2
- kubectl

## Key Bindings

### Neovim

| Binding | Action |
|---------|--------|
| `<Space>` | Leader key |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep |
| `<leader>n` | Toggle file tree |
| `<leader>a` | Add to Harpoon |
| `<C-e>` | Harpoon quick menu |
| `<leader>gd` | Go to definition |
| `<leader>gr` | Find references |
| `<leader>.` | Code actions |
| `<leader>H` | Hover documentation |
| `jk` | Exit insert mode |
| `J` / `K` | Move 5 lines down/up |

### tmux

| Binding | Action |
|---------|--------|
| `Ctrl-a` | Prefix (instead of Ctrl-b) |
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + r` | Reload config |

### Git Aliases

| Alias | Command |
|-------|---------|
| `gst` | `git status` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gcm` | `git commit -m` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git pull` |
| `gp` | `git push` |
| `gpf` | `git push --force-with-lease` |
| `glog` | `git log --oneline --decorate --graph` |

## Post-Install Steps

After installation, complete these manual steps:

1. **Git credentials:**
   ```bash
   # macOS
   git config --global credential.helper osxkeychain

   # Or configure SSH keys
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **AWS configuration:**
   ```bash
   aws configure
   ```

3. **Docker login:**
   ```bash
   docker login
   ```

4. **Install Node.js LTS:**
   ```bash
   nvm install --lts
   nvm use --lts
   ```

## Updating

To update your dotfiles:

```bash
cd ~/.dotfiles
git pull
./scripts/common.sh  # Re-run symlinks
```

## Customization

### Adding packages (macOS)

Edit `Brewfile` and run:
```bash
brew bundle --file=~/.dotfiles/Brewfile
```

### Adding VS Code extensions

Add extension ID to `editors/vscode/extensions.txt` and run:
```bash
cat ~/.dotfiles/editors/vscode/extensions.txt | xargs -L 1 code --install-extension
```

### Modifying aliases

Edit `shell/aliases.zsh` - changes take effect on new terminal sessions or run:
```bash
source ~/.zshrc
```

## Backup Strategy

The installer automatically backs up existing configs:
- Existing files are renamed to `<filename>.backup`
- Symlinks are replaced without backup

To restore a backup:
```bash
mv ~/.zshrc.backup ~/.zshrc
```

## Design Principles

- **Minimal dependencies** - No heavy frameworks
- **Cross-platform** - Works on macOS and Ubuntu/Debian
- **No cloud/AI in shell** - Starship over Powerlevel10k for clean terminal output
- **Secrets out of repo** - Use environment variables or local gitignored files
- **Preserves existing configs** - Backup before overwrite

## Troubleshooting

### Starship not showing

Ensure your terminal supports Unicode and has a [Nerd Font](https://www.nerdfonts.com/) installed.

### NVM not found

Restart your terminal or run:
```bash
source ~/.zshrc
```

### Permission denied on scripts

```bash
chmod +x ~/.dotfiles/install.sh ~/.dotfiles/scripts/*.sh
```

### Neovim plugins not loading

Open Neovim and run:
```vim
:Lazy sync
```

## License

MIT
