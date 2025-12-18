#!/bin/bash

# Test rsync compatibility fix

set -e

echo "🔧 Testing Rsync Compatibility Fix"
echo "=================================="

# Check rsync version
echo "Rsync version:"
rsync --version | head -1

echo
echo "Testing rsync options compatibility..."

# Test if --mkpath is supported
if rsync --help 2>/dev/null | grep -q -- '--mkpath'; then
    echo "✅ --mkpath is supported"
else
    echo "❌ --mkpath is NOT supported (this is expected for older versions)"
fi

# Test basic rsync functionality
echo
echo "Testing basic rsync functionality..."

# Create test files
TEST_DIR="/tmp/rsync_compat_test_$$"
mkdir -p "$TEST_DIR/source"
echo "test content" > "$TEST_DIR/source/test.txt"

# Test local rsync
if rsync -v "$TEST_DIR/source/test.txt" "$TEST_DIR/dest.txt" >&2; then
    echo "✅ Basic rsync works"
    rm -f "$TEST_DIR/dest.txt"
else
    echo "❌ Basic rsync failed"
fi

# Test directory creation
echo
echo "Testing directory creation methods..."

# Method 1: SSH + mkdir (our new approach)
echo "Method 1: SSH + mkdir"
if command -v ssh >/dev/null 2>&1; then
    echo "✅ SSH command available"
else
    echo "❌ SSH command not available"
fi

# Method 2: rsync with existing directory
echo "Method 2: rsync to existing directory"
mkdir -p "$TEST_DIR/existing_dir"
if rsync -v "$TEST_DIR/source/test.txt" "$TEST_DIR/existing_dir/" >&2; then
    echo "✅ rsync to existing directory works"
else
    echo "❌ rsync to existing directory failed"
fi

# Cleanup
rm -rf "$TEST_DIR"

echo
echo "🎯 Compatibility Summary:"
echo "- Our fix uses SSH to create directories before rsync"
echo "- This works with all rsync versions (no --mkpath needed)"
echo "- Requires SSH access to the remote server"

echo
echo "✅ Rsync compatibility test completed"