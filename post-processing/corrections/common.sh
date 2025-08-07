#!/bin/sh
# Common Corrections
# Platform-agnostic fixes that apply to all systems

apply_common_corrections() {
  local command="$1"
  
  # Fix mtime confusion: "from last week" should use -mtime -7, not +7
  case "$command" in
    *-mtime\ +7*) command=$(printf '%s\n' "$command" | sed 's/-mtime +7/-mtime -7/g') ;;
  esac
  
  # Add .log filter if command seems to be looking for log files but missing extension
  if printf '%s' "$command" | grep -q 'find.*-type f' && ! printf '%s' "$command" | grep -q '\.log'; then
    # Check if this might be a log-related command by looking for common patterns
    case "$command" in
      *gzip*|*compress*|*archive*) 
        # Likely working with log files, add .log filter
        command=$(printf '%s\n' "$command" | sed 's/find \([^ ]*\) -type f/find \1 -name "*.log" -type f/')
        ;;
    esac
  fi
  
  printf '%s' "$command"
}