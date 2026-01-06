#!/bin/bash
# Cross-platform comparison script for dotfiles deployment
# Tests and documents differences between macOS and Linux behavior

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPARISON_LOG="$SCRIPT_DIR/platform-comparison-results.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
    echo -e "\n## $1\n" >> "$COMPARISON_LOG"
}

log_result() {
    local status="$1"
    local message="$2"
    local details="$3"
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✓${NC} $message"
            echo "- ✅ **PASS**: $message" >> "$COMPARISON_LOG"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            echo "- ❌ **FAIL**: $message" >> "$COMPARISON_LOG"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            echo "- ⚠️ **WARNING**: $message" >> "$COMPARISON_LOG"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            echo "- ℹ️ **INFO**: $message" >> "$COMPARISON_LOG"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "  $details"
        echo "  - Details: $details" >> "$COMPARISON_LOG"
    fi
}

detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

get_architecture() {
    uname -m
}

check_package_manager() {
    local platform="$1"
    
    case "$platform" in
        "macos")
            if command -v brew &> /dev/null; then
                log_result "PASS" "Homebrew available" "$(brew --version | head -1)"
            else
                log_result "FAIL" "Homebrew not found"
            fi
            ;;
        "linux")
            if command -v apt &> /dev/null; then
                log_result "PASS" "APT available" "$(apt --version | head -1)"
            else
                log_result "FAIL" "APT not found"
            fi
            ;;
    esac
}

check_tool_versions() {
    local tools=("git" "nvim" "tmux" "jq" "rg" "fd" "go" "terraform" "aws" "kubectl" "node" "npm")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=""
            case "$tool" in
                "git") version=$(git --version) ;;
                "nvim") version=$(nvim --version | head -1) ;;
                "tmux") version=$(tmux -V) ;;
                "jq") version=$(jq --version) ;;
                "rg") version=$(rg --version | head -1) ;;
                "fd") version=$(fd --version 2>/dev/null || fdfind --version 2>/dev/null || echo "fd variant") ;;
                "go") version=$(go version) ;;
                "terraform") version=$(terraform version | head -1) ;;
                "aws") version=$(aws --version) ;;
                "kubectl") version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1) ;;
                "node") version=$(node --version) ;;
                "npm") version=$(npm --version) ;;
            esac
            log_result "PASS" "$tool installed" "$version"
        else
            log_result "FAIL" "$tool not found"
        fi
    done
}

check_symlinks() {
    local expected_links=(
        "$HOME/.zshrc:$DOTFILES_DIR/shell/zshrc"
        "$HOME/.gitconfig:$DOTFILES_DIR/git/gitconfig"
        "$HOME/.config/nvim:$DOTFILES_DIR/editors/nvim"
        "$HOME/.tmux.conf:$DOTFILES_DIR/tmux/tmux.conf"
        "$HOME/.config/dotfiles/shell/aliases.zsh:$DOTFILES_DIR/shell/aliases.zsh"
        "$HOME/.claude/settings.json:$DOTFILES_DIR/claude/settings.json"
        "$HOME/.kiro/settings/mcp.json:$DOTFILES_DIR/editors/kiro/settings/mcp.json"
    )
    
    for link_spec in "${expected_links[@]}"; do
        local target="${link_spec%:*}"
        local source="${link_spec#*:}"
        
        if [ -L "$target" ]; then
            local actual_source=$(readlink "$target")
            if [ "$actual_source" = "$source" ]; then
                log_result "PASS" "Symlink correct: $target -> $source"
            else
                log_result "FAIL" "Symlink incorrect: $target -> $actual_source (expected: $source)"
            fi
        else
            log_result "FAIL" "Missing symlink: $target"
        fi
    done
}

check_vscode_config() {
    local platform="$1"
    local vscode_dir=""
    
    case "$platform" in
        "macos")
            vscode_dir="$HOME/Library/Application Support/Code/User"
            ;;
        "linux")
            vscode_dir="$HOME/.config/Code/User"
            ;;
    esac
    
    if [ -n "$vscode_dir" ]; then
        local settings_file="$vscode_dir/settings.json"
        if [ -L "$settings_file" ]; then
            log_result "PASS" "VS Code settings symlinked" "$settings_file"
        else
            log_result "FAIL" "VS Code settings not symlinked" "$settings_file"
        fi
        
        log_result "INFO" "VS Code directory path" "$vscode_dir"
    fi
}

check_shell_functionality() {
    # Test zsh configuration loading
    if zsh -c "source ~/.zshrc && echo 'zsh config loaded'" &>/dev/null; then
        log_result "PASS" "zsh configuration loads without errors"
    else
        log_result "FAIL" "zsh configuration has errors"
    fi
    
    # Test git aliases
    if zsh -c "source ~/.config/dotfiles/shell/aliases.zsh && alias gst" &>/dev/null; then
        log_result "PASS" "Git aliases available"
    else
        log_result "FAIL" "Git aliases not available"
    fi
    
    # Test PATH additions
    if zsh -c "source ~/.zshrc && echo \$PATH | grep -q '/usr/local/go/bin'" &>/dev/null; then
        log_result "PASS" "Go PATH configured"
    else
        log_result "WARN" "Go PATH not configured (may be expected if Go not installed)"
    fi
    
    # Test NVM availability
    if zsh -c "source ~/.zshrc && command -v nvm" &>/dev/null; then
        log_result "PASS" "NVM available in shell"
    else
        log_result "WARN" "NVM not available (may be expected)"
    fi
}

