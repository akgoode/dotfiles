#!/bin/bash
# Test Kiro MCP configuration

set -e

CONTAINER="dotfiles-test"

echo "========================================"
echo "  Kiro MCP Configuration Tests"
echo "========================================"

# Test 5.4: Test Kiro MCP configuration
echo ""
echo "[5.4] Testing Kiro MCP configuration..."

# Verify MCP settings are linked correctly in container
echo "  Testing Kiro MCP settings symlink..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that Kiro MCP settings directory exists and is properly symlinked
    if [ -L ~/.kiro/settings/mcp.json ] && [ -f ~/.kiro/settings/mcp.json ]; then
        echo "    ✓ Kiro MCP settings are properly symlinked"
    else
        echo "    ✗ Kiro MCP settings symlink is broken or missing"
        exit 1
    fi
    
    # Test that the symlink points to the correct dotfiles location
    LINK_TARGET=$(readlink ~/.kiro/settings/mcp.json)
    if [[ "$LINK_TARGET" == *"dotfiles/editors/kiro/settings/mcp.json" ]]; then
        echo "    ✓ Kiro MCP settings symlink points to correct location"
    else
        echo "    ✗ Kiro MCP settings symlink points to wrong location: $LINK_TARGET"
        exit 1
    fi
    
    # Test that the settings file is readable
    if [ -r ~/.kiro/settings/mcp.json ]; then
        echo "    ✓ Kiro MCP settings file is readable"
    else
        echo "    ✗ Kiro MCP settings file is not readable"
        exit 1
    fi
'

# Test configuration file format via SSH
echo "  Testing Kiro MCP configuration file format..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that the MCP config file is valid JSON
    if jq . ~/.kiro/settings/mcp.json >/dev/null 2>&1; then
        echo "    ✓ Kiro MCP config is valid JSON"
    else
        echo "    ✗ Kiro MCP config is not valid JSON"
        exit 1
    fi
    
    # Test for expected MCP configuration structure
    MCP_CONFIG=~/.kiro/settings/mcp.json
    
    # Check for mcpServers section
    if jq -e ".mcpServers" "$MCP_CONFIG" >/dev/null 2>&1; then
        echo "    ✓ mcpServers section exists"
    else
        echo "    ✗ mcpServers section missing"
        exit 1
    fi
    
    # Check if there are any configured servers
    SERVER_COUNT=$(jq ".mcpServers | length" "$MCP_CONFIG")
    echo "    ✓ MCP configuration contains $SERVER_COUNT server(s)"
    
    # Test each configured server for required fields
    jq -r ".mcpServers | keys[]" "$MCP_CONFIG" | while read server; do
        echo "    Testing server: $server"
        
        # Check for command field
        if jq -e ".mcpServers.\"$server\".command" "$MCP_CONFIG" >/dev/null 2>&1; then
            COMMAND=$(jq -r ".mcpServers.\"$server\".command" "$MCP_CONFIG")
            echo "      ✓ Command configured: $COMMAND"
        else
            echo "      ✗ Command field missing for server $server"
            exit 1
        fi
        
        # Check for args field (should be array)
        if jq -e ".mcpServers.\"$server\".args" "$MCP_CONFIG" >/dev/null 2>&1; then
            if jq -e ".mcpServers.\"$server\".args | type == \"array\"" "$MCP_CONFIG" >/dev/null 2>&1; then
                echo "      ✓ Args field is properly formatted as array"
            else
                echo "      ✗ Args field is not an array"
                exit 1
            fi
        else
            echo "      ⚠ Args field missing for server $server"
        fi
        
        # Check for env field (should be object)
        if jq -e ".mcpServers.\"$server\".env" "$MCP_CONFIG" >/dev/null 2>&1; then
            if jq -e ".mcpServers.\"$server\".env | type == \"object\"" "$MCP_CONFIG" >/dev/null 2>&1; then
                echo "      ✓ Env field is properly formatted as object"
            else
                echo "      ✗ Env field is not an object"
                exit 1
            fi
        else
            echo "      ⚠ Env field missing for server $server"
        fi
        
        # Check for disabled field (should be boolean)
        if jq -e ".mcpServers.\"$server\".disabled" "$MCP_CONFIG" >/dev/null 2>&1; then
            if jq -e ".mcpServers.\"$server\".disabled | type == \"boolean\"" "$MCP_CONFIG" >/dev/null 2>&1; then
                DISABLED=$(jq -r ".mcpServers.\"$server\".disabled" "$MCP_CONFIG")
                echo "      ✓ Disabled field is properly formatted: $DISABLED"
            else
                echo "      ✗ Disabled field is not a boolean"
                exit 1
            fi
        else
            echo "      ⚠ Disabled field missing for server $server"
        fi
        
        # Check for autoApprove field (should be array)
        if jq -e ".mcpServers.\"$server\".autoApprove" "$MCP_CONFIG" >/dev/null 2>&1; then
            if jq -e ".mcpServers.\"$server\".autoApprove | type == \"array\"" "$MCP_CONFIG" >/dev/null 2>&1; then
                echo "      ✓ AutoApprove field is properly formatted as array"
            else
                echo "      ✗ AutoApprove field is not an array"
                exit 1
            fi
        else
            echo "      ⚠ AutoApprove field missing for server $server"
        fi
    done
