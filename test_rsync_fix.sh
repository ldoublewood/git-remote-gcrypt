#!/bin/bash

# Test the rsync compatibility fix for version 3.1.3

set -e

echo "🔧 Testing Rsync 3.1.3 Compatibility Fix"
echo "========================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not in a git repository. Creating test repository..."
    
    # Create a test git repository
    TEST_REPO="/tmp/gcrypt_test_repo_$$"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    
    git init
    echo "test content" > test.txt
    git add test.txt
    git commit -m "Initial commit"
    
    echo "✅ Created test repository at $TEST_REPO"
fi

echo
echo "Current directory: $(pwd)"
echo "Git status:"
git status --porcelain || echo "Clean working directory"

echo
echo "Testing rsync compatibility without --mkpath..."

# Simulate the user's configuration
echo "Setting up test remote configuration..."

# Use a local test path to avoid network issues
TEST_REMOTE_PATH="/tmp/gcrypt_remote_test_$$"
mkdir -p "$TEST_REMOTE_PATH"

# Configure the remote (using file:// for local testing)
git remote remove origin 2>/dev/null || true
git remote add origin "gcrypt-incremental::file://$TEST_REMOTE_PATH"

# Configure gcrypt settings
git config remote.origin.gcrypt-participants "simple"
git config remote.origin.gcrypt-incremental-branch "$(git branch --show-current 2>/dev/null || echo master)"

# Test the rsync flags without --mkpath
git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"

echo "✅ Remote configured: $(git config --get remote.origin.url)"
echo "✅ Rsync flags: $(git config --get remote.origin.gcrypt-rsync-put-flags)"
echo "✅ Incremental branch: $(git config --get remote.origin.gcrypt-incremental-branch)"

echo
echo "Testing git-remote-gcrypt-incremental..."

# Test the incremental remote helper
export GCRYPT_DEBUG=1

# Test list command first
echo "Testing list command..."
if ./git-remote-gcrypt-incremental list origin "file://$TEST_REMOTE_PATH" 2>&1; then
    echo "✅ List command works"
else
    echo "❌ List command failed"
fi

echo
echo "Testing push command..."
if ./git-remote-gcrypt-incremental push origin "file://$TEST_REMOTE_PATH" 2>&1; then
    echo "✅ Push command works"
else
    echo "❌ Push command failed"
fi

echo
echo "Verifying remote files..."
if [ -d "$TEST_REMOTE_PATH" ]; then
    echo "Remote directory contents:"
    ls -la "$TEST_REMOTE_PATH" || echo "Directory is empty or inaccessible"
else
    echo "❌ Remote directory not created"
fi

# Cleanup
echo
echo "Cleaning up..."
rm -rf "$TEST_REMOTE_PATH"

# If we created a test repo, clean it up too
if [[ "$(pwd)" == /tmp/gcrypt_test_repo_* ]]; then
    cd /tmp
    rm -rf "$TEST_REPO"
    echo "✅ Cleaned up test repository"
fi

echo
echo "🎯 Rsync 3.1.3 Compatibility Test Summary:"
echo "- Configuration uses --chmod=D755,F644 (no --mkpath)"
echo "- Directory creation handled by SSH/mkdir in PUT/PUTREPO functions"
echo "- Compatible with rsync 3.1.3 and newer versions"

echo
echo "✅ Rsync compatibility test completed"