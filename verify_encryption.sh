#!/bin/bash

# Verify that the encryption is working correctly

set -e

echo "🔍 Verifying Encryption Functionality"
echo "====================================="

# Create test repository
TEST_DIR="/tmp/verify_encryption_$$"
REMOTE_DIR="/tmp/verify_remote_$$"
mkdir -p "$TEST_DIR" "$REMOTE_DIR"
cd "$TEST_DIR"

echo "Setting up test repository..."
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create test content
echo "# Secret Repository" > README.md
echo "This content should be encrypted!" >> README.md
echo "Secret data: $(date)" >> README.md
git add README.md
git commit -m "Secret commit with sensitive data"

# Install our helper
HELPER_PATH="/tmp/git-remote-gcrypt-incremental-verify-$$"
cp "$OLDPWD/git-remote-gcrypt-incremental" "$HELPER_PATH"
chmod +x "$HELPER_PATH"
ln -sf "$HELPER_PATH" "/tmp/git-remote-gcrypt-incremental"
export PATH="/tmp:$PATH"

# Configure remote
git remote add origin "gcrypt-incremental::file://$REMOTE_DIR"
git config remote.origin.gcrypt-participants "simple"
git config remote.origin.gcrypt-incremental-branch "master"

echo "✅ Setup complete"
echo

# Perform encrypted push
echo "Performing encrypted push..."
export GCRYPT_DEBUG=1
git push origin master

echo
echo "🔍 Verifying encryption..."

# Check remote directory
echo "Remote directory contents:"
ls -la "$REMOTE_DIR"

echo
echo "Checking if files are encrypted (should not contain plaintext):"

# Check each file for plaintext content
for file in "$REMOTE_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "Checking file: $filename"
        
        # These strings should NOT appear in encrypted files
        if grep -q "Secret Repository" "$file" 2>/dev/null; then
            echo "❌ SECURITY ISSUE: Plaintext found in $filename"
        elif grep -q "Secret data" "$file" 2>/dev/null; then
            echo "❌ SECURITY ISSUE: Plaintext found in $filename"
        elif grep -q "This content should be encrypted" "$file" 2>/dev/null; then
            echo "❌ SECURITY ISSUE: Plaintext found in $filename"
        else
            echo "✅ File $filename appears to be encrypted (no plaintext found)"
        fi
        
        # Show first few bytes to verify it looks encrypted
        echo "First 50 bytes of $filename:"
        head -c 50 "$file" | hexdump -C
        echo
    fi
done

# Test that we can clone and decrypt
echo "🔄 Testing decryption by cloning..."
CLONE_DIR="/tmp/verify_clone_$$"
mkdir -p "$CLONE_DIR"
cd "$CLONE_DIR"

# Clone the encrypted repository
if git clone "gcrypt-incremental::file://$REMOTE_DIR" decrypted_repo; then
    echo "✅ Successfully cloned and decrypted repository"
    
    cd decrypted_repo
    echo "Decrypted content:"
    cat README.md
    
    # Verify the content matches
    if grep -q "Secret Repository" README.md && grep -q "This content should be encrypted" README.md; then
        echo "✅ Decrypted content matches original"
    else
        echo "❌ Decrypted content does not match original"
    fi
else
    echo "❌ Failed to clone encrypted repository"
fi

# Cleanup
cd "$OLDPWD"
rm -f "/tmp/git-remote-gcrypt-incremental" "$HELPER_PATH"
rm -rf "$TEST_DIR" "$REMOTE_DIR" "$CLONE_DIR"

echo
echo "🏁 Encryption verification completed"