#!/bin/bash

# Test real encrypted push functionality

set -e

echo "🔐 Testing Real Encrypted Push"
echo "=============================="

# Create test repository
TEST_DIR="/tmp/real_push_test_$$"
REMOTE_DIR="/tmp/real_push_remote_$$"
mkdir -p "$TEST_DIR" "$REMOTE_DIR"
cd "$TEST_DIR"

echo "Setting up test repository..."
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create initial commit
echo "# Real Push Test" > README.md
echo "Testing actual encrypted push functionality" >> README.md
git add README.md
git commit -m "Initial commit for real push test"

# Install our helper temporarily
HELPER_PATH="/tmp/git-remote-gcrypt-incremental-real-$$"
cp "$OLDPWD/git-remote-gcrypt-incremental" "$HELPER_PATH"
chmod +x "$HELPER_PATH"

# Create symlink with expected name
ln -sf "$HELPER_PATH" "/tmp/git-remote-gcrypt-incremental"
export PATH="/tmp:$PATH"

echo "✅ Repository and helper setup complete"
echo

# Configure remote and GPG
echo "Configuring remote and encryption..."
git remote add origin "gcrypt-incremental::file://$REMOTE_DIR"

# Configure for simple encryption (default key)
git config remote.origin.gcrypt-participants "simple"
git config remote.origin.gcrypt-incremental-branch "master"

echo "Remote configuration:"
git remote -v
echo "Participants: $(git config remote.origin.gcrypt-participants)"
echo "Incremental branch: $(git config remote.origin.gcrypt-incremental-branch)"
echo

# Test the actual push
echo "Testing real encrypted push..."
export GCRYPT_DEBUG=1

echo "Attempting git push..."
if timeout 60s git push origin master 2>&1; then
    echo "✅ Real encrypted push completed successfully!"
    
    # Verify the remote directory has encrypted files
    echo
    echo "Checking remote directory contents:"
    ls -la "$REMOTE_DIR"
    
    if [ -f "$REMOTE_DIR/91bd0c092128cf2e60e1a608c31e92caf1f9c1595f83f2890ef17c0e4881aa0a" ]; then
        echo "✅ Manifest file created"
    else
        echo "❌ Manifest file not found"
    fi
    
    # Count encrypted files
    file_count=$(ls -1 "$REMOTE_DIR" | wc -l)
    echo "📁 Remote directory contains $file_count encrypted files"
    
else
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
        echo "⚠️  Push timed out after 60 seconds"
    else
        echo "❌ Push failed with exit code: $exit_code"
    fi
fi

# Cleanup
cd "$OLDPWD"
rm -f "/tmp/git-remote-gcrypt-incremental" "$HELPER_PATH"
rm -rf "$TEST_DIR" "$REMOTE_DIR"

echo
echo "🏁 Real encrypted push test completed"