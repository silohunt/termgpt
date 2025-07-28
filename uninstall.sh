#!/bin/sh
#
# uninstall.sh - Complete removal of TermGPT and cleanup
#
# This script removes all TermGPT files and provides information about
# dependencies that were installed but may no longer be needed.
#
# Usage: ./uninstall.sh [--dry-run] [--keep-config] [--keep-ollama]

set -eu

# Configuration
DRY_RUN=false
KEEP_CONFIG=false
KEEP_OLLAMA=false
FORCE=false

# Colors for output
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Helper functions
info() {
  printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

success() {
  printf "${GREEN}[REMOVED]${NC} %s\n" "$1"
}

warn() {
  printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

error() {
  printf "${RED}[ERROR]${NC} %s\n" "$1"
}

would_remove() {
  printf "${YELLOW}[WOULD REMOVE]${NC} %s\n" "$1"
}

# Parse command line arguments
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        info "Dry run mode - no files will be deleted"
        ;;
      --keep-config)
        KEEP_CONFIG=true
        info "Will preserve user configuration files"
        ;;
      --keep-ollama)
        KEEP_OLLAMA=true
        info "Will not remove Ollama installation"
        ;;
      --force)
        FORCE=true
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
}

show_help() {
  cat << EOF
TermGPT Uninstaller

Usage: $0 [OPTIONS]

OPTIONS:
    --dry-run       Show what would be removed without actually removing
    --keep-config   Preserve user configuration in ~/.config/termgpt/
    --keep-ollama   Don't remove Ollama (just report on it)
    --force         Skip confirmation prompts
    -h, --help      Show this help message

This script will remove:
- System-wide TermGPT installation (/usr/local/...)
- User configuration (~/.config/termgpt/)
- Man pages and documentation
- Optionally: Ollama installation and models

Dependencies installed by setup.sh will be reported but not removed.
EOF
}

# Safe file removal
safe_remove() {
  path="$1"
  description="$2"
  
  if [ ! -e "$path" ]; then
    return 0
  fi
  
  if [ "$DRY_RUN" = true ]; then
    would_remove "$description: $path"
    return 0
  fi
  
  if rm -rf "$path" 2>/dev/null; then
    success "$description: $path"
  else
    error "Failed to remove $description: $path"
    return 1
  fi
}

# Check if running as root
check_root() {
  if [ "$(id -u)" = "0" ]; then
    warn "Running as root. This will remove system-wide installation."
  fi
}

# Find TermGPT installations
find_installations() {
  echo
  info "Scanning for TermGPT installations..."
  
  # System installations
  SYSTEM_LOCATIONS=""
  for prefix in "/usr/local" "/usr" "/opt/termgpt"; do
    if [ -f "$prefix/bin/termgpt" ] || [ -d "$prefix/lib/termgpt" ] || [ -d "$prefix/share/termgpt" ]; then
      SYSTEM_LOCATIONS="$SYSTEM_LOCATIONS $prefix"
      info "Found system installation in: $prefix"
    fi
  done
  
  # User installations
  USER_CONFIG="$HOME/.config/termgpt"
  if [ -d "$USER_CONFIG" ]; then
    info "Found user configuration in: $USER_CONFIG"
  fi
  
  # Development installations (check current directory and common locations)
  DEV_LOCATIONS=""
  for dev_path in "$(pwd)" "$HOME/termgpt" "$HOME/projects/termgpt" "$HOME/src/termgpt"; do
    if [ -f "$dev_path/bin/termgpt" ] && [ -f "$dev_path/setup.sh" ]; then
      DEV_LOCATIONS="$DEV_LOCATIONS $dev_path"
      info "Found development installation in: $dev_path"
    fi
  done
}

# Remove system installation
remove_system_installation() {
  echo
  info "Removing system installations..."
  
  for prefix in $SYSTEM_LOCATIONS; do
    info "Removing from $prefix..."
    
    # Remove binaries
    safe_remove "$prefix/bin/termgpt" "TermGPT binary"
    safe_remove "$prefix/bin/termgpt-history" "TermGPT history utility"
    
    # Remove libraries
    safe_remove "$prefix/lib/termgpt" "TermGPT libraries"
    
    # Remove shared data
    safe_remove "$prefix/share/termgpt" "TermGPT shared data"
    
    # Remove documentation
    safe_remove "$prefix/share/doc/termgpt" "TermGPT documentation"
    
    # Remove man page
    safe_remove "$prefix/share/man/man1/termgpt.1" "TermGPT man page"
  done
}

# Remove user configuration
remove_user_config() {
  if [ "$KEEP_CONFIG" = true ]; then
    warn "Keeping user configuration as requested"
    return 0
  fi
  
  echo
  info "Removing user configuration..."
  safe_remove "$USER_CONFIG" "User configuration directory"
}

