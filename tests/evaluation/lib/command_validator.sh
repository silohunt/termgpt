#!/bin/bash

# Simple but effective command validation
validate_command() {
    local command="$1"
    local query="$2"
    
    # Skip validation for empty or error commands
    if [[ -z "$command" ]] || [[ "$command" == *"ERROR"* ]]; then
        echo "VALIDATION_SKIP: Empty or error command" >&2
        return 1
    fi
    
    # Check for incomplete commands BEFORE syntax check
    if [[ "$command" == "#!/bin/sh" ]] || [[ "$command" == "#!/bin/bash" ]]; then
        echo "INCOMPLETE: Only shebang" >&2
        return 1
    elif [[ "$command" == *"Here's how"* ]] || [[ "$command" == *"You can"* ]] || [[ "$command" == *"Try this"* ]]; then
        echo "NOT_COMMAND: Contains explanation text" >&2
        return 1
    elif [[ "$command" == "cat > "* ]] && [[ "$command" == *"<<" ]]; then
        # These are often incomplete script generation attempts
        echo "INCOMPLETE: Unfinished script generation" >&2
        return 1
    elif [[ "$command" == *"<"*".txt>"* ]] || [[ "$command" == *"<"*"_file>"* ]]; then
        echo "INCOMPLETE: Contains placeholder text" >&2
        return 1
    elif [[ "$command" =~ ^[0-9]+[[:space:]]+[0-9]+[[:space:]]+\\* ]]; then
        echo "NOT_COMMAND: Appears to be crontab entry" >&2
        return 1
    fi
    
    # Test shell syntax after incomplete check
    if ! echo "$command" | sh -n 2>/dev/null; then
        echo "SYNTAX_ERROR: Invalid shell syntax" >&2
        return 1
    fi
    
    # Context-specific validation
    case "$query" in
        *"zombie"*)
            if ! echo "$command" | grep -qiE "(ps.*Z|grep.*zombie|awk.*Z|stat.*Z)"; then
                echo "LOGIC_ERROR: Zombie process detection should check for Z state" >&2
                return 1
            fi
            ;;
        *"duplicate"*"files"*)
            if ! echo "$command" | grep -qE "(md5sum|sha256sum|sha1sum)"; then
                echo "LOGIC_ERROR: Duplicate detection needs checksums" >&2
                return 1
            fi
            ;;
        *"fuzzy matching"*)
            if echo "$command" | grep -qE "fzf"; then
                echo "TOOL_ERROR: fzf is interactive selection, not fuzzy matching" >&2
                return 1
            fi
            ;;
    esac
    
    return 0
}