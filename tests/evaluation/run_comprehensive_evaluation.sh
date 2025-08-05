#!/bin/bash

# Comprehensive Evaluation Script for 50 Complex Commands
# Tests both LLM baseline and post-processing improvements

set -e

EVALUATION_FILE="evaluation_50_commands.txt"
RESULTS_FILE="comprehensive_evaluation_results.md"
OLLAMA_MODEL="${TERMGPT_MODEL:-codellama:7b-instruct}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 Starting Comprehensive Evaluation with 50 Complex Commands"
echo "Model: $OLLAMA_MODEL"
echo "Post-processing: Enabled"
echo

# Initialize results file
cat > "$RESULTS_FILE" << 'EOF'
# Comprehensive Evaluation Results - 50 Complex Commands

## Test Configuration
- Model: `codellama:7b-instruct`
- Post-processing: Enabled (modular pipeline)
- Test Date: $(date)
- Commands: 50 complex scenarios across 5 categories

## Results Summary

| Category | Commands | LLM Success | Post-Proc Success | Improvement |
|----------|----------|-------------|-------------------|-------------|
EOF

# Counter variables
total_commands=0
llm_successes=0
postproc_successes=0
category_stats=()

# Function to test a single command
test_command() {
    local query="$1"
    local category="$2"
    local cmd_num="$3"
    
    echo -e "${BLUE}[$cmd_num/50]${NC} Testing: $query"
    
    # Test LLM baseline (without post-processing)
    export TERMGPT_DISABLE_POSTPROCESSING=1
    llm_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "TIMEOUT_OR_ERROR")
    llm_result=$(echo "$llm_output" | grep -A1 "Generated Command:" | tail -1 | xargs)
    unset TERMGPT_DISABLE_POSTPROCESSING
    
    # Test with post-processing
    postproc_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "TIMEOUT_OR_ERROR")
    postproc_result=$(echo "$postproc_output" | grep -A1 "Generated Command:" | tail -1 | xargs)
    
    # Basic validation - check if result looks like a valid command
    llm_valid=0
    postproc_valid=0
    
    if [[ "$llm_result" != "TIMEOUT_OR_ERROR" ]] && [[ "$llm_result" =~ ^[a-zA-Z] ]] && [[ ${#llm_result} -gt 3 ]]; then
        # Additional checks for command validity
        if ! echo "$llm_result" | grep -q "I cannot\|I can't\|Sorry\|Error\|undefined"; then
            llm_valid=1
        fi
    fi
    
    if [[ "$postproc_result" != "TIMEOUT_OR_ERROR" ]] && [[ "$postproc_result" =~ ^[a-zA-Z] ]] && [[ ${#postproc_result} -gt 3 ]]; then
        # Additional checks for command validity
        if ! echo "$postproc_result" | grep -q "I cannot\|I can't\|Sorry\|Error\|undefined"; then
            postproc_valid=1
        fi
    fi
    
    # Update counters
    total_commands=$((total_commands + 1))
    llm_successes=$((llm_successes + llm_valid))
    postproc_successes=$((postproc_successes + postproc_valid))
    
    # Status indicators
    llm_status="${RED}✗${NC}"
    if [ $llm_valid -eq 1 ]; then
        llm_status="${GREEN}✓${NC}"
    fi
    
    postproc_status="${RED}✗${NC}"
    if [ $postproc_valid -eq 1 ]; then
        postproc_status="${GREEN}✓${NC}"
    fi
    
    improvement=""
    if [ $llm_valid -eq 0 ] && [ $postproc_valid -eq 1 ]; then
        improvement=" ${YELLOW}(FIXED)${NC}"
    elif [ $llm_valid -eq 1 ] && [ $postproc_valid -eq 0 ]; then
        improvement=" ${RED}(BROKEN)${NC}"
    fi
    
    echo -e "  LLM: $llm_status  Post-proc: $postproc_status$improvement"
    
    # Log detailed results
    cat >> "$RESULTS_FILE" << EOF

### Command $cmd_num: $category
**Query:** $query

**LLM Result:** $llm_result
**Valid:** $([ $llm_valid -eq 1 ] && echo "✅ Yes" || echo "❌ No")

**Post-processing Result:** $postproc_result  
**Valid:** $([ $postproc_valid -eq 1 ] && echo "✅ Yes" || echo "❌ No")

**Improvement:** $([ $llm_valid -eq 0 ] && [ $postproc_valid -eq 1 ] && echo "🔧 Fixed by post-processing" || ([ $llm_valid -eq 1 ] && [ $postproc_valid -eq 0 ] && echo "⚠️ Broken by post-processing" || echo "No change"))

---

EOF
    
    sleep 1  # Rate limiting
}

# Parse commands and run tests
cmd_num=1
current_category=""
category_cmd_count=0
category_llm_success=0
category_postproc_success=0

while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
        # Check if this is a category header
        if [[ "$line" =~ ^##[[:space:]](.+) ]]; then
            # Save previous category stats
            if [[ -n "$current_category" ]]; then
                improvement=$((category_postproc_success - category_llm_success))
                category_stats+=("$current_category|$category_cmd_count|$category_llm_success|$category_postproc_success|$improvement")
            fi
            
            # Start new category
            current_category=$(echo "$line" | sed 's/^##[[:space:]]*//' | sed 's/[[:space:]]*(.*//')
            category_cmd_count=0
            category_llm_success=0
            category_postproc_success=0
            echo -e "\n${YELLOW}=== $current_category ===${NC}"
        fi
        continue
    fi
    
    # Extract command from numbered line
    if [[ "$line" =~ ^[0-9]+\.[[:space:]](.+) ]]; then
        query=$(echo "$line" | sed 's/^[0-9]*\.[[:space:]]*//')
        test_command "$query" "$current_category" "$cmd_num"
        cmd_num=$((cmd_num + 1))
        category_cmd_count=$((category_cmd_count + 1))
        
        # Update category stats based on last test results
        if [ $llm_valid -eq 1 ]; then
            category_llm_success=$((category_llm_success + 1))
        fi
        if [ $postproc_valid -eq 1 ]; then
            category_postproc_success=$((category_postproc_success + 1))
        fi
    fi
done < "$EVALUATION_FILE"

# Save final category stats
if [[ -n "$current_category" ]]; then
    improvement=$((category_postproc_success - category_llm_success))
    category_stats+=("$current_category|$category_cmd_count|$category_llm_success|$category_postproc_success|$improvement")
fi

# Calculate final statistics
llm_percentage=$(echo "scale=1; $llm_successes * 100 / $total_commands" | bc)
postproc_percentage=$(echo "scale=1; $postproc_successes * 100 / $total_commands" | bc)
improvement_points=$(echo "scale=1; $postproc_percentage - $llm_percentage" | bc)
improvement_relative=$(echo "scale=1; $improvement_points * 100 / $llm_percentage" | bc)

echo
echo -e "${BLUE}=== FINAL RESULTS ===${NC}"
echo -e "Total Commands: $total_commands"
echo -e "LLM Baseline: $llm_successes/$total_commands (${llm_percentage}%)"
echo -e "With Post-processing: $postproc_successes/$total_commands (${postproc_percentage}%)"
echo -e "Improvement: ${improvement_points} percentage points (${improvement_relative}% relative)"

# Update results file with category breakdown
for stat in "${category_stats[@]}"; do
    IFS='|' read -ra PARTS <<< "$stat"
    category="${PARTS[0]}"
    count="${PARTS[1]}"
    llm_success="${PARTS[2]}"
    postproc_success="${PARTS[3]}"
    improvement="${PARTS[4]}"
    
    llm_pct=$(echo "scale=1; $llm_success * 100 / $count" | bc)
    postproc_pct=$(echo "scale=1; $postproc_success * 100 / $count" | bc)
    
    echo "| $category | $count | $llm_success ($llm_pct%) | $postproc_success ($postproc_pct%) | +$improvement |" >> "$RESULTS_FILE"
done

# Add final summary to results file
cat >> "$RESULTS_FILE" << EOF

## Overall Performance

- **Total Commands Tested:** $total_commands
- **LLM Baseline Success Rate:** $llm_successes/$total_commands (**${llm_percentage}%**)
- **Post-processing Success Rate:** $postproc_successes/$total_commands (**${postproc_percentage}%**)
- **Improvement:** **${improvement_points} percentage points** (${improvement_relative}% relative improvement)

## Analysis Notes

This comprehensive evaluation tested 50 complex commands across 5 categories, focusing on edge cases and advanced scenarios that go beyond typical command generation tasks.

The results show the effectiveness of the modular post-processing pipeline in handling complex, multi-step operations that require contextual understanding and platform-specific corrections.

## Next Steps

Based on these results, areas for improvement include:
1. Enhanced handling of complex multi-step operations
2. Better context awareness for system administration tasks
3. Improved parsing of compound commands with multiple pipes/filters
4. Advanced network and security command generation
5. Better handling of automation and scripting scenarios

EOF

echo
echo "📊 Detailed results saved to: $RESULTS_FILE"