# Remove development installations
remove_dev_installations() {
  if [ -z "$DEV_LOCATIONS" ]; then
    return 0
  fi
  
  echo
  info "Found development installations. These should be removed manually:"
  for dev_path in $DEV_LOCATIONS; do
    warn "Development installation: $dev_path"
    warn "  Remove with: rm -rf '$dev_path' (if you're sure)"
  done
}

# Check Ollama installation
check_ollama() {
  echo
  info "Checking Ollama installation..."
  
  if ! command -v ollama >/dev/null 2>&1; then
    info "Ollama is not installed"
    return 0
  fi
  
  OLLAMA_PATH=$(command -v ollama)
  info "Found Ollama at: $OLLAMA_PATH"
  
  # Check for models
  if ollama list >/dev/null 2>&1; then
    info "Installed Ollama models:"
    ollama list | grep -v "NAME" | while read -r line; do
      if [ -n "$line" ]; then
        model_name=$(echo "$line" | awk '{print $1}')
        model_size=$(echo "$line" | awk '{print $2}')
        info "  - $model_name ($model_size)"
      fi
    done
  fi
  
  if [ "$KEEP_OLLAMA" = true ]; then
    warn "Keeping Ollama as requested"
    return 0
  fi
  
  echo
  warn "Ollama was likely installed by TermGPT setup."
  warn "To remove Ollama and its models:"
  warn "  1. Stop Ollama service: ollama serve (Ctrl+C) or sudo systemctl stop ollama"
  warn "  2. Remove models: ollama rm codellama:7b-instruct (for each model)"
  warn "  3. Remove Ollama binary: sudo rm '$OLLAMA_PATH'"
  warn "  4. Remove Ollama data: rm -rf ~/.ollama"
  if [ -f "/etc/systemd/system/ollama.service" ]; then
    warn "  5. Remove systemd service: sudo systemctl disable ollama && sudo rm /etc/systemd/system/ollama.service"
  fi
}

# Check installed dependencies
check_dependencies() {
  echo
  info "Checking dependencies that may have been installed by TermGPT setup..."
  
  # Check jq
  if command -v jq >/dev/null 2>&1; then
    JQ_PATH=$(command -v jq)
    info "jq is installed at: $JQ_PATH"
    warn "jq may have been installed by TermGPT setup"
    warn "  Remove with package manager if no longer needed"
  fi
  
  # Check curl (usually pre-installed)
  if command -v curl >/dev/null 2>&1; then
    info "curl is installed (usually system default)"
  fi
  
  # Check python3 (usually pre-installed)
  if command -v python3 >/dev/null 2>&1; then
    info "python3 is installed (usually system default)"
  fi
  
  # Check clipboard tools on Linux
  if [ "$(uname -s)" = "Linux" ]; then
    for tool in xclip xsel wl-copy; do
      if command -v "$tool" >/dev/null 2>&1; then
        TOOL_PATH=$(command -v "$tool")
        info "$tool is installed at: $TOOL_PATH"
        warn "$tool may have been installed for TermGPT clipboard support"
      fi
    done
  fi
}

# Main uninstall process
main() {
  echo "${BOLD}TermGPT Uninstaller${NC}"
  echo "=================="
  
  parse_args "$@"
  
  check_root
  find_installations
  
  # Show summary
  echo
  info "Summary of what will be removed:"
  if [ -n "$SYSTEM_LOCATIONS" ]; then
    info "- System installations: $SYSTEM_LOCATIONS"
  fi
  if [ -d "$USER_CONFIG" ] && [ "$KEEP_CONFIG" = false ]; then
    info "- User configuration: $USER_CONFIG"
  fi
  if [ -n "$DEV_LOCATIONS" ]; then
    info "- Development installations: $DEV_LOCATIONS (manual removal required)"
  fi
  
  # Confirmation
  if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
    echo
    printf "Are you sure you want to remove TermGPT? [y/N] "
    read -r response
    case "$response" in
      [Yy]*)
        info "Proceeding with removal..."
        ;;
      *)
        info "Uninstall cancelled"
        exit 0
        ;;
    esac
  fi
  
  # Perform removal
  if [ -n "$SYSTEM_LOCATIONS" ]; then
    remove_system_installation
  fi
  
  if [ -d "$USER_CONFIG" ]; then
    remove_user_config
  fi
  
  remove_dev_installations
  check_ollama
  check_dependencies
  
  echo
  if [ "$DRY_RUN" = true ]; then
    info "Dry run completed. Run without --dry-run to actually remove files."
  else
    success "TermGPT uninstall completed!"
  fi
  
  echo
  info "If you reinstall TermGPT later, you may want to:"
  info "- Remove any remaining dependencies if not needed elsewhere"
  info "- Clear Ollama models to free disk space"
  info "- Check for any remaining configuration files"
}

# Run main function with all arguments
main "$@"