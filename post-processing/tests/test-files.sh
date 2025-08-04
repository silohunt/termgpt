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
    actual=$(apply_file_corrections "$input")
    
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

echo "Testing file corrections..."
echo

# Test permission corrections
test_correction "Fix permission syntax -perm -0004" \
    "find . -perm -0004" \
    "find . -perm 644"

test_correction "Fix permission syntax -perm -0002" \
    "find . -perm -0002" \
    "find . -perm 755"

test_correction "Fix permission syntax with leading zero" \
    "find . -perm 0644" \
    "find . -perm 644"

# Test placeholder replacements
test_correction "Replace <log_file> placeholder" \
    "grep ERROR <log_file>" \
    "grep ERROR /var/log/*.log"

test_correction "Replace <pattern> placeholder" \
    "grep <pattern> /var/log/system.log" \
    "grep ERROR /var/log/system.log"

test_correction "Replace <username> placeholder" \
    "find /home/<username> -type f" \
    "find /home/\$USER -type f"

test_correction "Replace path placeholders" \
    "find /path/to/log/files -name '*.log'" \
    "find /var/log -name '*.log'"

test_correction "Replace specific error patterns" \
    "grep 'specific_error_pattern' /var/log/*.log" \
    "grep 'ERROR' /var/log/*.log"

# Test file filtering improvements
test_correction "Add log filter for compression" \
    "find . -type f -exec gzip {} \\;" \
    "find . -name \"*.log\" -type f -exec gzip {} \\;"

test_correction "Fix log path optimization" \
    "find . -name \"*.log\"" \
    "find /var/log -name \"*.log\""

# Test backup exclusions
test_correction "Add git exclusions for backup" \
    "find . -type f -name \"*.conf\" backup" \
    "find . -type f -not -path \"*/.git/*\" -not -path \"*/.svn/*\" -name \"*.conf\" backup"

# Test missing quotes
test_correction "Add quotes to wildcards" \
    "find . -name *.py" \
    "find . -name \"*.py\""

# Summary
echo
echo "File correction tests: $PASSED/$TESTS passed"
[ "$PASSED" -eq "$TESTS" ] && exit 0 || exit 1