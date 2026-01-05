#!/bin/bash
# Comprehensive shell configuration validation

set -e

echo "========================================"
echo "  Shell Configuration Validation Suite"
echo "========================================"

echo ""
echo "Running shell configuration tests..."
./test/test-shell-config.sh

echo ""
echo "Running AI-friendly output tests..."
./test/test-ai-friendly-output.sh

echo ""
echo "========================================"
echo "  All Shell Validation Tests Complete"
echo "========================================"
echo ""
echo "✓ Task 3.1: zsh configuration loading - PASSED"
echo "✓ Task 3.3: AI-friendly output format - PASSED"
echo ""
echo "Shell configuration is validated and ready for use!"