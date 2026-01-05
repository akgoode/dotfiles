#!/bin/bash
# Pre-deployment requirements checker for dotfiles installation
# Requirements: 6.3, 1.4

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REQUIREMENTS_MET=0
WARNINGS_COUNT=0

echo "========================================"
echo "  Dotfiles Pre-Deployment Requirements Check"
echo "========================================"
echo ""

log_result() {
    local status="$1"
    local message="$2"
    local details="$3"
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            REQUIREMENTS_MET=1
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            WARNINGS_COUNT=$((WARNINGS_COUNT + 1))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "  $details"
    fi
}

check_os_support() {
    echo "Checking operating system support..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
        log_result "PASS" "macOS detected" "Version: $macos_version"
        
        # Check macOS version (require 10.15+)
        if [[ "$macos_version" != "unknown" ]]; then
            local major_version=$(echo "$macos_version" | cut -d. -f1)
            local minor_version=$(echo "$macos_version" | cut -d. -f2)
            
            if [ "$major_version" -gt 10 ] || ([ "$major_version" -eq 10 ] && [ "$minor_version" -ge 15 ]); then
                log_result "PASS" "macOS version supported" "Requires 10.15+, found $macos_version"
            else
                log_result "FAIL" "macOS version too old" "Requires 10.15+, found $macos_version"
            fi
        fi
        
    elif [[ -f /etc/debian_version ]]; then
        local debian_version=$(cat /etc/debian_version 2>/dev/null || echo "unknown")
        log_result "PASS" "Debian/Ubuntu detected" "Version info: $debian_version"
        
        # Check Ubuntu version if available
        if command -v lsb_release >/dev/null 2>&1; then
            local ubuntu_version=$(lsb_release -rs 2>/dev/null || echo "unknown")
            if [[ "$ubuntu_version" != "unknown" ]]; then
                local version_num=$(echo "$ubuntu_version" | cut -d. -f1)
                if [ "$version_num" -ge 20 ]; then
                    log_result "PASS" "Ubuntu version supported" "Requires 20.04+, found $ubuntu_version"
                else
                    log_result "WARN" "Ubuntu version may be too old" "Recommended 20.04+, found $ubuntu_version"
                fi
            fi
        fi
        
    else
        log_result "FAIL" "Unsupported operating system" "Supports macOS and Ubuntu/Debian only"
    fi
}

check_disk_space() {
    echo ""
    echo "Checking disk space..."
    
    if command -v df >/dev/null; then
        local available_kb=$(df "$HOME" | awk 'NR==2 {print $4}')
        local available_gb=$((available_kb / 1024 / 1024))
        
        if [ "$available_kb" -gt 2097152 ]; then  # 2GB in KB
            log_result "PASS" "Sufficient disk space" "${available_gb}GB available (requires 2GB)"
        elif [ "$available_kb" -gt 1048576 ]; then  # 1GB in KB
            log_result "WARN" "Low disk space" "${available_gb}GB available (recommended 2GB+)"
        else
            log_result "FAIL" "Insufficient disk space" "${available_gb}GB available (requires 2GB minimum)"
        fi
    else
        log_result "WARN" "Cannot check disk space" "df command not available"
    fi
}

check_internet_connectivity() {
    echo ""
    echo "Checking internet connectivity..."
    
    # Test basic connectivity
    if curl -s --connect-timeout 10 https://github.com >/dev/null 2>&1; then
        log_result "PASS" "Internet connectivity" "Can reach github.com"
    else
        log_result "FAIL" "No internet connectivity" "Cannot reach github.com"
        return
    fi
    
    # Test specific required domains
    local domains=(
        "raw.githubusercontent.com"
        "archive.ubuntu.com"
        "releases.hashicorp.com"
        "awscli.amazonaws.com"
        "dl.k8s.io"
        "go.dev"
    )
    
    # Add macOS-specific domains
    if [[ "$OSTYPE" == "darwin"* ]]; then
        domains+=("brew.sh")
    fi
    
    local failed_domains=()
    for domain in "${domains[@]}"; do
        if curl -s --connect-timeout 5 "https://$domain" >/dev/null 2>&1; then
            log_result "PASS" "Can reach $domain"
        else
            failed_domains+=("$domain")
            log_result "WARN" "Cannot reach $domain" "May cause installation issues"
        fi
    done
    
    if [ ${#failed_domains[@]} -gt 0 ]; then
        log_result "WARN" "Some domains unreachable" "Installation may partially fail"
    fi
}

check_user_privileges() {
    echo ""
    echo "Checking user privileges..."
    
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        log_result "WARN" "Running as root" "Not recommended - consider using regular user"
    else
        log_result "PASS" "Running as regular user" "UID: $EUID"
    fi
    
    # Check sudo access (Linux)
    if [[ ! "$OSTYPE" == "darwin"* ]]; then
        if sudo -n true 2>/dev/null; then
            log_result "PASS" "Sudo access available" "Required for package installation"
        else
            log_result "FAIL" "No sudo access" "Required for Linux package installation"
        fi
    fi
    
    # Check write permissions to home directory
    if [ -w "$HOME" ]; then
        log_result "PASS" "Home directory writable" "$HOME"
    else
        log_result "FAIL" "Home directory not writable" "$HOME"
    fi
}

check_existing_tools() {
    echo ""
    echo "Checking existing tools..."
    
    # Essential tools that should be available
    local essential_tools=("curl" "git")
    
    # Add platform-specific tools
    if [[ "$OSTYPE" == "darwin"* ]]; then
        essential_tools+=("xcode-select")
    else
        essential_tools+=("apt")
    fi
    
    for tool in "${essential_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "curl") version=$(curl --version | head -1) ;;
                "git") version=$(git --version) ;;
                "xcode-select") 
                    if xcode-select -p >/dev/null 2>&1; then
                        version="Command Line Tools installed"
                    else
                        version="Command Line Tools NOT installed"
                        log_result "FAIL" "$tool available but not configured" "Run: xcode-select --install"
                        continue
                    fi
                    ;;
                "apt") version=$(apt --version | head -1) ;;
            esac
            log_result "PASS" "$tool available" "$version"
        else
            if [[ "$tool" == "xcode-select" ]]; then
                log_result "FAIL" "Xcode Command Line Tools not installed" "Run: xcode-select --install"
            else
                log_result "FAIL" "$tool not found" "Required for installation"
            fi
        fi
    done
}