check_file_permissions() {
    local files=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local perms=$(ls -l "$file" | cut -d' ' -f1)
            log_result "INFO" "File permissions: $file" "$perms"
        fi
    done
}

test_command_equivalence() {
    # Test fd vs fdfind (Linux uses fdfind, macOS uses fd)
    if command -v fd &> /dev/null; then
        log_result "PASS" "fd command available"
    elif command -v fdfind &> /dev/null; then
        log_result "PASS" "fdfind command available (Linux variant)"
    else
        log_result "FAIL" "Neither fd nor fdfind available"
    fi
    
    # Test ripgrep
    if command -v rg &> /dev/null; then
        log_result "PASS" "ripgrep (rg) available"
    else
        log_result "FAIL" "ripgrep not available"
    fi
}

document_platform_differences() {
    local platform="$1"
    local arch="$2"
    
    log_result "INFO" "Platform detected" "$platform"
    log_result "INFO" "Architecture detected" "$arch"
    
    case "$platform" in
        "macos")
            log_result "INFO" "Package manager" "Homebrew"
            log_result "INFO" "VS Code config path" "$HOME/Library/Application Support/Code/User"
            log_result "INFO" "Shell change method" "chsh (standard)"
            ;;
        "linux")
            log_result "INFO" "Package manager" "APT + manual downloads"
            log_result "INFO" "VS Code config path" "$HOME/.config/Code/User"
            log_result "INFO" "Shell change method" "chsh or /etc/passwd modification"
            log_result "INFO" "fd command variant" "fdfind"
            ;;
    esac
}

run_docker_comparison() {
    echo "Starting Docker container for Linux comparison..."
    
    # Build and start container
    cd "$DOTFILES_DIR"
    
    # Try docker compose first (newer), then docker-compose (older)
    if command -v "docker" &> /dev/null; then
        if docker compose version &> /dev/null; then
            docker compose -f test/docker-compose.yml up -d --build
        elif command -v "docker-compose" &> /dev/null; then
            docker-compose -f test/docker-compose.yml up -d --build
        else
            echo "Neither 'docker compose' nor 'docker-compose' available. Skipping Docker comparison."
            return 1
        fi
    else
        echo "Docker not available. Skipping Docker comparison."
        return 1
    fi
    
    # Wait for container to be ready
    sleep 5
    
    # Run installation in container
    echo "Running installation in Docker container..."
    docker exec -u testuser dotfiles-test bash -c "cd ~/.dotfiles && ./scripts/install-linux.sh" || true
    docker exec -u testuser dotfiles-test bash -c "cd ~/.dotfiles && ./scripts/common.sh"
    
    # Run comparison tests in container
    echo "Running comparison tests in Docker container..."
    docker exec -u testuser dotfiles-test bash -c "cd ~/.dotfiles && ./test/cross-platform-comparison.sh --container-mode"
    
    # Copy results from container
    docker cp dotfiles-test:/home/testuser/.dotfiles/test/platform-comparison-results.md "$SCRIPT_DIR/linux-comparison-results.md"
    
    # Clean up
    if docker compose version &> /dev/null; then
        docker compose -f test/docker-compose.yml down
    else
        docker-compose -f test/docker-compose.yml down
    fi
}

main() {
    local container_mode=false
    
    # Check if running in container mode
    if [[ "$1" == "--container-mode" ]]; then
        container_mode=true
    fi
    
    # Initialize comparison log
    cat > "$COMPARISON_LOG" << EOF
# Cross-Platform Dotfiles Comparison Results

Generated on: $(date)
Platform: $(detect_platform)
Architecture: $(get_architecture)
Container Mode: $container_mode

EOF

    local platform=$(detect_platform)
    local arch=$(get_architecture)
    
    log_section "Platform Detection"
    document_platform_differences "$platform" "$arch"
    
    log_section "Package Manager Check"
    check_package_manager "$platform"
    
    log_section "Tool Versions"
    check_tool_versions
    
    log_section "Command Equivalence"
    test_command_equivalence
    
    log_section "Symlink Verification"
    check_symlinks
    
    log_section "VS Code Configuration"
    check_vscode_config "$platform"
    
    log_section "Shell Functionality"
    check_shell_functionality
    
    log_section "File Permissions"
    check_file_permissions
    
    echo -e "\n${GREEN}Cross-platform comparison complete!${NC}"
    echo "Results saved to: $COMPARISON_LOG"
    
    # If not in container mode and on macOS, also run Docker comparison
    if [[ "$container_mode" == false && "$platform" == "macos" ]]; then
        echo -e "\n${BLUE}Running Docker comparison for Linux behavior...${NC}"
        run_docker_comparison
        
        echo -e "\n${GREEN}Full cross-platform comparison complete!${NC}"
        echo "macOS results: $COMPARISON_LOG"
        echo "Linux results: $SCRIPT_DIR/linux-comparison-results.md"
    fi
}

# Run main function with all arguments
main "$@"