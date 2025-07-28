#!/bin/sh

check_command_danger_level() {
  command="$1"
  
  # Find rules file (support multiple locations)
  if [ -n "${TERMGPT_RULES_PATH:-}" ] && [ -f "$TERMGPT_RULES_PATH" ]; then
    rules_file="$TERMGPT_RULES_PATH"
  elif [ -f "$HOME/.config/termgpt/rules.txt" ]; then
    rules_file="$HOME/.config/termgpt/rules.txt"
  elif [ -f "/usr/local/share/termgpt/rules.txt" ]; then
    rules_file="/usr/local/share/termgpt/rules.txt"
  elif [ -f "/usr/share/termgpt/rules.txt" ]; then
    rules_file="/usr/share/termgpt/rules.txt"
  elif [ -f "$(dirname "$0")/../share/termgpt/rules.txt" ]; then
    rules_file="$(dirname "$0")/../share/termgpt/rules.txt"
  else
    # No rules file found, proceed without checks
    return 0
  fi

  export TERMGPT_MATCH_LEVEL=""
  [ ! -f "$rules_file" ] && return 0

  line="" level="" pattern=""

  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] || [ "${line#\#}" != "$line" ] && continue

    case "$line" in
      # Match literal rule
      \[*_LITERAL\]*)
        level=$(echo "$line" | sed -E 's/^\[(CRITICAL|HIGH|MEDIUM|LOW)_LITERAL\].*/\1/')
        pattern=$(echo "$line" | sed -E 's/^\[[A-Z]+_LITERAL\][[:space:]]+//')
        if [ "$command" = "$pattern" ]; then
          export TERMGPT_MATCH_LEVEL="$level"
          echo "$level: Dangerous command matched literal → $pattern"
          return 0
        fi
        ;;

      # Match regex rule
      \[*\]*)
        level=$(echo "$line" | sed -E 's/^\[(CRITICAL|HIGH|MEDIUM|LOW)\].*/\1/')
        pattern=$(echo "$line" | sed -E 's/^\[[A-Z]+\][[:space:]]+//')
        if echo "$command" | grep -Eq "$pattern"; then
          export TERMGPT_MATCH_LEVEL="$level"
          echo "$level: Dangerous command matched pattern → $pattern"
          return 0
        fi
        ;;
    esac
  done < "$rules_file"
}