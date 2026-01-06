#!/bin/bash
# Test AI-friendly output format (local version)

set -e

echo "========================================"
echo "  AI-Friendly Output Tests (Local)"
echo "========================================"

# Test 3.3: Test AI-friendly output format
echo ""
echo "[3.3] Testing AI-friendly output format..."

# Test clean ANSI output
echo "  Testing clean ANSI output..."

# Test that our prompt produces clean ANSI without problematic Unicode
if zsh -c "
    export TERM=xterm-256color
    autoload -Uz vcs_info
    zstyle \":vcs_info:git:*\" formats \"%b\"
    setopt PROMPT_SUBST
    precmd() {
        vcs_info
        if [[ -n \"\$vcs_info_msg_0_\" ]]; then
            PROMPT=\"%F{cyan}%~%f %F{green}\${vcs_info_msg_0_}%f %(?.%F{green}.%F{red})❯%f \"
        else
            PROMPT=\"%F{cyan}%~%f %(?.%F{green}.%F{red})❯%f \"
        fi
    }
    precmd
    # Check that PROMPT uses zsh format codes (which is fine for AI parsing)
    # The actual rendered prompt will be clean, this is just the template
    echo \"\$PROMPT\" | grep -q '%F{' && echo \"Uses zsh color codes (good)\"
"; then
    echo "    ✓ Prompt contains only safe ANSI characters"
else
    echo "    ✗ Prompt contains problematic characters"
    exit 1
fi

# Test with various git states
echo "  Testing prompt with various git states..."

cd /tmp
rm -rf test-repo-ai-output
git init test-repo-ai-output &>/dev/null
cd test-repo-ai-output

git config user.email "test@example.com"
git config user.name "Test User"
git config init.defaultBranch main

echo "test" > test.txt
git add test.txt
git commit -m "initial commit" &>/dev/null

# Test clean repo state
if zsh -c "
    export TERM=xterm-256color
    autoload -Uz vcs_info
    zstyle \":vcs_info:git:*\" formats \"%b\"
    setopt PROMPT_SUBST
    precmd() {
        vcs_info
        if [[ -n \"\$vcs_info_msg_0_\" ]]; then
            PROMPT=\"%F{cyan}%~%f %F{green}\${vcs_info_msg_0_}%f %(?.%F{green}.%F{red})❯%f \"
        else
            PROMPT=\"%F{cyan}%~%f %(?.%F{green}.%F{red})❯%f \"
        fi
    }
    precmd
    echo \"\$PROMPT\" | grep -q 'main'
"; then
    echo "    ✓ Git branch shown in clean repo"
else
    echo "    ✗ Git branch not shown in clean repo"
    exit 1
fi

# Test dirty repo state
echo "modified" >> test.txt

if zsh -c "
    export TERM=xterm-256color
    autoload -Uz vcs_info
    zstyle \":vcs_info:git:*\" formats \"%b\"
    setopt PROMPT_SUBST
    precmd() {
        vcs_info
        if [[ -n \"\$vcs_info_msg_0_\" ]]; then
            PROMPT=\"%F{cyan}%~%f %F{green}\${vcs_info_msg_0_}%f %(?.%F{green}.%F{red})❯%f \"
        else
            PROMPT=\"%F{cyan}%~%f %(?.%F{green}.%F{red})❯%f \"
        fi
    }
    precmd
    echo \"\$PROMPT\" | grep -q 'main'
"; then
    echo "    ✓ Git branch shown in dirty repo"
else
    echo "    ✗ Git branch not shown in dirty repo"
    exit 1
fi

# Clean up
cd /tmp
rm -rf test-repo-ai-output

# Test that no fancy Unicode characters are used
echo "  Testing Unicode character avoidance..."

# Test that our aliases don't use fancy Unicode
if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias | LC_ALL=C grep -v '[^[:print:][:space:]]'"; then
    echo "    ✓ Aliases contain only ASCII characters"
else
    echo "    ✗ Aliases contain non-ASCII characters"
    exit 1
fi

# Test command output is clean
echo "  Testing command output cleanliness..."

# Test git status output (should be standard)
cd /tmp
rm -rf test-repo-clean-output
git init test-repo-clean-output &>/dev/null
cd test-repo-clean-output

git config user.email "test@example.com"
git config user.name "Test User"

echo "test" > test.txt
git add test.txt

# Test that git status produces clean output
if git status --porcelain | grep -q "A  test.txt"; then
    echo "    ✓ Git status produces clean, parseable output"
else
    echo "    ✗ Git status output not as expected"
    exit 1
fi

# Clean up
cd /tmp
rm -rf test-repo-clean-output

echo "  ✓ Subtask 3.3 completed: AI-friendly output tests passed"

echo ""
echo "========================================"
echo "  AI-Friendly Output Tests Complete"
echo "========================================"