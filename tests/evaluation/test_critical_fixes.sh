#!/bin/bash

# Test Critical Fixes - Focus on the 2 failing commands from hardest test
echo "🎯 Testing Critical Fixes for 95% Success Rate"
echo "=============================================="
echo

# The exact 2 commands that are failing in our hardest test
critical_commands=(
    "Analyze email headers to detect spam patterns and trace message routing paths"
    "Set up monitoring for disk space usage with email alerts when partitions exceed 85% full"
)

echo "Testing the 2 commands that are preventing 95% success rate..."
echo

total=0
llm_success=0
postproc_success=0
fixes_applied=0

for i in "${!critical_commands[@]}"; do
    query="${critical_commands[$i]}"
    num=$((i + 1))
    
    echo "🔍 CRITICAL COMMAND $num: $query"
    echo "=" | head -c 80; echo
    
    # Test LLM baseline
    echo "🧠 LLM Baseline (no post-processing):"
    export TERMGPT_DISABLE_POSTPROCESSING=1
    llm_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    llm_cmd=$(echo "$llm_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    unset TERMGPT_DISABLE_POSTPROCESSING
    
    echo "  Command: $llm_cmd"
    
    # Validate LLM result
    llm_valid=0
    if [[ -n "$llm_cmd" ]] && [[ ${#llm_cmd} -gt 5 ]] && [[ "$llm_cmd" =~ ^[a-zA-Z] ]]; then
        if [[ "$llm_cmd" != *"Error"* ]] && [[ "$llm_cmd" != *"ERROR"* ]]; then
            llm_valid=1
            echo "  Status: ✅ VALID"
        else
            echo "  Status: ❌ INVALID (contains error)"
        fi
    else
        echo "  Status: ❌ INVALID (too short or bad format)"
    fi
    
    echo
    echo "🔧 Post-processing Result:"
    postproc_output=$(../../bin/termgpt --eval "$query" 2>&1 || echo "ERROR")
    postproc_cmd=$(echo "$postproc_output" | grep -A1 "Generated Command:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    echo "  Command: $postproc_cmd"
    
    # Validate post-processing result
    postproc_valid=0
    if [[ -n "$postproc_cmd" ]] && [[ ${#postproc_cmd} -gt 5 ]] && [[ "$postproc_cmd" =~ ^[a-zA-Z] ]]; then
        if [[ "$postproc_cmd" != *"Error"* ]] && [[ "$postproc_cmd" != *"ERROR"* ]]; then
            postproc_valid=1
            echo "  Status: ✅ VALID"
        else
            echo "  Status: ❌ INVALID (contains error)"
        fi
    else
        echo "  Status: ❌ INVALID (too short or bad format)"
    fi
    
    # Analysis
    echo
    echo "🔬 Analysis:"
    if [[ $llm_valid -eq 1 ]] && [[ $postproc_valid -eq 0 ]]; then
        echo "  ⚠️  POST-PROCESSING REGRESSION: LLM had valid result, post-processing broke it"
        echo "  📋 LLM Length: ${#llm_cmd} chars"
        echo "  📋 Post-proc Length: ${#postproc_cmd} chars"
        echo "  💡 This is exactly what we need to fix for 95% success!"
    elif [[ $llm_valid -eq 0 ]] && [[ $postproc_valid -eq 1 ]]; then
        echo "  🎉 POST-PROCESSING SUCCESS: Fixed invalid LLM result"
        fixes_applied=$((fixes_applied + 1))
    elif [[ $llm_valid -eq 1 ]] && [[ $postproc_valid -eq 1 ]]; then
        echo "  ✨ BOTH VALID: Post-processing preserved good result"
    else
        echo "  💥 BOTH INVALID: Neither LLM nor post-processing worked"
    fi
    
    # Update counters
    total=$((total + 1))
    llm_success=$((llm_success + llm_valid))
    postproc_success=$((postproc_success + postproc_valid))
    
    echo
    echo "-" | head -c 80; echo
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

echo "🎯 CRITICAL FIXES RESULTS"
echo "========================"
echo "LLM Baseline: $llm_success/$total ($llm_pct%)"
echo "With Post-processing: $postproc_success/$total ($postproc_pct%)"
echo "Improvement: $improvement percentage points"
echo
echo "📊 SUCCESS RATE IMPACT:"
echo "Current hardest test: 13/15 (86.6%)"
if [[ $postproc_success -eq 2 ]]; then
    echo "If these 2 commands work: 15/15 (100.0%) 🎉"
elif [[ $postproc_success -eq 1 ]]; then
    echo "If 1 of these commands works: 14/15 (93.3%) ✅"
else
    echo "No improvement from current state: 13/15 (86.6%) ⚠️"
fi
echo
echo "🛠️  RECOMMENDED FIXES:"
if [[ $llm_success -gt $postproc_success ]]; then
    echo "1. Add command chain preservation logic"
    echo "2. Add validation layer to prevent over-correction"
    echo "3. Focus on preserving valid complex command patterns"
else
    echo "1. The failing commands need different correction approaches"
    echo "2. May need enhanced pattern recognition"
fi
echo
echo "This focused test helps validate fixes before running the full evaluation suite."