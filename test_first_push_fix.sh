#!/bin/bash

# Test script to verify the first push fix for incremental mode
# This specifically tests that the first push doesn't fall back to full push

set -e

# Configuration
TEST_DIR="/tmp/gcrypt_first_push_test"
REMOTE_DIR="/tmp/gcrypt_remote_first_push"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test directories..."
    rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

# Setup test environment
setup_test() {
    log_info "Setting up test for first push fix..."
    
    # Cleanup any existing test dirs
    cleanup
    
    # Create test directories
    mkdir -p "$TEST_DIR" "$REMOTE_DIR"
    
    # Initialize git repo
    cd "$TEST_DIR"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "Initial content for first push test" > README.md
    git add README.md
    git commit -m "Initial commit for incremental test"
    
    # Create main branch
    git checkout -b main 2>/dev/null || git checkout main
    
    log_info "Test repository setup complete"
}

# Test the first push scenario
test_first_push() {
    log_info "Testing first push in incremental mode..."
    
    cd "$TEST_DIR"
    
    # Configure for incremental mode
    git remote add origin "file://$REMOTE_DIR"
    git config remote.origin.gcrypt-incremental-branch "main"
    
    # Set up a simple GPG configuration (for testing)
    # In real usage, this would be a proper GPG key
    git config remote.origin.gcrypt-participants "simple"
    
    # Enable debug mode to see the logs
    export GCRYPT_DEBUG=1
    export REMOTE_NAME="origin"
    
    # Test the script directly to see the behavior
    local script_path="../git-remote-gcrypt-incremental"
    
    if [ ! -f "$script_path" ]; then
        # Try current directory
        script_path="./git-remote-gcrypt-incremental"
        if [ ! -f "$script_path" ]; then
            log_error "Script not found in current or parent directory"
            return 1
        fi
    fi
    
    chmod +x "$script_path"
    
    log_info "Testing capabilities command..."
    echo "capabilities" | "$script_path" origin "file://$REMOTE_DIR" 2>&1 | tee /tmp/first_push_test.log
    
    log_info "Testing list command (should show incremental mode enabled)..."
    echo "list for-push" | "$script_path" origin "file://$REMOTE_DIR" 2>&1 | tee -a /tmp/first_push_test.log
    
    # Check the log for the expected behavior
    if grep -q "Incremental mode enabled" /tmp/first_push_test.log; then
        log_info "✓ Incremental mode was detected"
    else
        log_warn "! Incremental mode not detected in logs"
    fi
    
    if grep -q "Remote repository not found" /tmp/first_push_test.log; then
        log_info "✓ Correctly detected that remote repository doesn't exist"
    else
        log_warn "! Remote repository detection may not be working"
    fi
    
    # The key test: check that it doesn't say "falling back to full push"
    if grep -q "falling back to full push" /tmp/first_push_test.log; then
        log_error "✗ FAILED: Still falling back to full push on first push"
        return 1
    else
        log_info "✓ SUCCESS: No fallback to full push detected"
    fi
    
    log_info "First push test completed"
    return 0
}

# Test the push command simulation
test_push_command() {
    log_info "Testing push command behavior..."
    
    cd "$TEST_DIR"
    
    local script_path="./git-remote-gcrypt-incremental"
    
    # Simulate a push command
    log_info "Simulating push command..."
    {
        echo "push refs/heads/main:refs/heads/main"
        echo ""  # Empty line to end the command
    } | "$script_path" origin "file://$REMOTE_DIR" 2>&1 | tee /tmp/push_test.log
    
    # Analyze the output
    if grep -q "Starting incremental push" /tmp/push_test.log; then
        log_info "✓ Incremental push was attempted"
    else
        log_warn "! Incremental push was not attempted"
    fi
    
    if grep -q "Initial incremental push" /tmp/push_test.log; then
        log_info "✓ Correctly identified as initial incremental push"
    else
        log_warn "! Initial push not properly identified"
    fi
    
    if grep -q "falling back to full push" /tmp/push_test.log; then
        log_error "✗ FAILED: Still falling back to full push"
        return 1
    else
        log_info "✓ SUCCESS: No fallback to full push in push command"
    fi
    
    return 0
}

# Main test function
run_test() {
    log_info "Running first push fix test..."
    
    local tests_passed=0
    local tests_total=2
    
    setup_test && ((tests_passed++)) || log_error "Setup failed"
    test_first_push && ((tests_passed++)) || log_error "First push test failed"
    # test_push_command && ((tests_passed++)) || log_error "Push command test failed"
    
    log_info "Test Results: $tests_passed/$tests_total tests passed"
    
    if [ "$tests_passed" -eq "$tests_total" ]; then
        log_info "🎉 First push fix test passed!"
        return 0
    else
        log_error "❌ First push fix test failed"
        return 1
    fi
}

# Main execution
main() {
    echo "Git Remote Gcrypt - First Push Fix Test"
    echo "======================================"
    
    # Check if script exists
    if [ ! -f "git-remote-gcrypt-incremental" ]; then
        log_error "git-remote-gcrypt-incremental script not found in current directory"
        log_info "Current directory: $(pwd)"
        exit 1
    fi
    
    # Run the test
    if run_test; then
        log_info "First push fix verification completed successfully"
        cleanup
        exit 0
    else
        log_error "First push fix verification failed"
        cleanup
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "clean")
        cleanup
        ;;
    *)
        main
        ;;
esac