#!/bin/bash
# Simple benchmarking tool for TermGPT
# Shows actual post-processing effects by applying corrections to the same LLM output

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"query\" [model]"
    echo ""
    echo "Examples:"
    echo "  $0 \"find large files\""
    echo "  $0 \"find large files\" codellama:33b-instruct"
    echo ""
    echo "Test commands that trigger post-processing:"
    echo "  $0 \"show network connections on port 80\"  # macOS: netstat -p fix"
    echo "  $0 \"find UDP connections\"                   # macOS: grep UDP -> grep -i udp"
    echo "  $0 \"find files modified last week\"          # Time fix: mtime +7 -> -7"
    echo "  $0 \"compress log files\"                     # Adds *.log filter"
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

# Get LLM output ONCE without post-processing (using interactive mode like manual testing)
echo "Getting LLM output..."
RAW_OUTPUT=$(echo "q" | TERMGPT_DISABLE_POSTPROCESSING=1 TERMGPT_MODEL="$MODEL" ../../bin/termgpt "$QUERY" 2>&1)
LLM_CMD=$(echo "$RAW_OUTPUT" | grep -A1 "Generated Command:" | tail -n 1)

if [ -z "$LLM_CMD" ]; then
    echo "Error: Could not extract command from LLM output"
    exit 1
fi

echo ""
echo "LLM Output (raw):"
echo "  $LLM_CMD"
echo ""

# Now apply post-processing to the SAME output
# Source the post-processing library
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source platform detection
if [ -f "$PROJECT_ROOT/lib/termgpt-platform.sh" ]; then
    . "$PROJECT_ROOT/lib/termgpt-platform.sh"
fi

# Source post-processing
if [ -f "$PROJECT_ROOT/post-processing/lib/postprocess.sh" ]; then
    . "$PROJECT_ROOT/post-processing/lib/postprocess.sh"
    POSTPROC_CMD=$(apply_platform_corrections "$LLM_CMD")
else
    echo "Warning: Post-processing library not found"
    POSTPROC_CMD="$LLM_CMD"
fi

echo "Post-processed:"
echo "  $POSTPROC_CMD"
echo ""

# Show if any fixes were applied
if [ "$LLM_CMD" != "$POSTPROC_CMD" ]; then
    echo "Fix Applied: Post-processing modified the command"
    echo "  Before: $LLM_CMD"
    echo "  After:  $POSTPROC_CMD"
    
    # Try to identify what changed
    echo ""
    echo "Changes detected:"
    
    # Check for common corrections
    if echo "$LLM_CMD" | grep -q "netstat.*-p" && echo "$POSTPROC_CMD" | grep -qv "netstat.*-p"; then
        echo "  - Removed unsupported netstat -p flag (macOS fix)"
    fi
    
    if echo "$LLM_CMD" | grep -q "grep.*UDP" && echo "$POSTPROC_CMD" | grep -q "grep.*-i.*udp"; then
        echo "  - Fixed UDP case sensitivity (macOS fix)"
    fi
    
    if echo "$LLM_CMD" | grep -q "mtime +7" && echo "$POSTPROC_CMD" | grep -q "mtime -7"; then
        echo "  - Fixed time logic (last week = -7, not +7)"
    fi
    
    if ! echo "$LLM_CMD" | grep -q '\.log' && echo "$POSTPROC_CMD" | grep -q '\.log'; then
        echo "  - Added .log filter for log-related commands"
    fi
else
    echo "No fixes applied: Command unchanged"
    echo "(Post-processing only applies platform and time corrections)"
fi

echo ""
echo "========================================"

# Optionally run predefined tests
if [ "$1" = "--test-all" ]; then
    echo ""
    echo "Running post-processing validation tests..."
    echo "========================================"
    
    # Test cases that should trigger post-processing
    test_queries=(
        "show network connections on port 80"
        "find UDP connections"
        "find files modified last week"
        "compress log files"
    )
    
    for query in "${test_queries[@]}"; do
        echo ""
        echo "Testing: $query"
        $0 "$query" "$MODEL" | grep -A2 "Fix Applied" || echo "  No changes"
    done
fi