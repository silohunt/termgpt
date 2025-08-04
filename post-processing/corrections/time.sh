#!/bin/sh
# Time Semantic Corrections
# Fixes common temporal logic errors in find commands

apply_time_corrections() {
    local command="$1"
    local original_query="${TERMGPT_ORIGINAL_QUERY:-}"
    
    # Context-aware time logic corrections
    # Check the original query context to determine correct time direction
    
    # First, handle "older than" patterns - these should use +N
    if printf '%s' "$original_query" | grep -q -E "(older than|more than.*old|before|prior to|.*old.*than)"; then
        # "older than N days/weeks/months" should use +N
        command=$(printf '%s\n' "$command" | sed 's/-mtime -\([0-9][0-9]*\)/-mtime +\1/g')
        command=$(printf '%s\n' "$command" | sed 's/-ctime -\([0-9][0-9]*\)/-ctime +\1/g')
        command=$(printf '%s\n' "$command" | sed 's/-atime -\([0-9][0-9]*\)/-atime +\1/g')
    fi
    
    # Handle "newer than" or "within last" patterns - these should use -N  
    if printf '%s' "$original_query" | grep -q -E "(last|within|past|recent|since|newer than|after)"; then
        # "last N days", "within past N days", etc. should use -N
        command=$(printf '%s\n' "$command" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g')
        command=$(printf '%s\n' "$command" | sed 's/-ctime +\([0-9][0-9]*\)/-ctime -\1/g')
        command=$(printf '%s\n' "$command" | sed 's/-atime +\([0-9][0-9]*\)/-atime -\1/g')
    fi
    
    # Fix specific common time values regardless of context (these are almost always wrong when +)
    command=$(printf '%s\n' "$command" | sed 's/-mtime +7/-mtime -7/g')   # last week
    command=$(printf '%s\n' "$command" | sed 's/-mtime +1/-mtime -1/g')   # yesterday
    command=$(printf '%s\n' "$command" | sed 's/-mtime +3/-mtime -3/g')   # last 3 days
    
    # Handle "yesterday" specifically - should always be -1, never +1 or 1
    if printf '%s' "$original_query" | grep -q -i "yesterday"; then
        command=$(printf '%s\n' "$command" | sed 's/-mtime [+]*1/-mtime -1/g')
        command=$(printf '%s\n' "$command" | sed 's/-mtime 1/-mtime -1/g')
    fi
    
    # Fix -ctime confusion (same rules as mtime)
    command=$(printf '%s\n' "$command" | sed 's/-ctime +7/-ctime -7/g')
    command=$(printf '%s\n' "$command" | sed 's/-ctime +30/-ctime -30/g')
    command=$(printf '%s\n' "$command" | sed 's/-ctime +1/-ctime -1/g')
    
    # Fix -atime confusion
    command=$(printf '%s\n' "$command" | sed 's/-atime +7/-atime -7/g')
    command=$(printf '%s\n' "$command" | sed 's/-atime +30/-atime -30/g')
    command=$(printf '%s\n' "$command" | sed 's/-atime +1/-atime -1/g')
    
    printf '%s' "$command"
}

# Check if a command has time-related issues
has_time_issues() {
    local command="$1"
    case "$command" in
        *"-mtime +"*|*"-ctime +"*|*"-atime +"*)
            return 0  # Has potential issues
            ;;
        *)
            return 1  # No time issues detected
            ;;
    esac
}