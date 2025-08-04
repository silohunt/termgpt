#!/bin/sh
# Test suite for time corrections

# Source the correction module
. "$(dirname "$0")/../corrections/time.sh"

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
    actual=$(apply_time_corrections "$input")
    
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

echo "Testing time corrections..."
echo

# Test mtime corrections
test_correction "Fix mtime +7 to -7" \
    "find . -mtime +7 -name '*.log'" \
    "find . -mtime -7 -name '*.log'"

test_correction "Fix mtime +30 to -30" \
    "find /var/log -mtime +30 -delete" \
    "find /var/log -mtime -30 -delete"

test_correction "Fix mtime +1 to -1" \
    "find . -mtime +1" \
    "find . -mtime -1"

test_correction "Don't change mtime -7" \
    "find . -mtime -7" \
    "find . -mtime -7"

test_correction "Fix multiple mtime in one command" \
    "find . -mtime +7 -o -mtime +30" \
    "find . -mtime -7 -o -mtime -30"

# Test ctime corrections
test_correction "Fix ctime +7 to -7" \
    "find . -ctime +7" \
    "find . -ctime -7"

test_correction "Fix ctime +30 to -30" \
    "find /tmp -ctime +30 -exec rm {} \;" \
    "find /tmp -ctime -30 -exec rm {} \;"

# Test atime corrections
test_correction "Fix atime +7 to -7" \
    "find . -atime +7" \
    "find . -atime -7"

# Test context awareness
test_correction "Fix 'last N days' pattern" \
    "find logs from last 5 days -mtime +5" \
    "find logs from last 5 days -mtime -5"

# Edge cases
test_correction "Don't change non-time +7" \
    "calculate 5 + 7" \
    "calculate 5 + 7"

test_correction "Handle complex find command" \
    "find . -type f -mtime +7 -size +100M -exec gzip {} \;" \
    "find . -type f -mtime -7 -size +100M -exec gzip {} \;"

# Test context-aware corrections (requires setting original query)
export TERMGPT_ORIGINAL_QUERY="delete backup files older than 30 days"
test_correction "Context: older than should use +N" \
    "find . -mtime -30 -delete" \
    "find . -mtime +30 -delete"

export TERMGPT_ORIGINAL_QUERY="find files from last week"  
test_correction "Context: last week should use -N" \
    "find . -mtime +7" \
    "find . -mtime -7"

export TERMGPT_ORIGINAL_QUERY="show files created yesterday"
test_correction "Context: yesterday should use -1" \
    "find . -mtime 1" \
    "find . -mtime -1"

# Clean up
unset TERMGPT_ORIGINAL_QUERY

# Summary
echo
echo "Time correction tests: $PASSED/$TESTS passed"
[ "$PASSED" -eq "$TESTS" ] && exit 0 || exit 1