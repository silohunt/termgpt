#!/bin/sh
# Test suite for file corrections

# Source the correction module
. "$(dirname "$0")/../corrections/files.sh"

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
    # For tests that need context, use a default query
    local query="${4:-test query}"
    actual=$(apply_file_corrections "$input" "$query")
    
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ $description"
    else
        echo "✗ $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

echo "Running file correction tests..."
echo

# Test log filtering
test_correction "Add .log filter for compression commands" \
    "find . -type f -exec gzip {} \\;" \
    "find /var/log -name \"*.log\" -type f -exec gzip {} \\;"

# Test path correction for logs
test_correction "Use /var/log for log operations" \
    "find . -name \"*.log\" -type f" \
    "find /var/log -name \"*.log\" -type f"

# Test permission corrections
test_correction "Fix wrong permission syntax" \
    "find . -perm -0004" \
    "find . -perm 644"

# Test placeholder replacements
test_correction "Replace username placeholder" \
    "chown <username> file.txt" \
    "chown \$USER file.txt"

test_correction "Replace log file placeholder" \
    "tail -f <log_file>" \
    "tail -f /var/log/*.log"

# Test missing quotes
test_correction "Add quotes to wildcards" \
    "find . -name *.py" \
    "find . -name \"*.py\""

# Test smart scope correction
test_correction "Convert find / to find . for local file searches" \
    "find / -name \"*.py\"" \
    "find . -name \"*.py\"" \
    "list all python files"

test_correction "Convert find / to find . for JavaScript files" \
    "find / -type f -name \"*.js\"" \
    "find . -type f -name \"*.js\"" \
    "find all javascript files"

test_correction "Preserve find / for system-wide searches" \
    "find / -name \"*.conf\"" \
    "find / -name \"*.conf\"" \
    "search the entire system for config files"

test_correction "Preserve find / when user says everywhere" \
    "find / -name \"*.py\"" \
    "find / -name \"*.py\"" \
    "search everywhere for python files"

test_correction "Convert find / for other programming languages" \
    "find / -name \"*.go\"" \
    "find . -name \"*.go\"" \
    "find all go files"

# Summary
echo
echo "File correction tests: $PASSED/$TESTS passed"
[ "$PASSED" -eq "$TESTS" ] && exit 0 || exit 1