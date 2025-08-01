#!/bin/sh
#
# termgpt-history.sh - History logging for fine-tuning data collection
#
# This library handles logging of user interactions in a format suitable
# for LLM fine-tuning. Each entry contains context, input, and output.

# History configuration
HISTORY_ENABLED="${TERMGPT_HISTORY:-true}"
HISTORY_FILE="${TERMGPT_HISTORY_FILE:-$HOME/.config/termgpt/history.jsonl}"
HISTORY_MAX_ENTRIES="${TERMGPT_HISTORY_MAX:-1000}"

# Ensure history directory exists
init_history() {
  if [ "$HISTORY_ENABLED" = "false" ]; then
    return 0
  fi
  
  history_dir=$(dirname "$HISTORY_FILE")
  if [ ! -d "$history_dir" ]; then
    mkdir -p "$history_dir" 2>/dev/null || return 1
  fi
  
  # Create history file if it doesn't exist
  if [ ! -f "$HISTORY_FILE" ]; then
    touch "$HISTORY_FILE" 2>/dev/null || return 1
  fi
}

# Get system context for fine-tuning
get_system_context() {
  platform="${TERMGPT_PLATFORM:-unknown}"
  os_version=$(uname -sr 2>/dev/null || echo "unknown")
  shell_name=$(basename "${SHELL:-sh}")
  
  # Get available tools
  clipboard_tool=""
  if command -v get_clipboard_cmd >/dev/null 2>&1; then
    clipboard_tool=$(get_clipboard_cmd)
  fi
  
  url_opener=""
  if command -v get_open_url_cmd >/dev/null 2>&1; then
    url_opener=$(get_open_url_cmd)
  fi
  
  package_manager=""
  if command -v get_package_manager >/dev/null 2>&1; then
    package_manager=$(get_package_manager)
  fi
  
  echo "{\"platform\":\"$platform\",\"os\":\"$os_version\",\"shell\":\"$shell_name\",\"tools\":{\"clipboard\":\"$clipboard_tool\",\"url_opener\":\"$url_opener\",\"package_manager\":\"$package_manager\"}}"
}

# Escape JSON strings
json_escape() {
  # Basic JSON escaping - handles quotes, newlines, backslashes
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\x0A/\\n/g; s/\x0D/\\r/g; s/\x09/\\t/g'
}

# Log interaction to history file
log_interaction() {
  if [ "$HISTORY_ENABLED" = "false" ]; then
    return 0
  fi
  
  user_prompt="$1"
  generated_command="$2"
  safety_level="$3"
  user_action="$4"  # "copied", "explained", "dismissed"
  
  if [ -z "$user_prompt" ] || [ -z "$generated_command" ]; then
    return 1
  fi
  
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%d %H:%M:%S UTC")
  session_id="${TERMGPT_SESSION_ID:-$(date +%s)}"
  
  # Get system context
  system_context=$(get_system_context)
  
  # Escape JSON values
  escaped_prompt=$(json_escape "$user_prompt")
  escaped_command=$(json_escape "$generated_command")
  escaped_safety=$(json_escape "$safety_level")
  escaped_action=$(json_escape "$user_action")
  
  # Create JSON entry in format suitable for fine-tuning (compact JSONL format)
  json_entry="{\"timestamp\":\"$timestamp\",\"session_id\":\"$session_id\",\"system_context\":$system_context,\"conversation\":[{\"role\":\"user\",\"content\":\"$escaped_prompt\"},{\"role\":\"assistant\",\"content\":\"$escaped_command\"}],\"metadata\":{\"safety_level\":\"$escaped_safety\",\"user_action\":\"$escaped_action\",\"model\":\"${MODEL:-codellama:7b-instruct}\",\"version\":\"termgpt-0.8\"}}"
  
  # Append to history file
  if echo "$json_entry" >> "$HISTORY_FILE" 2>/dev/null; then
    # Rotate history if it gets too large
    rotate_history_if_needed
    return 0
  else
    return 1
  fi
}

# Rotate history file when it gets too large
rotate_history_if_needed() {
  if [ ! -f "$HISTORY_FILE" ]; then
    return 0
  fi
  
  # Count lines in history file
  line_count=$(wc -l < "$HISTORY_FILE" 2>/dev/null || echo "0")
  
  if [ "$line_count" -gt "$HISTORY_MAX_ENTRIES" ]; then
    # Keep last 80% of entries
    keep_lines=$((HISTORY_MAX_ENTRIES * 4 / 5))
    temp_file="${HISTORY_FILE}.tmp"
    
    if tail -n "$keep_lines" "$HISTORY_FILE" > "$temp_file" 2>/dev/null; then
      mv "$temp_file" "$HISTORY_FILE"
    else
      rm -f "$temp_file" 2>/dev/null
    fi
  fi
}

