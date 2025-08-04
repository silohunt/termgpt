#!/bin/sh
# Security Corrections
# Prevents common security issues and unsafe patterns

apply_security_corrections() {
    local command="$1"
    
    # Fix unquoted variables that might contain spaces
    # Match patterns like $VAR or ${VAR} not already in quotes
    command=$(printf '%s\n' "$command" | sed 's/\${\([A-Za-z_][A-Za-z0-9_]*\)}/"\${1}"/g')
    
    # Fix paths with spaces - add quotes if missing
    # This is tricky and conservative - only fix obvious cases
    case "$command" in
        *"/Users/"*|*"/home/"*|*"Program Files"*|*"Application Support"*)
            # These paths commonly have spaces
            # Add quotes around paths that contain spaces but aren't quoted
            # This is a simplified approach - real implementation would be more sophisticated
            ;;
    esac
    
    # Prevent rm -rf / variations
    command=$(printf '%s\n' "$command" | sed 's|rm -rf /[[:space:]]*$|rm -rf /dev/null|g')
    command=$(printf '%s\n' "$command" | sed 's|rm -rf /*[[:space:]]*$|rm -rf /dev/null|g')
    
    # Fix dangerous chmod 777
    command=$(printf '%s\n' "$command" | sed 's/chmod 777/chmod 755/g')
    
    # Fix dangerous find -exec without {} quoting
    command=$(printf '%s\n' "$command" | sed 's/-exec \([^;]*\){}/-exec \1"{}"/g')
    
    # Prevent eval with uncontrolled input
    case "$command" in
        *"eval"*"\$"*|*"eval"*"\`"*)
            # This is potentially dangerous
            # In real usage, we might want to warn rather than modify
            ;;
    esac
    
    # Fix wget/curl without output specification (could overwrite files)
    case "$command" in
        *"wget http"*|*"curl http"*)
            if ! printf '%s' "$command" | grep -q -- '-O\|--output\|>'; then
                # Add safe output redirection
                command="$command > downloaded_file"
            fi
            ;;
    esac
    
    printf '%s' "$command"
}

# Check if command has security issues
has_security_issues() {
    local command="$1"
    case "$command" in
        *"rm -rf /"*|*"chmod 777"*|*"eval"*|*"exec"*"{}"*)
            return 0  # Has security issues
            ;;
        *)
            return 1  # No security issues detected
            ;;
    esac
}