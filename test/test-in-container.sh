#!/bin/sh
# Test script to validate TermGPT in container

set -e

echo "=== TermGPT Container Test ==="
echo "Platform: $(uname -s) $(uname -m)"
echo "Shell: $SHELL"
echo

echo "1. Testing setup.sh (dry run)..."
echo "n" | ./setup.sh || true
echo

echo "2. Testing uninstaller..."
./uninstall.sh --dry-run
echo

echo "3. Testing syntax with sh..."
sh -n bin/termgpt
sh -n lib/termgpt-check.sh
sh -n lib/termgpt-platform.sh
sh -n lib/termgpt-history.sh
echo "✓ All scripts are POSIX compliant"
echo

echo "4. Running unit tests..."
cd tests && ./termgpt-test.sh
cd ..
echo

echo "5. Testing basic functionality..."
./bin/termgpt "list files" <<EOF
q
EOF
echo

echo "=== All tests passed! ==="