# Export history in training format
export_history_for_training() {
  output_file="$1"
  format="${2:-jsonl}"  # jsonl, csv, or claude
  
  if [ ! -f "$HISTORY_FILE" ]; then
    echo "No history file found at: $HISTORY_FILE"
    return 1
  fi
  
  case "$format" in
    jsonl)
      cp "$HISTORY_FILE" "$output_file"
      echo "Exported JSONL format to: $output_file"
      ;;
    claude)
      # Format for Claude fine-tuning (conversation format)
      {
        echo "# TermGPT Training Data"
        echo "# Generated: $(date)"
        echo "# Format: User input -> Generated command"
        echo
        
        while IFS= read -r line; do
          if [ -n "$line" ]; then
            user_input=$(echo "$line" | jq -r '.conversation[0].content' 2>/dev/null)
            assistant_output=$(echo "$line" | jq -r '.conversation[1].content' 2>/dev/null)
            platform=$(echo "$line" | jq -r '.system_context.platform' 2>/dev/null)
            safety=$(echo "$line" | jq -r '.metadata.safety_level' 2>/dev/null)
            
            if [ "$user_input" != "null" ] && [ "$assistant_output" != "null" ]; then
              echo "## Example"
              echo "**Platform:** $platform"
              if [ "$safety" != "null" ] && [ -n "$safety" ]; then
                echo "**Safety:** $safety"
              fi
              echo "**User:** $user_input"
              echo "**Assistant:** \`$assistant_output\`"
              echo
            fi
          fi
        done < "$HISTORY_FILE"
      } > "$output_file"
      echo "Exported Claude format to: $output_file"
      ;;
    csv)
      # CSV format for analysis
      {
        echo "timestamp,platform,user_input,generated_command,safety_level,user_action"
        while IFS= read -r line; do
          if [ -n "$line" ]; then
            timestamp=$(echo "$line" | jq -r '.timestamp' 2>/dev/null)
            platform=$(echo "$line" | jq -r '.system_context.platform' 2>/dev/null)
            user_input=$(echo "$line" | jq -r '.conversation[0].content' 2>/dev/null)
            assistant_output=$(echo "$line" | jq -r '.conversation[1].content' 2>/dev/null)
            safety=$(echo "$line" | jq -r '.metadata.safety_level' 2>/dev/null)
            action=$(echo "$line" | jq -r '.metadata.user_action' 2>/dev/null)
            
            # Escape CSV values
            user_input=$(printf '%s' "$user_input" | sed 's/"/""/g')
            assistant_output=$(printf '%s' "$assistant_output" | sed 's/"/""/g')
            
            echo "\"$timestamp\",\"$platform\",\"$user_input\",\"$assistant_output\",\"$safety\",\"$action\""
          fi
        done < "$HISTORY_FILE"
      } > "$output_file"
      echo "Exported CSV format to: $output_file"
      ;;
    *)
      echo "Unsupported format: $format"
      echo "Supported formats: jsonl, claude, csv"
      return 1
      ;;
  esac
}

# Get history statistics
show_history_stats() {
  if [ ! -f "$HISTORY_FILE" ]; then
    echo "No history file found"
    return 1
  fi
  
  total_entries=$(wc -l < "$HISTORY_FILE" 2>/dev/null || echo "0")
  file_size=$(du -h "$HISTORY_FILE" 2>/dev/null | cut -f1 || echo "unknown")
  
  echo "History Statistics:"
  echo "  File: $HISTORY_FILE"
  echo "  Entries: $total_entries"
  echo "  Size: $file_size"
  echo "  Max entries: $HISTORY_MAX_ENTRIES"
  
  if command -v jq >/dev/null 2>&1 && [ "$total_entries" -gt 0 ]; then
    echo
    echo "Platform distribution:"
    jq -r '.system_context.platform' "$HISTORY_FILE" 2>/dev/null | sort | uniq -c | sort -nr
    
    echo
    echo "Safety levels:"
    jq -r '.metadata.safety_level // "none"' "$HISTORY_FILE" 2>/dev/null | sort | uniq -c | sort -nr
    
    echo
    echo "User actions:"
    jq -r '.metadata.user_action' "$HISTORY_FILE" 2>/dev/null | sort | uniq -c | sort -nr
  fi
}