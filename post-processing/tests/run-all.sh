#!/bin/sh
# Run all post-processing tests

SCRIPT_DIR="$(dirname "$0")"
TOTAL_TESTS=0
TOTAL_PASSED=0

echo "Running all post-processing tests..."
echo "=================================="
echo

# Run each test suite
for test_file in "$SCRIPT_DIR"/test-*.sh; do
    if [ -f "$test_file" ] && [ "$test_file" != "$0" ]; then
        echo "Running $(basename "$test_file")..."
        echo "-----------------------------------"
        if sh "$test_file"; then
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        echo
    fi
done

# Summary
echo "=================================="
echo "Overall Results: $TOTAL_PASSED/$TOTAL_TESTS test suites passed"
echo

if [ "$TOTAL_PASSED" -eq "$TOTAL_TESTS" ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed"
    exit 1
fi