#!/bin/sh
# TermGPT Post-Processing Library
# Simplified modular approach - essential corrections only

# Find the post-processing directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
POSTPROCESS_DIR="$(dirname "$SCRIPT_DIR")"

# Source correction modules with error handling
for module in common platform-macos platform-linux; do
    module_path="$POSTPROCESS_DIR/corrections/$module.sh"
    if [ -f "$module_path" ]; then
        . "$module_path"
    else
        echo "Warning: Post-processing module $module.sh not found at $module_path" >&2
        # Define stub function to prevent errors
        case "$module" in
            platform-macos)
                apply_macos_corrections() { printf '%s' "$1"; }
                ;;
            platform-linux)
                apply_linux_corrections() { printf '%s' "$1"; }
                ;;
            common)
                apply_common_corrections() { printf '%s' "$1"; }
                ;;
        esac
    fi
done

# Simple post-processing pipeline - only essential corrections
apply_platform_corrections() {
    local command="$1"
    local platform="${TERMGPT_PLATFORM:-unknown}"
    
    # Apply common corrections first
    command=$(apply_common_corrections "$command")
    
    # Apply platform-specific corrections
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