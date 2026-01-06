#!/bin/bash
# Production deployment test runner
# Requirements: 1.2, 1.3, 2.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG_DIR="/tmp/dotfiles-production-tests-$(date +%Y%m%d-%H%M%S)"
OVERALL_RESULT=0

echo "========================================"
echo "  Dotfiles Production Test Suite"
echo "========================================"
echo "Test Suite: Production Deployment Validation"
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo "Log Directory: $TEST_LOG_DIR"
echo ""

# Create test log directory
mkdir -p "$TEST_LOG_DIR"

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
            OVERALL_RESULT=1
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "  $details"
    fi
}

# Test 1: Requirements Check
run_requirements_test() {
    echo "========================================"
    echo "  Test 1: System Requirements"
    echo "========================================"
    
    local test_log="$TEST_LOG_DIR/requirements-test.log"
    
    echo "Running system requirements check..."
    if curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/scripts/check-requirements.sh | bash > "$test_log" 2>&1; then
        log_result "PASS" "System requirements check" "See: $test_log"
    else
        log_result "FAIL" "System requirements check failed" "See: $test_log"
        echo "Requirements check output:"
        tail -10 "$test_log" | sed 's/^/  /'
    fi
}

# Test 2: Clean Installation
run_clean_installation_test() {
    echo ""
    echo "========================================"
    echo "  Test 2: Clean Installation"
    echo "========================================"
    
    local test_log="$TEST_LOG_DIR/clean-installation-test.log"
    
    echo "Running clean installation test..."
    echo "This test installs dotfiles on a clean system and validates the result."
    
    if [ -f "$SCRIPT_DIR/test-production-deployment.sh" ]; then
        if "$SCRIPT_DIR/test-production-deployment.sh" > "$test_log" 2>&1; then
            log_result "PASS" "Clean installation test" "See: $test_log"
        else
            log_result "FAIL" "Clean installation test failed" "See: $test_log"
            echo "Clean installation test output (last 10 lines):"
            tail -10 "$test_log" | sed 's/^/  /'
        fi
    else
        log_result "FAIL" "Clean installation test script missing" "$SCRIPT_DIR/test-production-deployment.sh"
    fi
}

# Test 3: Existing Configuration Handling
run_existing_config_test() {
    echo ""
    echo "========================================"
    echo "  Test 3: Existing Configuration Handling"
    echo "========================================"
    
    local test_log="$TEST_LOG_DIR/existing-config-test.log"
    
    echo "Running existing configuration test..."
    echo "This test installs dotfiles over existing configurations and validates backup/restore."
    
    if [ -f "$SCRIPT_DIR/test-existing-config-deployment.sh" ]; then
        if "$SCRIPT_DIR/test-existing-config-deployment.sh" > "$test_log" 2>&1; then
            log_result "PASS" "Existing configuration test" "See: $test_log"
        else
            log_result "FAIL" "Existing configuration test failed" "See: $test_log"
            echo "Existing configuration test output (last 10 lines):"
            tail -10 "$test_log" | sed 's/^/  /'
        fi
    else
        log_result "FAIL" "Existing configuration test script missing" "$SCRIPT_DIR/test-existing-config-deployment.sh"
    fi
}

# Test 4: Cross-Platform Validation
run_cross_platform_test() {
    echo ""
    echo "========================================"
    echo "  Test 4: Cross-Platform Validation"
    echo "========================================"
    
    local test_log="$TEST_LOG_DIR/cross-platform-test.log"
    
    echo "Running cross-platform validation..."
    
    # Detect current platform
    local current_platform
    if [[ "$OSTYPE" == "darwin"* ]]; then
        current_platform="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        current_platform="Linux"
    else
        current_platform="Unknown"
    fi
    
    echo "Current platform: $current_platform" > "$test_log"
    
    # Run platform-specific tests
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Testing macOS-specific functionality..." | tee -a "$test_log"
        
        # Test Homebrew functionality
        if command -v brew >/dev/null 2>&1; then
            if brew --version >> "$test_log" 2>&1; then
                log_result "PASS" "Homebrew available and functional"
            else
                log_result "WARN" "Homebrew has issues"
            fi
        else
            log_result "INFO" "Homebrew not installed (will be installed during dotfiles setup)"
        fi
        
        # Test Xcode Command Line Tools
        if xcode-select -p >/dev/null 2>&1; then
            log_result "PASS" "Xcode Command Line Tools installed"
        else
            log_result "WARN" "Xcode Command Line Tools missing"
        fi
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Testing Linux-specific functionality..." | tee -a "$test_log"
        
        # Test package manager
        if command -v apt >/dev/null 2>&1; then
            if apt --version >> "$test_log" 2>&1; then
                log_result "PASS" "APT package manager available"
            else
                log_result "WARN" "APT package manager has issues"
            fi
        else
            log_result "WARN" "APT package manager not available"
        fi
        
        # Test sudo access
        if sudo -n true 2>/dev/null; then
            log_result "PASS" "Sudo access available"
        else
            log_result "WARN" "Sudo access may be required during installation"
        fi
    fi
    
    # Test common functionality across platforms
    echo "Testing cross-platform compatibility..." | tee -a "$test_log"
    
    # Test shell availability
    if command -v zsh >/dev/null 2>&1; then
        log_result "PASS" "zsh shell available"
    else
        log_result "INFO" "zsh will be installed during setup"
    fi
    
    # Test git availability
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version)
        log_result "PASS" "git available" "$git_version"
    else
        log_result "FAIL" "git not available (required)"
    fi
    
    # Test curl availability
    if command -v curl >/dev/null 2>&1; then
        local curl_version=$(curl --version | head -1)
        log_result "PASS" "curl available" "$curl_version"
    else
        log_result "FAIL" "curl not available (required)"
    fi
}

