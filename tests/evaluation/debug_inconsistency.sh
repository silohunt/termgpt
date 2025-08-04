#!/bin/bash

# Debug Inconsistency - Why are results varying?
echo "🔍 Debugging Performance Inconsistency"
echo "=====================================​"
echo

# Test one problematic command multiple times to check consistency
test_cmd="Set up monitoring for disk space usage with email alerts when partitions exceed 85% full"

echo "Testing command 5 times to check consistency:"
echo "Query: $test_cmd"
echo

for i in {1..5}; do
    echo "--- Run $i ---"
    
    # LLM baseline
    export TERMGPT_DISABLE_POSTPROCESSING=1
    llm_result=$(../../bin/termgpt --eval "$test_cmd" 2>&1 | grep -A1 "Generated Command:" | tail -1 | xargs)
    unset TERMGPT_DISABLE_POSTPROCESSING
    
    # Post-processing
    postproc_result=$(../../bin/termgpt --eval "$test_cmd" 2>&1 | grep -A1 "Generated Command:" | tail -1 | xargs)
    
    echo "LLM: $llm_result"
    echo "Post-proc: $postproc_result"
    echo "Same: $([ "$llm_result" = "$postproc_result" ] && echo "YES" || echo "NO")"
    echo
done

echo "🔍 Checking post-processing system status..."

# Check if post-processing library is being loaded
echo "Post-processing library path:"
find_postprocess_lib() {
  if [ -f "$(dirname "$0")/../post-processing/lib/postprocess.sh" ]; then
    echo "$(dirname "$0")/../post-processing/lib/postprocess.sh"
  elif [ -f "./post-processing/lib/postprocess.sh" ]; then
    echo "./post-processing/lib/postprocess.sh"
  else
    echo "NOT FOUND"
  fi
}

lib_path=$(find_postprocess_lib)
echo "Library: $lib_path"

if [ -f "$lib_path" ]; then
    echo "Library exists: ✅"
    echo "Library size: $(wc -l < "$lib_path") lines"
    echo "Library permissions: $(ls -la "$lib_path" | awk '{print $1}')"
else
    echo "Library missing: ❌"
fi

echo
echo "🔍 Testing post-processing function directly..."

# Source the library and test directly
if [ -f "$lib_path" ]; then
    . "$lib_path" 2>/dev/null
    if command -v apply_all_corrections >/dev/null 2>&1; then
        echo "Post-processing function available: ✅"
        test_input="while true; do df -h | grep 85% && mail admin; done"
        result=$(apply_all_corrections "$test_input" "" "monitor disk space email alerts")
        echo "Direct test input: $test_input"
        echo "Direct test output: $result"
    else
        echo "Post-processing function not available: ❌"
    fi
else
    echo "Cannot test post-processing function: Library not found"
fi