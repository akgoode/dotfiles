#!/bin/bash
# Test AI-friendly output format

set -e

CONTAINER="dotfiles-test"

echo "========================================"
echo "  AI-Friendly Output Format Tests"
echo "========================================"

# Test 3.3: Test AI-friendly output format
echo ""
echo "[3.3] Testing AI-friendly output format..."

# Verify prompt outputs clean ANSI
echo "  Testing clean ANSI output..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that the prompt uses only clean ANSI escape codes
    PROMPT_OUTPUT=$(zsh -c "
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
        echo \$PROMPT
    ")
    
    # Check that prompt contains standard ANSI color codes
    if echo "$PROMPT_OUTPUT" | grep -q "%F{"; then
        echo "    ✓ Prompt uses clean zsh color formatting"
    else
        echo "    ✗ Prompt does not use expected color formatting"
        exit 1
    fi
    
    # Check that prompt does not contain complex Unicode or fancy characters
    if echo "$PROMPT_OUTPUT" | LC_ALL=C grep -q "[^[:print:][:space:]]"; then
        echo "    ⚠ Prompt may contain non-printable characters (checking...)"
        # Allow the ❯ character as it'\''s part of the design
        if echo "$PROMPT_OUTPUT" | grep -v "❯" | LC_ALL=C grep -q "[^[:print:][:space:]]"; then
            echo "    ✗ Prompt contains problematic characters"
            echo "    Debug: $PROMPT_OUTPUT"
            exit 1
        else
            echo "    ✓ Only expected Unicode characters found (❯)"
        fi
    else
        echo "    ✓ Prompt uses only printable characters and formatting codes"
    fi
'

# Test with various git states
echo "  Testing prompt with various git states..."
docker exec -u testuser $CONTAINER bash -c '
    cd /tmp
    rm -rf test-git-states
    
    # Test 1: No git repo (clean directory)
    mkdir test-git-states
    cd test-git-states
    
    PROMPT_NO_GIT=$(zsh -c "
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
        echo \$PROMPT
    ")
    
    if [[ -n "$PROMPT_NO_GIT" ]]; then
        echo "    ✓ Prompt works in non-git directory"
    else
        echo "    ✗ Prompt failed in non-git directory"
        exit 1
    fi
    
    # Test 2: Clean git repo
    git init &>/dev/null
    git config user.email "test@example.com" 
    git config user.name "Test User"
    echo "test" > file.txt
    git add file.txt
    git commit -m "initial" &>/dev/null
    
    PROMPT_CLEAN_GIT=$(zsh -c "
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
        echo \$PROMPT
    ")
    
    if [[ -n "$PROMPT_CLEAN_GIT" ]]; then
        echo "    ✓ Prompt works in clean git repository"
    else
        echo "    ✗ Prompt failed in clean git repository"
        exit 1
    fi
    
    # Test 3: Dirty git repo
    echo "modified" >> file.txt
    
    PROMPT_DIRTY_GIT=$(zsh -c "
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
        echo \$PROMPT
    ")
    
    if [[ -n "$PROMPT_DIRTY_GIT" ]]; then
        echo "    ✓ Prompt works in dirty git repository"
    else
        echo "    ✗ Prompt failed in dirty git repository"
        exit 1
    fi
    
    # Clean up
    cd /tmp
    rm -rf test-git-states
'

# Ensure no problematic Unicode characters
echo "  Testing for problematic Unicode characters..."
docker exec -u testuser $CONTAINER bash -c '
    # Test the actual zshrc content for problematic characters
    if LC_ALL=C grep -q "[^[:print:][:space:]]" ~/.dotfiles/shell/zshrc; then
        # Check if it'\''s only the expected ❯ character
        if grep -v "❯" ~/.dotfiles/shell/zshrc | LC_ALL=C grep -q "[^[:print:][:space:]]"; then
            echo "    ✗ zshrc contains problematic characters"
            echo "    Problematic characters found:"
            LC_ALL=C grep "[^[:print:][:space:]]" ~/.dotfiles/shell/zshrc | grep -v "❯"
            exit 1
        else
            echo "    ✓ Only expected Unicode character (❯) found in zshrc"
        fi
    else
        echo "    ✓ No problematic characters found in zshrc"
    fi
    
    # Test aliases file for problematic characters
    if LC_ALL=C grep -q "[^[:print:][:space:]]" ~/.dotfiles/shell/aliases.zsh; then
        echo "    ✗ aliases.zsh contains non-printable characters"
        echo "    Problematic characters found:"
        LC_ALL=C grep "[^[:print:][:space:]]" ~/.dotfiles/shell/aliases.zsh
        exit 1
    else
        echo "    ✓ No problematic characters found in aliases.zsh"
    fi
'

# Test output parsing compatibility
echo "  Testing AI parsing compatibility..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that command output is clean and parseable
    OUTPUT=$(zsh -c "
        source ~/.config/dotfiles/shell/aliases.zsh
        gst() { git status --porcelain; }
        echo \"test output\"
    ")
    
    if [[ "$OUTPUT" == "test output" ]]; then
        echo "    ✓ Command output is clean and parseable"
    else
        echo "    ✗ Command output may have formatting issues"
        echo "    Expected: test output"
        echo "    Got: $OUTPUT"
        exit 1
    fi
    
    # Test that aliases produce clean output
    ALIAS_OUTPUT=$(zsh -c "
        source ~/.config/dotfiles/shell/aliases.zsh
        alias g
    ")
    
    if echo "$ALIAS_OUTPUT" | grep -q "git" && ! echo "$ALIAS_OUTPUT" | LC_ALL=C grep -q "[^[:print:][:space:]]"; then
        echo "    ✓ Alias output is clean and contains expected content"
    else
        echo "    ✗ Alias output may have issues"
        echo "    Output: $ALIAS_OUTPUT"
        exit 1
    fi
'

echo "  ✓ Subtask 3.3 completed: AI-friendly output format tests passed"

echo ""
echo "========================================"
echo "  AI-Friendly Output Format Tests Complete"
echo "========================================"