# Test 5: Network and Connectivity
run_network_test() {
    echo ""
    echo "========================================"
    echo "  Test 5: Network and Connectivity"
    echo "========================================"
    
    local test_log="$TEST_LOG_DIR/network-test.log"
    
    echo "Testing network connectivity..." | tee "$test_log"
    
    # Test basic internet connectivity
    if curl -s --connect-timeout 10 https://github.com >/dev/null 2>&1; then
        log_result "PASS" "Basic internet connectivity"
    else
        log_result "FAIL" "No internet connectivity"
        return 1
    fi
    
    # Test required domains
    local domains=(
        "github.com"
        "raw.githubusercontent.com"
        "archive.ubuntu.com"
        "releases.hashicorp.com"
        "awscli.amazonaws.com"
        "dl.k8s.io"
        "go.dev"
    )
    
    # Add platform-specific domains
    if [[ "$OSTYPE" == "darwin"* ]]; then
        domains+=("brew.sh")
    fi
    
    local failed_domains=0
    for domain in "${domains[@]}"; do
        echo "Testing $domain..." >> "$test_log"
        if curl -s --connect-timeout 5 "https://$domain" >/dev/null 2>&1; then
            log_result "PASS" "Can reach $domain"
        else
            log_result "WARN" "Cannot reach $domain"
            failed_domains=$((failed_domains + 1))
        fi
    done
    
    if [ $failed_domains -eq 0 ]; then
        log_result "PASS" "All required domains accessible"
    elif [ $failed_domains -lt 3 ]; then
        log_result "WARN" "Some domains inaccessible" "$failed_domains/${#domains[@]} failed"
    else
        log_result "FAIL" "Many domains inaccessible" "$failed_domains/${#domains[@]} failed"
    fi
    
    # Test download speed
    echo "Testing download speed..." >> "$test_log"
    local start_time=$(date +%s)
    if curl -o /dev/null -s https://github.com/akgoode/dotfiles/archive/main.zip 2>>"$test_log"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        if [ $duration -lt 30 ]; then
            log_result "PASS" "Download speed acceptable" "${duration}s for repository archive"
        else
            log_result "WARN" "Download speed slow" "${duration}s for repository archive"
        fi
    else
        log_result "WARN" "Could not test download speed"
    fi
}

# Test 6: Security and Permissions
run_security_test() {
    echo ""
    echo "========================================"
    echo "  Test 6: Security and Permissions"
    echo "========================================"
    
    local test_log="$TEST_LOG_DIR/security-test.log"
    
    echo "Testing security and permissions..." | tee "$test_log"
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_result "WARN" "Running as root" "Not recommended for dotfiles installation"
    else
        log_result "PASS" "Running as non-root user" "UID: $EUID"
    fi
    
    # Check home directory permissions
    if [ -w "$HOME" ]; then
        log_result "PASS" "Home directory writable"
    else
        log_result "FAIL" "Home directory not writable"
    fi
    
    # Check .config directory
    if [ -d ~/.config ]; then
        if [ -w ~/.config ]; then
            log_result "PASS" ".config directory writable"
        else
            log_result "WARN" ".config directory not writable"
        fi
    else
        log_result "INFO" ".config directory will be created"
    fi
    
    # Test file creation permissions
    local test_file="$HOME/.dotfiles-permission-test-$$"
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        log_result "PASS" "File creation permissions OK"
    else
        log_result "FAIL" "Cannot create files in home directory"
    fi
    
    # Check for immutable files (Linux)
    if command -v lsattr >/dev/null 2>&1; then
        local immutable_files=$(find ~ -maxdepth 2 -exec lsattr {} \; 2>/dev/null | grep "^....i" | wc -l)
        if [ "$immutable_files" -eq 0 ]; then
            log_result "PASS" "No immutable files found"
        else
            log_result "WARN" "Immutable files found" "$immutable_files files"
        fi
    fi
}

