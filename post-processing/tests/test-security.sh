#!/bin/sh

# Test suite for security corrections

# Source the security module to test
. "$(dirname "$0")/../corrections/security.sh"

# Test counter
TESTS=0
PASSED=0

# Test function
test_correction() {
    local description="$1"
    local input="$2"
    local expected="$3"
    local actual
    
    TESTS=$((TESTS + 1))
    actual=$(apply_security_corrections "$input")
    
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ $description"
    else
        echo "✗ $description"
        echo "  Input:    $input"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

echo "Testing security corrections (focused on improvements not covered by rules system)..."

echo ""
echo "Testing find -exec safety..."

# Test find -exec quoting
test_correction "Add quotes to find -exec rm" \
    "find /tmp -name '*.tmp' -exec rm {} \\;" \
    "find /tmp -name '*.tmp' -exec rm '{}' \\;"

test_correction "Add quotes to find -exec with path" \
    "find . -type f -exec chmod 644 {} +" \
    "find . -type f -exec chmod 644 '{}' +"

test_correction "Keep already quoted find -exec" \
    "find . -name '*.log' -exec gzip '{}' \\;" \
    "find . -name '*.log' -exec gzip '{}' \\;"

echo ""
echo "Testing wget/curl output safety..."

# Test wget without output file
test_correction "Add safe output to wget" \
    "wget http://example.com/file.zip" \
    "wget -O file.zip http://example.com/file.zip"

test_correction "Keep wget with output" \
    "wget -O myfile.zip http://example.com/file.zip" \
    "wget -O myfile.zip http://example.com/file.zip"

test_correction "Add safe output to curl" \
    "curl http://example.com/script.sh" \
    "curl -o script.sh http://example.com/script.sh"

test_correction "Keep curl with output" \
    "curl -o output.txt http://example.com/data" \
    "curl -o output.txt http://example.com/data"

echo ""
echo "Testing shell injection prevention..."

# Test command substitution safety
test_correction "Quote command substitution in echo" \
    "echo \$(whoami)" \
    "echo \"\$(whoami)\""

test_correction "Quote backticks in echo" \
    "echo \`date\`" \
    "echo \"\`date\`\""

test_correction "Keep already quoted substitution" \
    "echo \"\$(pwd)\"" \
    "echo \"\$(pwd)\""

# Print test summary
echo ""
echo "Test Summary: $PASSED/$TESTS tests passed"
if [ "$PASSED" -eq "$TESTS" ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi