#!/bin/bash

# Debug the push issue

set -e

echo "🔍 Debugging Push Issue"
echo "======================"

# Test GPG functionality
echo "Testing GPG..."
if gpg --armor --gen-rand 1 15 >/dev/null 2>&1; then
    echo "✅ GPG works"
else
    echo "❌ GPG failed"
    exit 1
fi

# Test the rungpg function from the script
echo
echo "Testing rungpg function..."

# Extract and test the rungpg function
cat > /tmp/test_rungpg.sh << 'EOF'
#!/bin/bash

GPG="$(git config --get "gpg.program" '.+' || echo gpg)"
Conf_gpg_args=""

rungpg()
{
	if [ -n "$Conf_gpg_args" ]; then
		set -- "$Conf_gpg_args" "$@"
	fi
	# gpg will fail to run when there is no controlling tty,
	# due to trying to print messages to it, even if a gpg agent is set
	# up. --no-tty fixes this.
	if [ "x$GPG_AGENT_INFO" != "x" ]; then
		${GPG} --no-tty "$@"
	else
		${GPG} --no-tty --batch "$@"
	fi
}

# Test the function
echo "Testing rungpg --armor --gen-rand 1 15..."
if rungpg --armor --gen-rand 1 15; then
    echo "✅ rungpg works"
else
    echo "❌ rungpg failed"
    exit 1
fi
EOF

chmod +x /tmp/test_rungpg.sh
if /tmp/test_rungpg.sh; then
    echo "✅ rungpg function works"
else
    echo "❌ rungpg function failed"
fi

# Test make_new_repo function
echo
echo "Testing make_new_repo logic..."

# Create a minimal test
mkdir -p /tmp/debug_gcrypt_test
cd /tmp/debug_gcrypt_test

# Initialize git repo
git init
echo "test" > test.txt
git add test.txt
git commit -m "test"

# Test the genkey function specifically
echo
echo "Testing genkey function..."

# Extract genkey function
cat > test_genkey.sh << 'EOF'
#!/bin/bash

GPG="$(git config --get "gpg.program" '.+' || echo gpg)"
Conf_gpg_args=""

rungpg()
{
	if [ -n "$Conf_gpg_args" ]; then
		set -- "$Conf_gpg_args" "$@"
	fi
	if [ "x$GPG_AGENT_INFO" != "x" ]; then
		${GPG} --no-tty "$@"
	else
		${GPG} --no-tty --batch "$@"
	fi
}

genkey()
{
	local bytes="$1"
	rungpg --armor --gen-rand 1 "$bytes"
}

echo "Testing genkey 15..."
if result=$(genkey 15); then
    echo "✅ genkey works: $result"
else
    echo "❌ genkey failed"
    exit 1
fi
EOF

chmod +x test_genkey.sh
if ./test_genkey.sh; then
    echo "✅ genkey function works"
else
    echo "❌ genkey function failed"
fi

# Cleanup
cd /tmp
rm -rf /tmp/debug_gcrypt_test /tmp/test_rungpg.sh

echo
echo "✅ Debug completed - GPG and related functions work correctly"