'

# Test Kiro directory structure
echo "  Testing Kiro directory structure..."
docker exec -u testuser $CONTAINER bash -c '
    # Test that the Kiro settings directory exists
    if [ -d ~/.kiro/settings ]; then
        echo "    ✓ Kiro settings directory exists"
    else
        echo "    ✗ Kiro settings directory does not exist"
        exit 1
    fi
    
    # Test directory permissions
    if [ -w ~/.kiro/settings ]; then
        echo "    ✓ Kiro settings directory is writable"
    else
        echo "    ✗ Kiro settings directory is not writable"
        exit 1
    fi
    
    # Test that the parent .kiro directory exists
    if [ -d ~/.kiro ]; then
        echo "    ✓ Kiro config directory exists"
    else
        echo "    ✗ Kiro config directory does not exist"
        exit 1
    fi
'

# Test MCP configuration compatibility
echo "  Testing MCP configuration compatibility..."
docker exec -u testuser $CONTAINER bash -c '
    MCP_CONFIG=~/.kiro/settings/mcp.json
    
    # Test that the configuration follows expected MCP format
    # Check for any syntax that might cause issues
    if jq -e "." "$MCP_CONFIG" >/dev/null 2>&1; then
        echo "    ✓ Configuration is parseable by jq"
    else
        echo "    ✗ Configuration has JSON syntax errors"
        exit 1
    fi
    
    # Check for any obvious configuration issues
    # Ensure no servers have empty commands
    EMPTY_COMMANDS=$(jq -r ".mcpServers | to_entries[] | select(.value.command == \"\") | .key" "$MCP_CONFIG" 2>/dev/null || echo "")
    if [ -z "$EMPTY_COMMANDS" ]; then
        echo "    ✓ No servers with empty commands"
    else
        echo "    ⚠ Found servers with empty commands: $EMPTY_COMMANDS"
    fi
    
    # Check for reasonable server names (no spaces, special chars)
    BAD_NAMES=$(jq -r ".mcpServers | keys[]" "$MCP_CONFIG" | grep -E "[^a-zA-Z0-9_-]" || echo "")
    if [ -z "$BAD_NAMES" ]; then
        echo "    ✓ All server names use valid characters"
    else
        echo "    ⚠ Found server names with special characters: $BAD_NAMES"
    fi
'

echo "  ✓ Subtask 5.4 completed: Kiro MCP configuration tests passed"

echo ""
echo "========================================"
echo "  Kiro MCP Configuration Tests Complete"
echo "========================================"