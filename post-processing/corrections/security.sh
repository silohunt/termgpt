#!/bin/sh
# Security Corrections
# Prevents common security issues and unsafe patterns

apply_security_corrections() {
    local command="$1"
    
    # Focus on CORRECTIONS not covered by the main rules system
    # The rules system handles detection/warnings, we handle safe transformations
    
    # Fix dangerous find -exec without {} quoting
    # Only add single quotes if {} is not already quoted
    if printf '%s' "$command" | grep -q -- '-exec.*{}'; then
        if ! printf '%s' "$command" | grep -q -- "-exec.*['\"]{}['\"]"; then
            command=$(printf '%s\n' "$command" | sed "s/-exec \([^;]*\){}/-exec \1'{}'/g")
        fi
    fi
    
    # Quote command substitutions in echo to prevent injection
    case "$command" in
        echo\ \$\(*\)*|echo\ \`*\`*)
            # Quote unquoted command substitutions
            command=$(printf '%s\n' "$command" | sed 's/echo \$(\([^)]*\))/echo "$(\1)"/g')
            command=$(printf '%s\n' "$command" | sed 's/echo `\([^`]*\)`/echo "`\1`"/g')
            ;;
    esac
    
    # Fix wget/curl without output specification (could overwrite files)
    # This is a usability improvement, not dangerous command prevention
    case "$command" in
        wget\ http*)
            if ! printf '%s' "$command" | grep -q -- '-O\|--output\|>'; then
                # Extract filename from URL
                filename=$(printf '%s' "$command" | sed 's|.*/||' | sed 's|?.*||')
                [ -z "$filename" ] && filename="file.zip"
                command="wget -O $filename ${command#wget }"
            fi
            ;;
        curl\ http*)
            if ! printf '%s' "$command" | grep -q -- '-o\|--output\|>'; then
                # Extract filename from URL
                filename=$(printf '%s' "$command" | sed 's|.*/||' | sed 's|?.*||')
                [ -z "$filename" ] && filename="script.sh"
                command="curl -o $filename ${command#curl }"
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