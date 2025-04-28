#!/usr/bin/env zsh

check_command_danger_level() {
  local command="$1"
  local rules_file="${TERM_GPT_RULES_PATH:-$HOME/.config/termgpt/termgpt-rules.txt}"

  export TERMGPT_MATCH_LEVEL=""
  [[ ! -f "$rules_file" ]] && return 0

  local line level pattern

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    case "$line" in
      # Match literal rule
      \[*_LITERAL\]*)
        level=$(echo "$line" | sed -E 's/^\[(CRITICAL|HIGH|MEDIUM|LOW)_LITERAL\].*/\1/')
        pattern=$(echo "$line" | sed -E 's/^\[[A-Z]+_LITERAL\][[:space:]]+//')
        if [[ "$command" == "$pattern" ]]; then
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