#!/bin/bash
# Test all commands from commands.txt
# Uses interactive mode to avoid --eval verbose response issue

set -e

echo "Testing all commands from commands.txt"
echo "======================================"
echo ""

# Extract commands (skip comments and empty lines)
COMMANDS=$(grep -v '^#' commands.txt | grep -v '^$')
TOTAL=$(echo "$COMMANDS" | wc -l | tr -d ' ')

echo "Total commands to test: $TOTAL"
echo ""

SUCCESS=0
VERBOSE=0
FAILED=0
RESULTS_FILE="test_results_$(date +%Y%m%d_%H%M%S).txt"

echo "Testing started at $(date)" > "$RESULTS_FILE"
echo "Model: ${TERMGPT_MODEL:-codellama:7b-instruct}" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TEMP_COUNTS=$(mktemp)
echo "0 0 0" > "$TEMP_COUNTS"

while IFS= read -r QUERY; do
    # Read current counts
    read SUCCESS VERBOSE FAILED < "$TEMP_COUNTS"
    COUNT=$((SUCCESS + VERBOSE + FAILED + 1))
    
    echo "[$COUNT/$TOTAL] Testing: $QUERY"
    echo "----------------------------------------" >> "$RESULTS_FILE"
    echo "[$COUNT] Query: $QUERY" >> "$RESULTS_FILE"
    
    # Use interactive mode (not --eval) - with retry logic enabled
    RAW_OUTPUT=$(echo "q" | ../../bin/termgpt "$QUERY" 2>&1)
    
    # Extract the command (after "Generated Command:")
    CMD=$(echo "$RAW_OUTPUT" | grep -A1 "Generated Command:" | tail -n 1 | sed 's/^[[:space:]]*//' | sed 's/^[$] //')
    
    if [ -z "$CMD" ] || echo "$CMD" | grep -q "^Options:"; then
        echo "  ❌ Failed to generate command" | tee -a "$RESULTS_FILE"
        FAILED=$((FAILED + 1))
    elif echo "$CMD" | grep -q "^To \|^This command\|^The command\|^Here's\|^Here is\|^You can\|^[0-9]\. "; then
        echo "  ⚠️  Verbose response: $CMD" | tee -a "$RESULTS_FILE"
        VERBOSE=$((VERBOSE + 1))
    else
        echo "  ✅ Command: $CMD" | tee -a "$RESULTS_FILE"
        SUCCESS=$((SUCCESS + 1))
    fi
    
    echo "" >> "$RESULTS_FILE"
    
    # Update temp counts file
    echo "$SUCCESS $VERBOSE $FAILED" > "$TEMP_COUNTS"
    
    # Small delay to avoid overwhelming the LLM
    sleep 0.5
done <<< "$COMMANDS"

# Read final counts
read SUCCESS VERBOSE FAILED < "$TEMP_COUNTS"
rm -f "$TEMP_COUNTS"

echo ""
echo "========================================"
echo "Results Summary:"
echo "  Total: $TOTAL"
echo "  Success: $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
echo "  Verbose: $VERBOSE ($(( VERBOSE * 100 / TOTAL ))%)"
echo "  Failed: $FAILED ($(( FAILED * 100 / TOTAL ))%)"
echo ""
echo "Detailed results saved to: $RESULTS_FILE"

# Add summary to results file
echo "" >> "$RESULTS_FILE"
echo "=======================================" >> "$RESULTS_FILE"
echo "Summary:" >> "$RESULTS_FILE"
echo "  Total: $TOTAL" >> "$RESULTS_FILE"
echo "  Success: $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)" >> "$RESULTS_FILE"
echo "  Verbose: $VERBOSE ($(( VERBOSE * 100 / TOTAL ))%)" >> "$RESULTS_FILE"
echo "  Failed: $FAILED ($(( FAILED * 100 / TOTAL ))%)" >> "$RESULTS_FILE"