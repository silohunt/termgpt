#!/bin/bash

# Test the 15 most challenging commands from the 50-command set
echo "🔥 Testing Most Challenging Commands"
echo

# Handpicked most complex commands likely to challenge the LLM
hardest_commands=(
    "Monitor disk I/O for processes writing more than 10MB/sec to any filesystem"
    "Find all zombie processes and their parent processes, show process tree"
    "Monitor real-time CPU usage per core and alert when any core exceeds 90% for 30 seconds"
    "Search for duplicate files based on content hash in the home directory, show sizes and paths" 
    "Find all executable files that are world-writable or owned by users other than root in system directories"
    "Scan local network for all active hosts and identify their operating systems and open ports"
    "Monitor network traffic for suspicious patterns like port scanning or brute force attempts"
    "Check SSL certificate expiration dates for all HTTPS services on the local network"
    "Extract and analyze error patterns from multiple log files, group by error type and frequency"
    "Process CSV files to find correlations between columns and generate statistical summaries"
    "Analyze email headers to detect spam patterns and trace message routing paths"
    "Process large text files to find near-duplicate content using fuzzy matching algorithms"
    "Create automated backup script that handles incremental backups with rotation and compression"
    "Set up monitoring for disk space usage with email alerts when partitions exceed 85% full"
    "Create a system health check script that validates services, disk space, memory, and network connectivity"
)

total=0
llm_success=0
postproc_success=0

echo "Testing ${#hardest_commands[@]} extremely challenging commands..."
echo

for i in "${!hardest_commands[@]}"; do
    query="${hardest_commands[$i]}"
    num=$((i + 1))
    
    echo "[$num/${#hardest_commands[@]}] $query"
    
    # Test LLM baseline
    export TERMGPT_DISABLE_POSTPROCESSING=1
    llm_output=$(./bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    llm_cmd=$(echo "$llm_output" | grep -A1 "Generated Command:" | tail -1 | xargs 2>/dev/null || echo "")
    unset TERMGPT_DISABLE_POSTPROCESSING
    
    # Test with post-processing  
    postproc_output=$(./bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    postproc_cmd=$(echo "$postproc_output" | grep -A1 "Generated Command:" | tail -1 | xargs 2>/dev/null || echo "")
    
    # Validation
    llm_valid=0
    if [[ -n "$llm_cmd" ]] && [[ ${#llm_cmd} -gt 5 ]] && [[ "$llm_cmd" =~ ^[a-zA-Z] ]] && [[ "$llm_cmd" != *"Error"* ]] && [[ "$llm_cmd" != *"ERROR"* ]]; then
        # Additional quality checks for complex commands
        if [[ "$llm_cmd" != *"Sorry"* ]] && [[ "$llm_cmd" != *"cannot"* ]] && [[ "$llm_cmd" != *"unable"* ]]; then
            llm_valid=1
        fi
    fi
    
    postproc_valid=0
    if [[ -n "$postproc_cmd" ]] && [[ ${#postproc_cmd} -gt 5 ]] && [[ "$postproc_cmd" =~ ^[a-zA-Z] ]] && [[ "$postproc_cmd" != *"Error"* ]] && [[ "$postproc_cmd" != *"ERROR"* ]]; then
        if [[ "$postproc_cmd" != *"Sorry"* ]] && [[ "$postproc_cmd" != *"cannot"* ]] && [[ "$postproc_cmd" != *"unable"* ]]; then
            postproc_valid=1
        fi
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
        improvement=" (FIXED by post-processing)"
    elif [[ $llm_valid -eq 1 ]] && [[ $postproc_valid -eq 0 ]]; then
        improvement=" (BROKEN by post-processing)"
    fi
    
    echo "  LLM: $llm_status  Post-proc: $postproc_status$improvement"
    
    # Show commands if they differ significantly or if there are issues
    if [[ "$llm_cmd" != "$postproc_cmd" ]] || [[ $llm_valid -eq 0 ]] || [[ $postproc_valid -eq 0 ]]; then
        echo "  💡 LLM:        $llm_cmd"
        echo "  🔧 Post-proc: $postproc_cmd"
    fi
    echo
done

# Calculate results
if [[ $total -gt 0 ]]; then
    llm_pct=$(echo "scale=1; $llm_success * 100 / $total" | bc)
    postproc_pct=$(echo "scale=1; $postproc_success * 100 / $total" | bc)
    improvement=$(echo "scale=1; $postproc_pct - $llm_pct" | bc)
else
    llm_pct="0.0"
    postproc_pct="0.0" 
    improvement="0.0"
fi

echo "🎯 RESULTS FOR MOST CHALLENGING COMMANDS"
echo "========================================="
echo "LLM Baseline: $llm_success/$total ($llm_pct%)"
echo "With Post-processing: $postproc_success/$total ($postproc_pct%)"
echo "Improvement: $improvement percentage points"
echo
echo "These results show performance on the most challenging edge cases"
echo "that are most likely to reveal areas for improvement."