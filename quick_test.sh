#!/bin/bash

# Quick test for git-remote-gcrypt-incremental

set -e

echo "=== Quick Test for git-remote-gcrypt-incremental ==="

# Test 1: capabilities command
echo "Test 1: capabilities command"
./git-remote-gcrypt-incremental capabilities
echo "✓ capabilities test passed"
echo

# Test 2: Test with debug mode
echo "Test 2: Debug mode test"
export GCRYPT_DEBUG=1

# Create a temporary git repo
TEST_DIR="/tmp/quick_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create initial commit
echo "test" > README.md
git add README.md
git commit -m "Initial commit"

# Configure incremental branch
git config remote.origin.gcrypt-incremental-branch "master"

echo "✓ Git repo setup complete"

# Test list command (should show incremental mode detection)
echo "Test 3: list command with incremental config"
SCRIPT_PATH="$OLDPWD/git-remote-gcrypt-incremental"
cd "$TEST_DIR"
"$SCRIPT_PATH" list origin "gcrypt::rsync://example.com/repo" || echo "Expected failure - no actual remote"

echo "✓ list command test completed"

# Cleanup
cd "$OLDPWD"
rm -rf "$TEST_DIR"

echo
echo "=== All quick tests completed ==="