check_existing_configurations() {
    echo ""
    echo "Checking existing configurations..."
    
    local config_files=(
        ".zshrc"
        ".gitconfig"
        ".config/nvim"
        ".tmux.conf"
    )
    
    local existing_configs=()
    
    for config in "${config_files[@]}"; do
        if [ -e "$HOME/$config" ]; then
            existing_configs+=("$config")
            if [ -L "$HOME/$config" ]; then
                local target=$(readlink "$HOME/$config")
                log_result "INFO" "Existing symlink: $config" "-> $target"
            else
                log_result "INFO" "Existing file/directory: $config" "Will be backed up"
            fi
        fi
    done
    
    if [ ${#existing_configs[@]} -eq 0 ]; then
        log_result "PASS" "No conflicting configurations found" "Clean installation possible"
    else
        log_result "INFO" "Existing configurations found" "Will be backed up during installation"
    fi
}

check_shell_configuration() {
    echo ""
    echo "Checking shell configuration..."
    
    # Check current shell
    log_result "INFO" "Current shell" "$SHELL"
    
    # Check if zsh is available
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version=$(zsh --version)
        log_result "PASS" "zsh available" "$zsh_version"
    else
        log_result "INFO" "zsh not installed" "Will be installed during setup"
    fi
    
    # Check if zsh is in /etc/shells
    if grep -q "$(command -v zsh 2>/dev/null || echo '/usr/bin/zsh')" /etc/shells 2>/dev/null; then
        log_result "PASS" "zsh in allowed shells" "/etc/shells"
    else
        log_result "WARN" "zsh may not be in /etc/shells" "May need manual addition"
    fi
}

generate_summary() {
    echo ""
    echo "========================================"
    echo "  Requirements Check Summary"
    echo "========================================"
    
    if [ $REQUIREMENTS_MET -eq 0 ]; then
        if [ $WARNINGS_COUNT -eq 0 ]; then
            echo -e "${GREEN}✅ All requirements met - Ready for installation${NC}"
        else
            echo -e "${YELLOW}⚠️  Requirements met with $WARNINGS_COUNT warnings${NC}"
            echo "Installation should proceed but may encounter minor issues"
        fi
    else
        echo -e "${RED}❌ Requirements check failed${NC}"
        echo "Please address the failed requirements before installation"
    fi
    
    echo ""
    echo "Next steps:"
    if [ $REQUIREMENTS_MET -eq 0 ]; then
        echo "1. Run the installation:"
        echo "   curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash"
        echo "2. Or clone manually:"
        echo "   git clone https://github.com/akgoode/dotfiles.git ~/.dotfiles"
        echo "   cd ~/.dotfiles && ./install.sh"
    else
        echo "1. Fix the failed requirements listed above"
        echo "2. Re-run this requirements check"
        echo "3. Proceed with installation once all requirements are met"
    fi
    
    if [ $WARNINGS_COUNT -gt 0 ]; then
        echo ""
        echo "Note: Warnings indicate potential issues but won't prevent installation"
    fi
}

main() {
    check_os_support
    check_disk_space
    check_internet_connectivity
    check_user_privileges
    check_existing_tools
    check_existing_configurations
    check_shell_configuration
    generate_summary
    
    # Exit with appropriate code
    exit $REQUIREMENTS_MET
}

# Run main function
main "$@"