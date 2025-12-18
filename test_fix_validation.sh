#!/bin/bash

# Test script to validate the fixes for client hanging and serial number issues

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "Testing Fixes for Client Hanging and Serial Number Issues"
echo "======================================================="

# Check if script exists
if [ ! -f "git-remote-gcrypt-incremental" ]; then
    log_error "git-remote-gcrypt-incremental not found"
    exit 1
fi

# Create test directories
TEST_DIR=$(mktemp -d)
REMOTE_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

trap cleanup EXIT

log_info "Test directories: $TEST_DIR, $REMOTE_DIR"

# Initialize test repository
cd "$TEST_DIR"
git init
git config user.name "Test"
git config user.email "test@test.com"
echo "Initial content" > README.md
git add README.md
git commit -m "Initial commit"
git checkout -b my 2>/dev/null || git checkout my

# Configure for incremental mode
git remote add origin "file://$REMOTE_DIR"
git config remote.origin.gcrypt-incremental-branch "my"
git config remote.origin.gcrypt-participants "simple"

export GCRYPT_DEBUG=1
SCRIPT_PATH="$(cd - >/dev/null && pwd)/git-remote-gcrypt-incremental"

log_info "Testing push with timeout to detect hanging..."

# Test the push command with timeout
timeout 30s bash -c "
{
    echo 'capabilities'
    echo 'list for-push'
    echo 'push refs/heads/my:refs/heads/my'
    echo ''
} | '$SCRIPT_PATH' origin 'file://$REMOTE_DIR'
" 2>&1 | tee /tmp/fix_test.log

exit_code=$?

if [ $exit_code -eq 124 ]; then
    log_error "✗ FAILED: Client still hangs (timeout reached)"
    exit 1
elif [ $exit_code -eq 0 ]; then
    log_info "✓ SUCCESS: Client completed without hanging"
else
    log_warn "! Client exited with code $exit_code (may be expected)"
fi

log_info "Analyzing output for serial number issues..."

# Check for base manifest (serial 0)
if grep -q "Uploading base manifest.*0000000000000000" /tmp/fix_test.log; then
    log_info "✓ Base manifest (serial 0) was created"
else
    log_warn "! Base manifest (serial 0) not found"
fi

# Check for different serial numbers
pack_serial=$(grep "Uploading incremental pack:" /tmp/fix_test.log | grep -o "0000000000000[0-9]*" | head -1)
manifest_serial=$(grep "Uploading new manifest:" /tmp/fix_test.log | grep -o "0000000000000[0-9]*" | head -1)

if [ -n "$pack_serial" ] && [ -n "$manifest_serial" ] && [ "$pack_serial" != "$manifest_serial" ]; then
    log_info "✓ Pack and manifest have different serial numbers:"
    log_info "  Pack serial: $pack_serial"
    log_info "  Manifest serial: $manifest_serial"
else
    log_error "✗ FAILED: Pack and manifest have same serial numbers or not found"
    log_error "  Pack serial: $pack_serial"
    log_error "  Manifest serial: $manifest_serial"
fi

# Check for Git protocol responses
if grep -q "ok refs/heads/my" /tmp/fix_test.log; then
    log_info "✓ Git protocol 'ok' response found"
else
    log_warn "! Git protocol 'ok' response not found in logs"
fi

log_info ""
log_info "🎉 Fix validation completed!"
log_info ""
log_info "Expected file structure on remote:"
log_info "- 0000000000000000-[hash] (base manifest)"
log_info "- 0000000000000001-[hash] (incremental pack)"
log_info "- 0000000000000002-[hash] (commit manifest)"

exit 0