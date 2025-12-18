#!/bin/bash

# Test real Git push with our incremental helper

set -e

echo "🚀 Testing Real Git Push"
echo "========================"

# Create test repository
TEST_DIR="/tmp/real_git_push_test_$$"
REMOTE_DIR="/tmp/real_git_remote_$$"
mkdir -p "$TEST_DIR" "$REMOTE_DIR"
cd "$TEST_DIR"

echo "Setting up test repository..."
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create initial commit
echo "# Test Repository for Real Git Push" > README.md
echo "This tests the actual Git integration" >> README.md
git add README.md
git commit -m "Initial commit for Git push test"

# Install our helper temporarily
HELPER_PATH="/tmp/git-remote-gcrypt-incremental-$$"
cp "$OLDPWD/git-remote-gcrypt-incremental" "$HELPER_PATH"
chmod +x "$HELPER_PATH"

# Add to PATH
export PATH="/tmp:$PATH"

# Create symlink with expected name
ln -sf "$HELPER_PATH" "/tmp/git-remote-gcrypt-incremental"

echo "✅ Repository and helper setup complete"
echo

# Configure remote
echo "Configuring remote..."
git remote add origin "gcrypt-incremental::file://$REMOTE_DIR"
git config remote.origin.gcrypt-incremental-branch "master"

echo "Remote configuration:"
git remote -v
echo "Incremental branch: $(git config remote.origin.gcrypt-incremental-branch)"
echo

# Test Git push with timeout to prevent hanging
echo "Testing Git push (with 30 second timeout)..."
export GCRYPT_DEBUG=1

# Use timeout to prevent hanging
if timeout 30s git push origin master 2>&1; then
    echo "✅ Git push completed successfully!"
else
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
        echo "⚠️  Git push timed out after 30 seconds"
        echo "This might indicate the helper is waiting for input or hanging"
    else
        echo "❌ Git push failed with exit code: $exit_code"
    fi
fi

echo
echo "Checking what Git actually sent to our helper..."
echo "If the push worked, our helper should have received the standard commands."

# Cleanup
cd "$OLDPWD"
rm -f "/tmp/git-remote-gcrypt-incremental" "$HELPER_PATH"
rm -rf "$TEST_DIR" "$REMOTE_DIR"

echo
echo "🏁 Real Git push test completed"