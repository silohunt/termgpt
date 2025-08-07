#!/bin/bash
# Simple benchmarking tool for TermGPT
# Compare LLM models and see post-processing fixes

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"query\" [model]"
    echo ""
    echo "Examples:"
    echo "  $0 \"find large files\""
    echo "  $0 \"find large files\" codellama:33b-instruct"
    echo ""
    echo "Available commands in commands.txt"
    exit 1
fi

QUERY="$1"
MODEL="${2:-${TERMGPT_MODEL:-codellama:7b-instruct}}"

echo "========================================"
echo "TermGPT Benchmark"
echo "========================================"
echo "Model: $MODEL"
echo "Query: $QUERY"
echo ""

# Get LLM output without post-processing
echo "LLM Output (raw):"
LLM_OUTPUT=$(TERMGPT_DISABLE_POSTPROCESSING=1 TERMGPT_MODEL="$MODEL" echo "q" | ../../bin/termgpt "$QUERY" 2>&1)
LLM_CMD=$(echo "$LLM_OUTPUT" | sed -n '/Generated Command:/,/Options:/p' | grep -v "Generated Command:" | grep -v "Options:" | head -n 1)
echo "  $LLM_CMD"
echo ""

# Get post-processed output
echo "Post-processed:"
POSTPROC_OUTPUT=$(TERMGPT_MODEL="$MODEL" echo "q" | ../../bin/termgpt "$QUERY" 2>&1)
POSTPROC_CMD=$(echo "$POSTPROC_OUTPUT" | sed -n '/Generated Command:/,/Options:/p' | grep -v "Generated Command:" | grep -v "Options:" | head -n 1)
echo "  $POSTPROC_CMD"
echo ""

# Show if any fixes were applied
if [ "$LLM_CMD" != "$POSTPROC_CMD" ]; then
    echo "Fix Applied: Post-processing modified the command"
    echo "  Before: $LLM_CMD"
    echo "  After:  $POSTPROC_CMD"
else
    echo "No fixes applied: Command unchanged"
fi

echo ""
echo "========================================"