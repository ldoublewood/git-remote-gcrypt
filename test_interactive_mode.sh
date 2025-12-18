#!/bin/bash

# Test interactive mode for git-remote-gcrypt-incremental

set -e

echo "=== Testing Interactive Mode ==="

# Test 1: capabilities command
echo "Test 1: capabilities command"
echo "capabilities" | ./git-remote-gcrypt-incremental origin "gcrypt::rsync://example.com/repo"
echo "✅ capabilities test passed"
echo

# Test 2: Test in a git repository with incremental config
echo "Test 2: Interactive mode in git repo"

# Create temporary git repo
TEST_DIR="/tmp/interactive_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

git init >/dev/null 2>&1
git config user.name "Test User" >/dev/null 2>&1
git config user.email "test@example.com" >/dev/null 2>&1

# Create initial commit
echo "test content" > README.md
git add README.md >/dev/null 2>&1
git commit -m "Initial commit" >/dev/null 2>&1

# Configure incremental branch
git config remote.origin.gcrypt-incremental-branch "master"

echo "Git repo setup complete"

# Test list command with incremental mode
echo "Testing list command with incremental mode..."
echo "list" | GCRYPT_DEBUG=1 "$OLDPWD/git-remote-gcrypt-incremental" origin "gcrypt::rsync://example.com/repo"

echo "✅ Interactive mode test completed"

# Cleanup
cd "$OLDPWD"
rm -rf "$TEST_DIR"

echo
echo "=== All interactive tests completed ==="