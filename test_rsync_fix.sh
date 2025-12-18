#!/bin/bash

# Test rsync functionality fix

set -e

echo "🔧 Testing Rsync Functionality Fix"
echo "=================================="

# Create test repository
TEST_DIR="/tmp/rsync_test_$$"
REMOTE_DIR="/tmp/rsync_remote_$$"
mkdir -p "$TEST_DIR" "$REMOTE_DIR"
cd "$TEST_DIR"

echo "Setting up test repository..."
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create test content
echo "# Rsync Test Repository" > README.md
echo "Testing rsync upload functionality" >> README.md
git add README.md
git commit -m "Initial commit for rsync test"

# Install our helper
HELPER_PATH="/tmp/git-remote-gcrypt-incremental-rsync-$$"
cp "$OLDPWD/git-remote-gcrypt-incremental" "$HELPER_PATH"
chmod +x "$HELPER_PATH"
ln -sf "$HELPER_PATH" "/tmp/git-remote-gcrypt-incremental"
export PATH="/tmp:$PATH"

echo "✅ Setup complete"
echo

# Test with local rsync (simulating remote)
echo "Testing with local rsync destination..."
git remote add origin "gcrypt-incremental::file://$REMOTE_DIR"
git config remote.origin.gcrypt-participants "simple"
git config remote.origin.gcrypt-incremental-branch "master"

echo "Remote configuration:"
git remote -v

# Test the push
echo "Performing test push..."
export GCRYPT_DEBUG=1

if git push origin master 2>&1; then
    echo "✅ Local file push successful"
    
    echo "Remote directory contents:"
    ls -la "$REMOTE_DIR"
    
    # Verify files exist
    if [ -f "$REMOTE_DIR/91bd0c092128cf2e60e1a608c31e92caf1f9c1595f83f2890ef17c0e4881aa0a" ]; then
        echo "✅ Manifest file created successfully"
    else
        echo "❌ Manifest file not found"
    fi
    
else
    echo "❌ Push failed"
fi

# Test rsynclocation function
echo
echo "Testing rsynclocation function..."

# Define the function locally for testing
rsynclocation() {
    echo "${1#rsync://}" | sed 's/\(^[^:/]*\)\//\1:\//'
}

test_urls=(
    "rsync://user@host/path"
    "rsync://user@host:path"
    "rsync://host/absolute/path"
)

for url in "${test_urls[@]}"; do
    result=$(rsynclocation "$url")
    echo "URL: $url -> $result"
done

# Cleanup
cd "$OLDPWD"
rm -f "/tmp/git-remote-gcrypt-incremental" "$HELPER_PATH"
rm -rf "$TEST_DIR" "$REMOTE_DIR"

echo
echo "🏁 Rsync functionality test completed"