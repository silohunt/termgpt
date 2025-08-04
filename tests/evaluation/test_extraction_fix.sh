#!/bin/bash

# Test improved command extraction
echo "🔧 Testing Improved Command Extraction"
echo "======================================"
echo

test_cmd="Set up monitoring for disk space usage with email alerts when partitions exceed 85% full"

echo "Query: $test_cmd"
echo

# Current method (broken)
echo "--- Current Method (using xargs) ---"
output=$(../../bin/termgpt --eval "$test_cmd" 2>&1)
current_extraction=$(echo "$output" | grep -A1 "Generated Command:" | tail -1 | xargs 2>/dev/null || echo "EXTRACTION_FAILED")
echo "Raw output:"
echo "$output"
echo
echo "Current extraction: '$current_extraction'"
echo

# Improved method (without xargs)
echo "--- Improved Method (without xargs) ---"
improved_extraction=$(echo "$output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
echo "Improved extraction: '$improved_extraction'"
echo

# Test validation
echo "--- Validation ---"
echo "Current length: ${#current_extraction}"
echo "Improved length: ${#improved_extraction}"
echo "Current valid: $([ -n "$current_extraction" ] && [ ${#current_extraction} -gt 5 ] && [ "$current_extraction" != "EXTRACTION_FAILED" ] && echo "YES" || echo "NO")"
echo "Improved valid: $([ -n "$improved_extraction" ] && [ ${#improved_extraction} -gt 5 ] && echo "YES" || echo "NO")"