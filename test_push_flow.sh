#!/bin/bash

# Test the complete push flow

set -e

echo "🧪 Testing Complete Push Flow"
echo "============================="

# Create test repository
TEST_DIR="/tmp/push_flow_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Setting up test repository..."
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create initial commit
echo "# Test Repository" > README.md
git add README.md
git commit -m "Initial commit"

# Configure incremental remote
git remote add origin "gcrypt-incremental::file:///tmp/test_remote_$$"
git config remote.origin.gcrypt-incremental-branch "master"

echo "✅ Repository setup complete"
echo

# Test the push flow step by step
echo "Testing push flow with debug output..."
export GCRYPT_DEBUG=1

# Simulate what Git does during push
echo "Step 1: capabilities"
echo "capabilities" | "$OLDPWD/git-remote-gcrypt-incremental" origin "gcrypt-incremental::file:///tmp/test_remote_$$"

echo
echo "Step 2: list"
echo "list" | "$OLDPWD/git-remote-gcrypt-incremental" origin "gcrypt-incremental::file:///tmp/test_remote_$$"

echo
echo "Step 3: push"
echo "push refs/heads/master:refs/heads/master" | "$OLDPWD/git-remote-gcrypt-incremental" origin "gcrypt-incremental::file:///tmp/test_remote_$$"

echo
echo "✅ Push flow test completed successfully!"

# Cleanup
cd "$OLDPWD"
rm -rf "$TEST_DIR" "/tmp/test_remote_$$"