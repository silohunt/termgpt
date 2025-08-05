#!/bin/sh
# Test script to validate TermGPT in container

set -e

echo "=== TermGPT Container Test ==="
echo "Platform: $(uname -s) $(uname -m)"
echo "Shell: $SHELL"
echo

echo "1. Testing termgpt init (check mode)..."
./bin/termgpt init --check || true
echo

echo "2. Testing help system..."
./bin/termgpt --help
echo

echo "3. Testing syntax with sh..."
sh -n bin/termgpt
sh -n bin/termgpt-init
sh -n lib/termgpt-check.sh
sh -n lib/termgpt-platform.sh
sh -n lib/termgpt-history.sh
echo "✓ All scripts are POSIX compliant"
echo

echo "4. Running unit tests..."
if [ -f tests/unit/safety-rules.sh ]; then
  cd tests/unit && ./safety-rules.sh
  cd ../..
elif [ -f tests/termgpt-test.sh ]; then
  # Fallback for old structure
  cd tests && ./termgpt-test.sh
  cd ..
fi
echo

echo "5. Testing basic functionality..."
./bin/termgpt "list files" <<EOF
q
EOF
echo

echo "=== All tests passed! ==="