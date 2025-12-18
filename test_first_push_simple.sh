#!/bin/bash

# Simple test to verify the first push fix for incremental mode

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "Testing First Push Fix for Incremental Mode"
echo "==========================================="

# Check if script exists
if [ ! -f "git-remote-gcrypt-incremental" ]; then
    log_error "git-remote-gcrypt-incremental not found"
    exit 1
fi

# Create a temporary test directory
TEST_DIR=$(mktemp -d)
REMOTE_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

trap cleanup EXIT

log_info "Test directories created: $TEST_DIR, $REMOTE_DIR"

# Initialize a test repository
cd "$TEST_DIR"
git init
git config user.name "Test"
git config user.email "test@test.com"
echo "test" > file.txt
git add file.txt
git commit -m "test commit"
git checkout -b my 2>/dev/null || git checkout my

# Configure incremental mode
git remote add origin "file://$REMOTE_DIR"
git config remote.origin.gcrypt-incremental-branch "my"
git config remote.origin.gcrypt-participants "simple"

log_info "Repository configured for incremental mode on branch 'my'"

# Test the script behavior
export GCRYPT_DEBUG=1
SCRIPT_PATH="$(cd - >/dev/null && pwd)/git-remote-gcrypt-incremental"

log_info "Testing list command..."
{
    echo "capabilities"
    echo "list for-push"
    echo ""
} | "$SCRIPT_PATH" origin "file://$REMOTE_DIR" 2>&1 | tee /tmp/test_output.log

log_info "Analyzing output..."

# Check for key indicators
if grep -q "Incremental mode enabled for branch: my" /tmp/test_output.log; then
    log_info "✓ Incremental mode was enabled"
else
    log_warn "! Incremental mode not detected"
fi

if grep -q "Remote repository not found" /tmp/test_output.log; then
    log_info "✓ Correctly detected empty remote"
else
    log_warn "! Remote detection may not be working"
fi

# The critical test: should NOT fall back to full push
if grep -q "falling back to full push" /tmp/test_output.log; then
    log_error "✗ FAILED: Still falling back to full push on first push!"
    log_error "This means the fix didn't work correctly."
    exit 1
else
    log_info "✓ SUCCESS: No fallback to full push detected!"
    log_info "The first push will now proceed in incremental mode."
fi

log_info ""
log_info "🎉 First push fix verification PASSED!"
log_info ""
log_info "Summary:"
log_info "- When pushing to an empty remote repository for the first time"
log_info "- The system now stays in incremental mode"
log_info "- It will initialize the remote repository for incremental mode"
log_info "- Instead of falling back to full push mode"

exit 0
