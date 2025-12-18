#!/bin/bash

# Git integration test for git-remote-gcrypt-incremental
# This test simulates real Git usage

set -e

echo "🔧 Git Integration Test for git-remote-gcrypt-incremental"
echo "========================================================"

# Configuration
TEST_DIR="/tmp/git_integration_test_$$"
REMOTE_DIR="/tmp/git_remote_test_$$"
SCRIPT_NAME="git-remote-gcrypt-incremental"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

# Setup test environment
setup_test() {
    log_step "Setting up test environment..."
    
    # Cleanup any existing test dirs
    cleanup
    
    # Create test directories
    mkdir -p "$TEST_DIR" "$REMOTE_DIR"
    
    # Create a symlink to our script with the expected name
    ln -sf "$(pwd)/git-remote-gcrypt-incremental" "/tmp/git-remote-gcrypt-incremental"
    
    # Add to PATH temporarily
    export PATH="/tmp:$PATH"
    
    # Initialize git repo
    cd "$TEST_DIR"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "# Test Repository" > README.md
    echo "This is a test repository for git-remote-gcrypt-incremental" >> README.md
    git add README.md
    git commit -m "Initial commit"
    
    log_success "Test environment setup complete"
}

# Test 1: Add remote with gcrypt-incremental protocol
test_add_remote() {
    log_step "Test 1: Adding gcrypt-incremental remote..."
    
    cd "$TEST_DIR"
    
    # Add remote using our incremental protocol
    git remote add origin "gcrypt-incremental::file://$REMOTE_DIR"
    
    # Configure incremental branch
    git config remote.origin.gcrypt-incremental-branch "master"
    
    # Verify remote was added
    if git remote -v | grep -q "gcrypt-incremental::"; then
        log_success "Remote added successfully"
    else
        log_error "Failed to add remote"
        return 1
    fi
}

# Test 2: Test Git calling our remote helper
test_git_capabilities() {
    log_step "Test 2: Testing Git remote helper capabilities..."
    
    cd "$TEST_DIR"
    
    # Git should be able to get capabilities from our helper
    # We'll simulate this by calling our helper directly
    if echo "capabilities" | git-remote-gcrypt-incremental origin "gcrypt-incremental::file://$REMOTE_DIR" | grep -q "push"; then
        log_success "Capabilities command works"
    else
        log_error "Capabilities command failed"
        return 1
    fi
}

# Test 3: Test list command
test_git_list() {
    log_step "Test 3: Testing Git remote helper list command..."
    
    cd "$TEST_DIR"
    
    # Test list command with debug output
    export GCRYPT_DEBUG=1
    if echo "list" | git-remote-gcrypt-incremental origin "gcrypt-incremental::file://$REMOTE_DIR" 2>&1 | grep -q "Incremental mode enabled"; then
        log_success "List command works with incremental mode detection"
    else
        log_error "List command failed"
        return 1
    fi
    unset GCRYPT_DEBUG
}

# Test 4: Test error handling
test_error_handling() {
    log_step "Test 4: Testing error handling..."
    
    cd "$TEST_DIR"
    
    # Test invalid command
    if echo "invalid_command" | git-remote-gcrypt-incremental origin "gcrypt-incremental::file://$REMOTE_DIR" 2>&1 | grep -q "Unknown input"; then
        log_success "Error handling works correctly"
    else
        log_error "Error handling failed"
        return 1
    fi
}

# Test 5: Test configuration detection
test_config_detection() {
    log_step "Test 5: Testing configuration detection..."
    
    cd "$TEST_DIR"
    
    # Test with different branch configuration
    git config remote.origin.gcrypt-incremental-branch "main"
    
    # Should detect that current branch (master) is not configured for incremental
    export GCRYPT_DEBUG=1
    if echo "list" | git-remote-gcrypt-incremental origin "gcrypt-incremental::file://$REMOTE_DIR" 2>&1 | grep -q "Incremental mode disabled"; then
        log_success "Configuration detection works correctly"
    else
        log_error "Configuration detection failed"
        return 1
    fi
    unset GCRYPT_DEBUG
    
    # Reset configuration
    git config remote.origin.gcrypt-incremental-branch "master"
}

# Test 6: Test with multiple remotes
test_multiple_remotes() {
    log_step "Test 6: Testing multiple remotes..."
    
    cd "$TEST_DIR"
    
    # Add another remote
    git remote add backup "gcrypt-incremental::file://${REMOTE_DIR}_backup"
    git config remote.backup.gcrypt-incremental-branch "master"
    
    # Test that each remote works independently
    if echo "capabilities" | git-remote-gcrypt-incremental backup "gcrypt-incremental::file://${REMOTE_DIR}_backup" | grep -q "push"; then
        log_success "Multiple remotes work correctly"
    else
        log_error "Multiple remotes failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    local tests_passed=0
    local tests_total=6
    
    # Setup (not counted as a test)
    if ! setup_test; then
        log_error "Setup failed - cannot continue"
        return 1
    fi
    
    # Run actual tests
    test_add_remote && tests_passed=$((tests_passed + 1)) || log_error "Add remote test failed"
    test_git_capabilities && tests_passed=$((tests_passed + 1)) || log_error "Capabilities test failed"
    test_git_list && tests_passed=$((tests_passed + 1)) || log_error "List test failed"
    test_error_handling && tests_passed=$((tests_passed + 1)) || log_error "Error handling test failed"
    test_config_detection && tests_passed=$((tests_passed + 1)) || log_error "Config detection test failed"
    test_multiple_remotes && tests_passed=$((tests_passed + 1)) || log_error "Multiple remotes test failed"
    
    echo
    echo "========================================================"
    echo "📊 Git Integration Test Results"
    echo "========================================================"
    echo "Tests passed: $tests_passed/$tests_total"
    
    if [ "$tests_passed" -eq "$tests_total" ]; then
        log_success "🎉 All Git integration tests passed!"
        log_success "The script is ready for real Git usage!"
        return 0
    else
        log_error "❌ Some Git integration tests failed"
        return 1
    fi
}

# Main execution
main() {
    if run_all_tests; then
        log_success "Git integration test completed successfully"
        cleanup
        # Remove temporary symlink
        rm -f "/tmp/git-remote-gcrypt-incremental"
        exit 0
    else
        log_error "Git integration test failed"
        cleanup
        # Remove temporary symlink
        rm -f "/tmp/git-remote-gcrypt-incremental"
        exit 1
    fi
}

# Run the tests
main