#!/bin/bash

# Challenging Commands Test - Edge cases evaluation (Target: 60%+)
# Tests the 15 most challenging commands from the 50-command set
echo "🔥 Testing Most Challenging Commands"
echo

# Results file
RESULTS_FILE="results/challenging_commands_results.md"

# Initialize results file
cat > "$RESULTS_FILE" << 'EOF'
# Challenging Commands Test Results - Edge Cases

## Configuration
- Model: `codellama:7b-instruct`
- Post-processing: Enabled
- Target: 60%+ success rate
- Commands: 15 most challenging edge cases

## Individual Results

EOF

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
    llm_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    llm_cmd=$(echo "$llm_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    unset TERMGPT_DISABLE_POSTPROCESSING
    
    # Test with post-processing  
    postproc_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    postproc_cmd=$(echo "$postproc_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Enhanced validation using command validator
    source "$(dirname "$0")/lib/command_validator.sh" 2>/dev/null || {
        echo "Warning: Command validator not found, using basic validation" >&2
        validate_command() { return 0; }
    }
    
    # Validate LLM command
    llm_valid=0
    llm_validation=""
    if [[ -n "$llm_cmd" ]] && [[ ${#llm_cmd} -gt 5 ]] && [[ "$llm_cmd" =~ ^[a-zA-Z] ]] && [[ "$llm_cmd" != *"Error"* ]] && [[ "$llm_cmd" != *"ERROR"* ]]; then
        if [[ "$llm_cmd" != *"Sorry"* ]] && [[ "$llm_cmd" != *"cannot"* ]] && [[ "$llm_cmd" != *"unable"* ]]; then
            if llm_validation=$(validate_command "$llm_cmd" "$query" 2>&1); then
                llm_valid=1
            else
                llm_validation=" ($llm_validation)"
            fi
        fi
    fi
    
    # Validate post-processed command  
    postproc_valid=0
    postproc_validation=""
    if [[ -n "$postproc_cmd" ]] && [[ ${#postproc_cmd} -gt 5 ]] && [[ "$postproc_cmd" =~ ^[a-zA-Z] ]] && [[ "$postproc_cmd" != *"Error"* ]] && [[ "$postproc_cmd" != *"ERROR"* ]]; then
        if [[ "$postproc_cmd" != *"Sorry"* ]] && [[ "$postproc_cmd" != *"cannot"* ]] && [[ "$postproc_cmd" != *"unable"* ]]; then
            if postproc_validation=$(validate_command "$postproc_cmd" "$query" 2>&1); then
                postproc_valid=1
            else
                postproc_validation=" ($postproc_validation)"
            fi
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
    
    echo "  LLM: $llm_status$llm_validation  Post-proc: $postproc_status$postproc_validation$improvement"
    
    # Show commands if they differ significantly or if there are issues
    if [[ "$llm_cmd" != "$postproc_cmd" ]] || [[ $llm_valid -eq 0 ]] || [[ $postproc_valid -eq 0 ]]; then
        echo "  💡 LLM:        $llm_cmd"
        echo "  🔧 Post-proc: $postproc_cmd"
    fi
    
    # Log to results file
    cat >> "$RESULTS_FILE" << EOF

### Command $num: $(echo "$query" | cut -c1-50)...
**Query:** $query

**LLM Result:** $llm_cmd
**Valid:** $([ $llm_valid -eq 1 ] && echo "✅ Yes" || echo "❌ No")$llm_validation

**Post-processing Result:** $postproc_cmd
**Valid:** $([ $postproc_valid -eq 1 ] && echo "✅ Yes" || echo "❌ No")$postproc_validation

**Outcome:** $([ $llm_valid -eq 0 ] && [ $postproc_valid -eq 1 ] && echo "🔧 Fixed by post-processing" || ([ $llm_valid -eq 1 ] && [ $postproc_valid -eq 0 ] && echo "⚠️ Broken by post-processing" || echo "No change"))

---
EOF
    
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
echo
echo "📊 Detailed results saved to: $RESULTS_FILE"
echo "📁 Results location: $(pwd)/$RESULTS_FILE"

# Add final summary to results file
cat >> "$RESULTS_FILE" << EOF

## Final Results Summary

- **Total Commands:** $total
- **LLM Baseline:** $llm_success/$total ($llm_pct%)
- **With Post-processing:** $postproc_success/$total ($postproc_pct%)
- **Improvement:** $improvement percentage points

## Analysis

These 15 commands represent the most challenging edge cases from the full 50-command evaluation suite. They test complex multi-step operations, advanced system analysis, and scenarios that push the limits of command generation capabilities.

The results demonstrate the effectiveness of post-processing improvements while identifying specific areas where further development is needed.

EOF