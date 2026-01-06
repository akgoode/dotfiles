# Cross-Platform Dotfiles Comparison Results

Generated on: Mon Jan  5 21:30:13 CST 2026
Platform: macos
Architecture: arm64
Container Mode: false


## Platform Detection

- ℹ️ **INFO**: Platform detected
  - Details: macos
- ℹ️ **INFO**: Architecture detected
  - Details: arm64
- ℹ️ **INFO**: Package manager
  - Details: Homebrew
- ℹ️ **INFO**: VS Code config path
  - Details: /Users/andrew/Library/Application Support/Code/User
- ℹ️ **INFO**: Shell change method
  - Details: chsh (standard)

## Package Manager Check

- ✅ **PASS**: Homebrew available
  - Details: Homebrew 5.0.8

## Tool Versions

- ✅ **PASS**: git installed
  - Details: git version 2.50.1 (Apple Git-155)
- ✅ **PASS**: nvim installed
  - Details: NVIM v0.11.5
- ❌ **FAIL**: tmux not found
- ✅ **PASS**: jq installed
  - Details: jq-1.7.1-apple
- ✅ **PASS**: rg installed
  - Details: ripgrep 15.1.0
- ✅ **PASS**: fd installed
  - Details: fd 10.3.0
- ✅ **PASS**: go installed
  - Details: go version go1.25.5 darwin/arm64
- ✅ **PASS**: terraform installed
  - Details: Terraform v1.5.7
- ✅ **PASS**: aws installed
  - Details: aws-cli/2.32.22 Python/3.13.11 Darwin/25.2.0 source/arm64
- ✅ **PASS**: kubectl installed
  - Details: Client Version: v1.35.0
- ✅ **PASS**: node installed
  - Details: v20.19.0
- ✅ **PASS**: npm installed
  - Details: 10.8.2

## Command Equivalence

- ✅ **PASS**: fd command available
- ✅ **PASS**: ripgrep (rg) available

## Symlink Verification

- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.zshrc -> /Users/andrew/.dotfiles/shell/zshrc (expected: /Users/andrew/projects/dotfiles/shell/zshrc)
- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.gitconfig -> /Users/andrew/.dotfiles/git/gitconfig (expected: /Users/andrew/projects/dotfiles/git/gitconfig)
- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.config/nvim -> /Users/andrew/.dotfiles/editors/nvim (expected: /Users/andrew/projects/dotfiles/editors/nvim)
- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.tmux.conf -> /Users/andrew/.dotfiles/tmux/tmux.conf (expected: /Users/andrew/projects/dotfiles/tmux/tmux.conf)
- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.config/dotfiles/shell/aliases.zsh -> /Users/andrew/.dotfiles/shell/aliases.zsh (expected: /Users/andrew/projects/dotfiles/shell/aliases.zsh)
- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.claude/settings.json -> /Users/andrew/.dotfiles/claude/settings.json (expected: /Users/andrew/projects/dotfiles/claude/settings.json)
- ❌ **FAIL**: Symlink incorrect: /Users/andrew/.kiro/settings/mcp.json -> /Users/andrew/.dotfiles/editors/kiro/settings/mcp.json (expected: /Users/andrew/projects/dotfiles/editors/kiro/settings/mcp.json)

## VS Code Configuration

- ✅ **PASS**: VS Code settings symlinked
  - Details: /Users/andrew/Library/Application Support/Code/User/settings.json
- ℹ️ **INFO**: VS Code directory path
  - Details: /Users/andrew/Library/Application Support/Code/User

## Shell Functionality

- ❌ **FAIL**: zsh configuration has errors
- ❌ **FAIL**: Git aliases not available
- ⚠️ **WARNING**: Go PATH not configured (may be expected if Go not installed)
- ⚠️ **WARNING**: NVM not available (may be expected)

## File Permissions

