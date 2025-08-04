#!/bin/bash

# Focused Evaluation Script - Test 10 representative commands first
set -e

echo "🔍 Focused Evaluation: Testing 10 Representative Commands"
echo

# Test commands that represent different complexity levels
test_commands=(
    "Find all processes consuming more than 500MB of memory"
    "Show files larger than 1GB modified in the last week"
    "List all processes listening on port 80 or 443"
    "Find log files older than 30 days and compress them"
    "Show network connections from last hour"
    "Find duplicate files in home directory"
    "Monitor CPU usage and alert if over 90%"
    "Search for files containing credit card patterns"
    "Create backup script with rotation"
    "Find world-writable files in system directories"
)

total=0
llm_success=0
postproc_success=0

for i in "${!test_commands[@]}"; do
    query="${test_commands[$i]}"
    num=$((i + 1))
    
    echo "[$num/10] Testing: $query"
    
    # Test LLM baseline
    export TERMGPT_DISABLE_POSTPROCESSING=1
    llm_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    llm_cmd=$(echo "$llm_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    unset TERMGPT_DISABLE_POSTPROCESSING
    
    # Test with post-processing
    postproc_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    postproc_cmd=$(echo "$postproc_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Simple validation: command exists, starts with valid command, reasonable length
    llm_valid=0
    if [[ -n "$llm_cmd" ]] && [[ ${#llm_cmd} -gt 5 ]] && [[ "$llm_cmd" =~ ^[a-zA-Z] ]] && [[ "$llm_cmd" != *"Error"* ]] && [[ "$llm_cmd" != *"ERROR"* ]]; then
        llm_valid=1
    fi
    
    postproc_valid=0
    if [[ -n "$postproc_cmd" ]] && [[ ${#postproc_cmd} -gt 5 ]] && [[ "$postproc_cmd" =~ ^[a-zA-Z] ]] && [[ "$postproc_cmd" != *"Error"* ]] && [[ "$postproc_cmd" != *"ERROR"* ]]; then
        postproc_valid=1
    fi
    
    # Update counters
    total=$((total + 1))
    llm_success=$((llm_success + llm_valid))
    postproc_success=$((postproc_success + postproc_valid))
    
    # Show results
    llm_status="❌"
    [[ $llm_valid -eq 1 ]] && llm_status="✅"
    
    postproc_status="❌"
    [[ $postproc_valid -eq 1 ]] && postproc_status="✅"
    
    improvement=""
    if [[ $llm_valid -eq 0 ]] && [[ $postproc_valid -eq 1 ]]; then
        improvement=" (FIXED)"
    elif [[ $llm_valid -eq 1 ]] && [[ $postproc_valid -eq 0 ]]; then
        improvement=" (BROKEN)"
    fi
    
    echo "  LLM: $llm_status  Post-proc: $postproc_status$improvement"
    echo "  LLM Command: $llm_cmd"
    echo "  Post-proc Command: $postproc_cmd"
    echo
done

# Calculate results
llm_pct=$(echo "scale=1; $llm_success * 100 / $total" | bc)
postproc_pct=$(echo "scale=1; $postproc_success * 100 / $total" | bc)
improvement=$(echo "scale=1; $postproc_pct - $llm_pct" | bc)

echo "=== RESULTS ==="
echo "LLM Baseline: $llm_success/$total ($llm_pct%)"
echo "With Post-processing: $postproc_success/$total ($postproc_pct%)"
echo "Improvement: $improvement percentage points"
echo