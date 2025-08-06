#!/bin/sh
# TermGPT Post-Processing Library
# Main entry point for all command corrections

# Find the post-processing directory
# When sourced, we need to find where THIS file is, not where $0 points
# Use a more reliable method to find the script location
if [ -n "${BASH_SOURCE:-}" ]; then
    # Bash
    SCRIPT_PATH="${BASH_SOURCE[0]}"
else
    # POSIX - we'll rely on the sourcing script to set POSTPROCESS_LIB_PATH
    SCRIPT_PATH="${POSTPROCESS_LIB_PATH:-$0}"
fi

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
POSTPROCESS_DIR="$(dirname "$SCRIPT_DIR")"

# Source individual correction modules with error handling
for module in complex-commands time files normalize platform-macos platform-linux security; do
    module_path="$POSTPROCESS_DIR/corrections/$module.sh"
    if [ -f "$module_path" ]; then
        . "$module_path"
    else
        echo "Warning: Post-processing module $module.sh not found at $module_path" >&2
        # Define stub function to prevent errors - fix invalid identifiers
        case "$module" in
            platform-macos)
                apply_macos_corrections() { printf '%s' "$1"; }
                ;;
            platform-linux)
                apply_linux_corrections() { printf '%s' "$1"; }
                ;;
            *)
                eval "apply_${module}_corrections() { printf '%s' \"\$1\"; }"
                ;;
        esac
    fi
done

# Main post-processing pipeline
# Usage: apply_all_corrections "command" ["platform"] ["original_query"]
apply_all_corrections() {
    local command="$1"
    local platform="${2:-${TERMGPT_PLATFORM:-unknown}}"
    local original_query="${3:-}"
    
    # Export original query for corrections that need context
    export TERMGPT_ORIGINAL_QUERY="$original_query"
    
    # 0. Complex command preservation (FIRST - before other corrections can break things)
    if command -v preserve_complex_chains >/dev/null 2>&1; then
        if preserve_complex_chains "$command" "$original_query"; then
            # Command preserved, return as-is
            echo "$command"
            return 0
        fi
    fi
    
    # Check for script generation requests (only if LLM command is clearly inadequate)
    if command -v detect_script_generation >/dev/null 2>&1; then
        if script_result=$(detect_script_generation "$command" "$original_query"); then
            echo "$script_result"
            return 0
        fi
    fi
    
    # Check for improved error analysis
    if command -v improve_error_analysis >/dev/null 2>&1; then
        if error_result=$(improve_error_analysis "$command" "$original_query"); then
            echo "$error_result"
            return 0
        fi
    fi
    
    # Apply corrections in order of importance
    # 1. Normalization (reduce variations)
    command=$(apply_normalization_corrections "$command" "$original_query")
    
    # 2. Security fixes (must come first after normalization)
    command=$(apply_security_corrections "$command")
    
    # 3. Semantic corrections (now context-aware)
    command=$(apply_time_corrections "$command")
    command=$(apply_file_corrections "$command" "$original_query")
    
    # 4. Platform-specific corrections
    case "$platform" in
        macos)
            command=$(apply_macos_corrections "$command")
            ;;
        linux)
            command=$(apply_linux_corrections "$command")
            ;;
    esac
    
    printf '%s' "$command"
}

# Apply only platform-specific corrections
# Usage: apply_platform_corrections "command" "platform"
apply_platform_corrections() {
    local command="$1"
    local platform="${2:-${TERMGPT_PLATFORM:-unknown}}"
    
    case "$platform" in
        macos)
            command=$(apply_macos_corrections "$command")
            ;;
        linux)
            command=$(apply_linux_corrections "$command")
            ;;
    esac
    
    printf '%s' "$command"
}

# Check if a correction would change the command
# Useful for testing and debugging
# Usage: would_correct "command" && echo "Command needs correction"
would_correct() {
    local original="$1"
    local corrected
    corrected=$(apply_all_corrections "$original")
    [ "$original" != "$corrected" ]
}

# Get a list of all corrections that would be applied
# Usage: list_corrections "command"
list_corrections() {
    local command="$1"
    local original="$command"
    local corrections=""
    
    # Test each correction type
    local security_corrected=$(apply_security_corrections "$command")
    if [ "$command" != "$security_corrected" ]; then
        corrections="${corrections}security "
        command="$security_corrected"
    fi
    
    local time_corrected=$(apply_time_corrections "$command")
    if [ "$command" != "$time_corrected" ]; then
        corrections="${corrections}time "
        command="$time_corrected"
    fi
    
    local file_corrected=$(apply_file_corrections "$command" "$original_query")
    if [ "$command" != "$file_corrected" ]; then
        corrections="${corrections}files "
        command="$file_corrected"
    fi
    
    local platform_corrected=$(apply_platform_corrections "$command")
    if [ "$command" != "$platform_corrected" ]; then
        corrections="${corrections}platform "
    fi
    
    printf '%s' "$corrections"
}