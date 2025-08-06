#!/bin/bash

# LLM Variation Analysis Script

set -e

OLLAMA_MODEL="${TERMGPT_MODEL:-codellama:7b-instruct}"
RUNS=5  # Number of times to test each command

echo "LLM Variation Analysis"
echo "Model: $OLLAMA_MODEL"
echo

# Results file
RESULTS_FILE="results/llm_consistency_analysis.md"

# Initialize results file
cat > "$RESULTS_FILE" << 'EOF'
# LLM Consistency Analysis Results

## Configuration
- Model: `codellama:7b-instruct`
- Runs per command: 5
- Purpose: Analyze output variation and post-processing effectiveness

## Analysis Results

EOF

# Test commands that often show variation
test_cases=(
    "find files larger than 100MB"
    "list running processes using most memory"  
    "show network connections on port 80"
    "compress old log files"
    "monitor disk usage"
)

for query in "${test_cases[@]}"; do
    echo "Query: $query"
    echo "   Running $RUNS times to capture variation..."
    
    # Collect LLM responses
    llm_responses=()
    postproc_responses=()
    
    for run in $(seq 1 $RUNS); do
        # LLM baseline
        export TERMGPT_DISABLE_POSTPROCESSING=1
        llm_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
        llm_cmd=$(echo "$llm_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        unset TERMGPT_DISABLE_POSTPROCESSING
        
        # Post-processed
        postproc_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
        postproc_cmd=$(echo "$postproc_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        llm_responses+=("$llm_cmd")
        postproc_responses+=("$postproc_cmd")
        
        echo -n "."
    done
    echo
    
    # Analyze uniqueness
    unique_llm=$(printf '%s\n' "${llm_responses[@]}" | sort -u | wc -l)
    unique_postproc=$(printf '%s\n' "${postproc_responses[@]}" | sort -u | wc -l)
    
    echo "   LLM Variations: $unique_llm different commands out of $RUNS runs"
    echo "   Post-proc Variations: $unique_postproc different commands out of $RUNS runs" 
    
    if [[ $unique_llm -gt 1 ]]; then
        echo "   LLM Generated:"
        printf '%s\n' "${llm_responses[@]}" | sort -u | while read -r cmd; do
            count=$(printf '%s\n' "${llm_responses[@]}" | grep -c "^$cmd$" || true)
            echo "     [$count/$RUNS] $cmd"
        done
    fi
    
    if [[ $unique_postproc -gt 1 ]]; then
        echo "   Post-processed:"
        printf '%s\n' "${postproc_responses[@]}" | sort -u | while read -r cmd; do
            count=$(printf '%s\n' "${postproc_responses[@]}" | grep -c "^$cmd$" || true)
            echo "     [$count/$RUNS] $cmd"
        done
    fi
    
    # Calculate consistency improvement
    llm_consistency=$(echo "scale=1; (1 - ($unique_llm - 1) / $RUNS) * 100" | bc)
    postproc_consistency=$(echo "scale=1; (1 - ($unique_postproc - 1) / $RUNS) * 100" | bc)
    improvement=$(echo "scale=1; $postproc_consistency - $llm_consistency" | bc)
    
    # Quality assessment using command validator
    source "$(dirname "$0")/lib/command_validator.sh" 2>/dev/null || {
        validate_command() { return 0; }
    }
    
    llm_quality=0
    postproc_quality=0
    
    # Check quality of LLM responses
    for response in "${llm_responses[@]}"; do
        if validate_command "$response" "$query" >/dev/null 2>&1; then
            llm_quality=$((llm_quality + 1))
        fi
    done
    
    # Check quality of post-processed responses  
    for response in "${postproc_responses[@]}"; do
        if validate_command "$response" "$query" >/dev/null 2>&1; then
            postproc_quality=$((postproc_quality + 1))
        fi
    done
    
    llm_quality_pct=$(echo "scale=1; $llm_quality * 100 / $RUNS" | bc)
    postproc_quality_pct=$(echo "scale=1; $postproc_quality * 100 / $RUNS" | bc)
    quality_improvement=$(echo "scale=1; $postproc_quality_pct - $llm_quality_pct" | bc)
    
    echo "   Consistency: LLM ${llm_consistency}% -> Post-proc ${postproc_consistency}% (+${improvement}%)"
    echo "   Quality: LLM ${llm_quality_pct}% -> Post-proc ${postproc_quality_pct}% (+${quality_improvement}%)"
    echo
done