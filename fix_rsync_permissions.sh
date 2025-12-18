#!/bin/bash

# Quick fix for rsync permission issues

set -e

echo "🔧 Git Remote Gcrypt - Rsync Permission Fix"
echo "==========================================="

# Extract remote info from git config
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

if [ -z "$REMOTE_URL" ]; then
    echo "❌ No remote.origin.url found. Please configure your remote first."
    exit 1
fi

echo "Current remote URL: $REMOTE_URL"

# Parse rsync URL
if [[ "$REMOTE_URL" =~ gcrypt-incremental::rsync://([^/]+)(.*) ]]; then
    HOST_USER="${BASH_REMATCH[1]}"
    REMOTE_PATH="${BASH_REMATCH[2]}"
    
    echo "Host/User: $HOST_USER"
    echo "Remote path: $REMOTE_PATH"
    
    # Extract just the host part for SSH commands
    if [[ "$HOST_USER" =~ (.*)@(.*) ]]; then
        USER="${BASH_REMATCH[1]}"
        HOST="${BASH_REMATCH[2]}"
    else
        USER="$(whoami)"
        HOST="$HOST_USER"
    fi
    
    echo "SSH User: $USER"
    echo "SSH Host: $HOST"
    echo
    
    # Test SSH connection
    echo "Testing SSH connection..."
    if ssh -o ConnectTimeout=10 "$USER@$HOST" "echo 'SSH connection successful'"; then
        echo "✅ SSH connection works"
    else
        echo "❌ SSH connection failed. Please check:"
        echo "   1. Host is reachable: ping $HOST"
        echo "   2. SSH service is running on $HOST"
        echo "   3. SSH keys are configured: ssh-copy-id $USER@$HOST"
        exit 1
    fi
    
    echo
    echo "Creating and configuring remote directory..."
    
    # Create remote directory and set permissions
    if ssh "$USER@$HOST" "mkdir -p '$REMOTE_PATH' && chmod 755 '$REMOTE_PATH' && ls -la '$REMOTE_PATH'"; then
        echo "✅ Remote directory created and configured"
    else
        echo "❌ Failed to create remote directory. Trying alternative path..."
        
        # Try alternative path in user's home directory
        ALT_PATH="gcrypt-repo"
        echo "Trying alternative path: ~/$ALT_PATH"
        
        if ssh "$USER@$HOST" "mkdir -p '$ALT_PATH' && chmod 755 '$ALT_PATH'"; then
            echo "✅ Alternative directory created"
            
            # Update git remote URL
            NEW_URL="gcrypt-incremental::rsync://$USER@$HOST:$ALT_PATH"
            git remote set-url origin "$NEW_URL"
            echo "✅ Updated remote URL to: $NEW_URL"
        else
            echo "❌ Failed to create alternative directory"
            exit 1
        fi
    fi
    
    echo
    echo "Configuring rsync parameters..."
    
    # Configure rsync flags for better compatibility
    git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"
    echo "✅ Configured rsync flags: $(git config --get remote.origin.gcrypt-rsync-put-flags)"
    
    # Ensure other required configs are set
    if [ -z "$(git config --get remote.origin.gcrypt-participants 2>/dev/null)" ]; then
        git config remote.origin.gcrypt-participants "simple"
        echo "✅ Set gcrypt-participants to 'simple'"
    fi
    
    if [ -z "$(git config --get remote.origin.gcrypt-incremental-branch 2>/dev/null)" ]; then
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "master")
        git config remote.origin.gcrypt-incremental-branch "$CURRENT_BRANCH"
        echo "✅ Set gcrypt-incremental-branch to '$CURRENT_BRANCH'"
    fi
    
    echo
    echo "Testing rsync upload..."
    
    # Create a test file and try to upload it
    TEST_FILE="/tmp/gcrypt_test_$$"
    echo "test content $(date)" > "$TEST_FILE"
    
    if rsync --chmod=D755,F644 -v "$TEST_FILE" "$USER@$HOST:$REMOTE_PATH/test_upload"; then
        echo "✅ Rsync upload test successful"
        
        # Clean up test file
        ssh "$USER@$HOST" "rm -f '$REMOTE_PATH/test_upload'"
        rm -f "$TEST_FILE"
        
        echo
        echo "🎉 Configuration complete! You can now try:"
        echo "   export GCRYPT_DEBUG=1"
        echo "   git push origin $(git branch --show-current 2>/dev/null || echo "master")"
        
    else
        echo "❌ Rsync upload test failed"
        rm -f "$TEST_FILE"
        
        echo
        echo "💡 Manual troubleshooting steps:"
        echo "1. Check remote directory permissions:"
        echo "   ssh $USER@$HOST 'ls -la $(dirname "$REMOTE_PATH")'"
        echo
        echo "2. Try a different remote path:"
        echo "   git remote set-url origin gcrypt-incremental::rsync://$USER@$HOST:/tmp/gcrypt-test"
        echo
        echo "3. Test manual rsync:"
        echo "   echo 'test' > /tmp/test && rsync /tmp/test $USER@$HOST:/tmp/"
        
        exit 1
    fi
    
else
    echo "❌ URL format not recognized. Expected: gcrypt-incremental::rsync://user@host/path"
    echo "Current URL: $REMOTE_URL"
    echo
    echo "Please set the correct remote URL:"
    echo "   git remote set-url origin gcrypt-incremental::rsync://user@host/path"
    exit 1
fi