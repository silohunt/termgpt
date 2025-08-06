#!/bin/sh
# Normalization Corrections
# Reduces command variations for better consistency

apply_normalization_corrections() {
    local command="$1"
    local original_query="${2:-}"
    
    # Normalize path placeholders to concrete paths
    # Replace generic placeholders with sensible defaults
    command=$(printf '%s\n' "$command" | sed 's|/path/to/search|.|g')
    command=$(printf '%s\n' "$command" | sed 's|/path/to/files|.|g')
    command=$(printf '%s\n' "$command" | sed 's|/path/to/log/files|/var/log|g')
    command=$(printf '%s\n' "$command" | sed 's|/path/to/backups|/backup|g')
    command=$(printf '%s\n' "$command" | sed 's|/path/to/old/logs|/var/log|g')
    
    # Normalize watch command variations
    # watch -n 1 'df -h' -> watch -n1 'df -h'
    command=$(printf '%s\n' "$command" | sed "s/watch -n 1 /watch -n1 /g")
    
    # Normalize process listing commands for consistency
    case "$command" in
        *"ps -eo"*"%mem"*|*"ps -A -o %mem"*|*"top -o %MEM"*|*"top -o %mem"*|*"top -o +%mem"*)
            # Standardize all memory-related process queries to ps aux format
            if echo "$original_query" | grep -qi "memory\|process.*mem"; then
                command="ps aux --sort=-%mem | head -10"
            fi
            ;;
        *"ps -eo"*"size"*|*"ps -eo"*"rss"*)
            # Also normalize size/rss queries to consistent format
            if echo "$original_query" | grep -qi "memory\|process.*mem"; then
                command="ps aux --sort=-%mem | head -10"
            fi
            ;;
    esac
    
    # Normalize netstat variations for port checking
    case "$command" in
        *"netstat -nltp"*|*"netstat -tlnp"*)
            # These are equivalent, standardize order
            command=$(printf '%s\n' "$command" | sed 's/netstat -nltp/netstat -tnlp/g')
            command=$(printf '%s\n' "$command" | sed 's/netstat -tlnp/netstat -tnlp/g')
            ;;
    esac
    
    # Normalize find command for log files
    # Standardize -name and -type order
    command=$(printf '%s\n' "$command" | sed 's/find \(.*\) -name \(.*\) -type f/find \1 -type f -name \2/g')
    
    # Remove trailing slashes from paths (except root /)
    command=$(printf '%s\n' "$command" | sed 's|\([^/]\)/$|\1|g')
    
    # Normalize gzip commands
    # -execdir -> -exec for consistency
    command=$(printf '%s\n' "$command" | sed 's/-execdir gzip/-exec gzip/g')
    
    # Remove redundant dollar sign prompt indicators
    command=$(printf '%s\n' "$command" | sed 's/^\$ //')
    
    printf '%s' "$command"
}

# Check if normalization would change the command
has_normalization_issues() {
    local command="$1"
    case "$command" in
        *"/path/to/"*|*"watch -n 1"*|*"ps -eo"*|*"top -o"*)
            return 0  # Has normalization opportunities
            ;;
        *)
            return 1  # No normalization needed
            ;;
    esac
}