# Generate comprehensive report
generate_final_report() {
    echo ""
    echo "========================================"
    echo "  Production Test Suite Results"
    echo "========================================"
    
    local total_tests=6
    local passed_tests=0
    
    # Count results from log files
    for log_file in "$TEST_LOG_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            if grep -q "PASSED\|✅" "$log_file"; then
                passed_tests=$((passed_tests + 1))
            fi
        fi
    done
    
    # Overall status
    if [ $OVERALL_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ Production Test Suite PASSED${NC}"
        echo "The dotfiles system is ready for production deployment"
    else
        echo -e "${RED}❌ Production Test Suite FAILED${NC}"
        echo "Issues found that need to be addressed before production deployment"
    fi
    
    echo ""
    echo "Test Summary:"
    echo "- Total Tests: $total_tests"
    echo "- Passed Tests: $passed_tests"
    echo "- Host: $(hostname)"
    echo "- Platform: $(uname -s) $(uname -r)"
    echo "- User: $(whoami)"
    echo "- Test Duration: $(($(date +%s) - $(date -d "$(ls -la "$TEST_LOG_DIR" | head -2 | tail -1 | awk '{print $6, $7, $8}')" +%s) 2>/dev/null || echo "unknown"))s"
    
    echo ""
    echo "Test Logs:"
    for log_file in "$TEST_LOG_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            echo "  $(basename "$log_file"): $log_file"
        fi
    done
    
    echo ""
    echo "Next Steps:"
    if [ $OVERALL_RESULT -eq 0 ]; then
        echo "1. ✅ All tests passed - system is ready for production deployment"
        echo "2. 📋 Use the deployment checklist: docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md"
        echo "3. 🚀 Deploy using: curl -fsSL https://raw.githubusercontent.com/akgoode/dotfiles/main/install.sh | bash"
        echo "4. 🔍 Validate deployment: ~/.dotfiles/scripts/validate-production-deployment.sh"
    else
        echo "1. ❌ Review failed tests above and in log files"
        echo "2. 🔧 Fix identified issues"
        echo "3. 🔄 Re-run this test suite"
        echo "4. 📖 Check troubleshooting guide: docs/TROUBLESHOOTING_GUIDE.md"
    fi
    
    echo ""
    echo "Documentation:"
    echo "- 📋 Deployment Checklist: docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md"
    echo "- 🔧 Troubleshooting Guide: docs/TROUBLESHOOTING_GUIDE.md"
    echo "- 🔄 Rollback Procedures: docs/ROLLBACK_PROCEDURES.md"
    echo "- 🆘 Support: https://github.com/akgoode/dotfiles/issues"
}

# Main execution
main() {
    echo "This comprehensive test suite validates the dotfiles system for production deployment."
    echo "It will test system requirements, installation processes, and functionality."
    echo ""
    echo "Tests to run:"
    echo "1. System Requirements Check"
    echo "2. Clean Installation Test"
    echo "3. Existing Configuration Handling"
    echo "4. Cross-Platform Validation"
    echo "5. Network and Connectivity"
    echo "6. Security and Permissions"
    echo ""
    
    # Confirm with user
    read -p "Run complete production test suite? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Test suite cancelled by user"
        exit 0
    fi
    
    echo ""
    echo "Starting production test suite..."
    
    # Run all tests
    run_requirements_test
    run_cross_platform_test
    run_network_test
    run_security_test
    
    # Interactive tests (require user confirmation)
    echo ""
    read -p "Run installation tests? These will modify your system temporarily. (y/N): " install_confirm
    if [[ "$install_confirm" =~ ^[Yy]$ ]]; then
        run_clean_installation_test
        run_existing_config_test
    else
        echo "Skipping installation tests (user choice)"
        log_result "INFO" "Installation tests skipped by user"
    fi
    
    # Generate final report
    generate_final_report
    
    exit $OVERALL_RESULT
}

# Run main function
main "$@"