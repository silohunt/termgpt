#!/bin/sh
# macOS Platform Corrections
# Simple, focused fixes for macOS compatibility

apply_macos_corrections() {
  local command="$1"
  
  # Fix common macOS issues
  # Remove unsupported netstat -p flag
  command=$(printf '%s\n' "$command" | sed 's/netstat -[a-zA-Z]*p[a-zA-Z]*/netstat -an/g')
  # Fix UDP case sensitivity (macOS outputs lowercase)
  command=$(printf '%s\n' "$command" | sed 's/grep [^|]*UDP[^|]*/grep -i udp/g')
  command=$(printf '%s\n' "$command" | sed 's/grep "UDP"/grep -i "udp"/g')
  command=$(printf '%s\n' "$command" | sed "s/grep 'UDP'/grep -i 'udp'/g")
  # Use lsof instead of netstat -p combinations
  command=$(printf '%s\n' "$command" | sed 's/netstat.*-p.*|.*grep/lsof -i/g')
  
  printf '%s' "$command"
}