#!/bin/sh
#
# setup.sh - Install and configure dependencies for TermGPT
#
# This script handles installation of all required dependencies:
# - Ollama (LLM server)
# - Required shell utilities (jq, curl)
# - Downloads the required LLM model
#
# Usage: ./setup.sh

set -eu

# Available Models Configuration
MODEL_CODELLAMA_7B="codellama:7b-instruct"
MODEL_DEEPSEEK_V2="deepseek-coder-v2:16b" 
MODEL_DEEPSEEK_V1="deepseek-coder:6.7b"
MODEL_QWEN_CODER="qwen2.5-coder:7b"
MODEL_STABLE_CODE="stable-code:3b"
MODEL_FAST_QUANT="codellama:7b-instruct-q4_0"

# Default fallbacks (will be overridden by interactive selection)
DEFAULT_MODEL="$MODEL_DEEPSEEK_V2"
FAST_MODEL="$MODEL_FAST_QUANT"
SMALL_MODEL="$MODEL_STABLE_CODE"
OLLAMA_API="http://localhost:11434/api/tags"

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Helper functions
info() {
  printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

success() {
  printf "${GREEN}[OK]${NC} %s\n" "$1"
}

warn() {
  printf "${YELLOW}[!]${NC} %s\n" "$1"
}

error() {
  printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# OS and architecture detection
detect_os() {
  case "$(uname -s)" in
    Darwin*) echo "macos" ;;
    Linux*) 
      # Check if running in WSL
      if grep -q "microsoft" /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unknown" ;;
  esac
}

# Detect GPU availability
detect_gpu() {
  # Check for NVIDIA GPU
  if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi >/dev/null 2>&1; then
      echo "nvidia"
      return
    fi
  fi
  
  # Check for AMD GPU (Linux)
  if [ -d "/sys/class/drm" ]; then
    for card in /sys/class/drm/card*/device/vendor; do
      if [ -r "$card" ] && grep -q "0x1002" "$card" 2>/dev/null; then
        echo "amd"
        return
      fi
    done
  fi
  
  # Check for Apple Silicon GPU (macOS)
  if [ "$(uname)" = "Darwin" ]; then
    if sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -q "Apple M[0-9]"; then
      echo "apple_silicon"
      return
    fi
  fi
  
  echo "none"
}

# Interactive model selection
select_model_interactive() {
  gpu_type=$(detect_gpu)
  os=$(detect_os)
  
  echo
  info "🤖 Model Selection for TermGPT"
  echo
  
  # Show system info
  if [ "$gpu_type" != "none" ]; then
    success "GPU detected: $gpu_type"
  else
    warn "No GPU detected - CPU only"
  fi
  
  if [ "$os" = "wsl" ]; then
    warn "WSL detected - performance may be slower"
  fi
  
  echo
  info "Available models:"
  echo
  printf "  ${BLUE}1)${NC} DeepSeek Coder V2 16B     ${GREEN}[RECOMMENDED]${NC}\n"
  printf "     • Best performance, MoE architecture (2.4B active params)\n"
  printf "     • 338 programming languages, 128K context\n"
  printf "     • ~8GB RAM required\n\n"
  
  printf "  ${BLUE}2)${NC} Qwen2.5 Coder 7B          ${GREEN}[FAST & ACCURATE]${NC}\n"
  printf "     • Excellent performance vs memory ratio\n"
  printf "     • Beats GPT-4o on many benchmarks\n"
  printf "     • ~6GB RAM required\n\n"
  
  printf "  ${BLUE}3)${NC} DeepSeek Coder V1 6.7B     ${YELLOW}[PROVEN]${NC}\n"
  printf "     • Well-tested, reliable performance\n"
  printf "     • Better than CodeLlama 34B\n"
  printf "     • ~7GB RAM required\n\n"
  
  printf "  ${BLUE}4)${NC} CodeLlama 7B               ${YELLOW}[STABLE]${NC}\n"
  printf "     • Original TermGPT default\n"
  printf "     • Most compatible\n"
  printf "     • ~4GB RAM required\n\n"
  
  printf "  ${BLUE}5)${NC} Stable Code 3B             ${GREEN}[LIGHTWEIGHT]${NC}\n"
  printf "     • Best for WSL/low-memory systems\n"
  printf "     • Code-specialized model\n"
  printf "     • ~2GB RAM required\n\n"
  
  # Smart defaults based on system
  if [ "$os" = "wsl" ] && [ "$gpu_type" = "none" ]; then
    default_choice="5"
    info "Recommended for your WSL system: Option 5 (Stable Code 3B)"
  elif [ "$gpu_type" != "none" ]; then
    default_choice="1"
    info "Recommended for your GPU system: Option 1 (DeepSeek V2)"
  else
    default_choice="2"
    info "Recommended for your CPU system: Option 2 (Qwen2.5 Coder)"
  fi
  
  echo
  printf "Choose model [1-5] (default: $default_choice): "
  read -r choice
  
  # Use default if empty
  if [ -z "$choice" ]; then
    choice="$default_choice"
  fi
  
  case "$choice" in
    1) echo "$MODEL_DEEPSEEK_V2" ;;
    2) echo "$MODEL_QWEN_CODER" ;;
    3) echo "$MODEL_DEEPSEEK_V1" ;;
    4) echo "$MODEL_CODELLAMA_7B" ;;
    5) echo "$MODEL_STABLE_CODE" ;;
    *) 
      warn "Invalid choice, using recommended default"
      case "$default_choice" in
        1) echo "$MODEL_DEEPSEEK_V2" ;;
        2) echo "$MODEL_QWEN_CODER" ;;
        5) echo "$MODEL_STABLE_CODE" ;;
      esac
      ;;
  esac
}

# Model selection logic
if [ -n "${TERMGPT_MODEL:-}" ]; then
  MODEL="$TERMGPT_MODEL"
  info "Using model from TERMGPT_MODEL environment variable: $MODEL"
elif [ "${TERMGPT_INTERACTIVE:-true}" = "false" ]; then
  # Non-interactive mode - use smart defaults
  gpu_type=$(detect_gpu)
  os=$(detect_os)
  if [ "$os" = "wsl" ] && [ "$gpu_type" = "none" ]; then
    MODEL="$MODEL_STABLE_CODE"
  elif [ "$gpu_type" != "none" ]; then
    MODEL="$MODEL_DEEPSEEK_V2"
  else
    MODEL="$MODEL_QWEN_CODER"
  fi
  info "Auto-selected model for your system: $MODEL"
else
  # Interactive selection
  MODEL=$(select_model_interactive)
  success "Selected model: $MODEL"
fi

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    success "$1 is installed"
    return 0
  else
    error "$1 is not installed"
    return 1
  fi
}

install_jq() {
  os=$(detect_os)
  info "Installing jq..."
  
  case "$os" in
    macos)
      if command -v brew >/dev/null 2>&1; then
        brew install jq
      else
        error "Homebrew not found. Please install jq manually: https://stedolan.github.io/jq/download/"
        return 1
      fi
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        info "Installing jq via apt-get (requires sudo)"
        sudo apt-get update && sudo apt-get install -y jq
      elif command -v yum >/dev/null 2>&1; then
        info "Installing jq via yum (requires sudo)"
        sudo yum install -y jq
      elif command -v pacman >/dev/null 2>&1; then
        info "Installing jq via pacman (requires sudo)"
        sudo pacman -S jq
      else
        error "Package manager not found. Please install jq manually: https://stedolan.github.io/jq/download/"
        return 1
      fi
      ;;
    *)
      error "Unsupported OS. Please install jq manually: https://stedolan.github.io/jq/download/"
      return 1
      ;;
  esac
}

install_ollama() {
  os=$(detect_os)
  info "Installing Ollama..."
  
  if [ "$os" = "unknown" ]; then
    error "Unsupported operating system"
    error "Please install Ollama manually from https://ollama.ai"
    return 1
  fi
  
  # Use Ollama's official install script (with user confirmation)
  warn "This will download and execute Ollama's installation script from the internet."
  printf "Do you want to proceed? [y/N] "
  read -r response
  case "$response" in
    [Yy]*)
      if curl -fsSL https://ollama.ai/install.sh | sh; then
        success "Ollama installed successfully"
        return 0
      else
        error "Failed to install Ollama"
        return 1
      fi
      ;;
    *)
      error "Installation cancelled. Please install Ollama manually from https://ollama.ai"
      return 1
      ;;
  esac
}

start_ollama() {
  info "Starting Ollama service..."
  
  # Check if already running
  if curl -s -f -o /dev/null "$OLLAMA_API" 2>/dev/null; then
    success "Ollama is already running"
    return 0
  fi
  
  # Try to start Ollama
  if command -v systemctl >/dev/null 2>&1 && systemctl is-enabled ollama >/dev/null 2>&1; then
    info "Starting Ollama via systemd (requires sudo)..."
    sudo systemctl start ollama
    sleep 3
  else
    info "Starting Ollama in background..."
    ollama serve >/dev/null 2>&1 &
    pid=$!
    info "Ollama started with PID $pid"
    info "Note: You may want to run 'ollama serve' in a separate terminal for better control"
    sleep 5
  fi
  
  # Verify it's running
  attempts=0
  while [ $attempts -lt 10 ]; do
    if curl -s -f -o /dev/null "$OLLAMA_API" 2>/dev/null; then
      success "Ollama is running and accessible"
      return 0
    fi
    attempts=$((attempts + 1))
    info "Waiting for Ollama to start... (attempt $attempts/10)"
    sleep 2
  done
  
  error "Failed to start Ollama"
  return 1
}

download_model() {
  info "Checking for model '$MODEL'..."
  
  if curl -s "$OLLAMA_API" 2>/dev/null | grep -q "\"$MODEL\""; then
    success "Model '$MODEL' is already available"
    return 0
  fi
  
  info "Downloading model '$MODEL'"
  case "$MODEL" in
    "$MODEL_DEEPSEEK_V2")
      info "DeepSeek Coder V2 16B (~8GB, MoE architecture with 2.4B active params)"
      ;;
    "$MODEL_QWEN_CODER")
      info "Qwen2.5 Coder 7B (~6GB, excellent performance/memory ratio)"
      ;;
    "$MODEL_DEEPSEEK_V1")
      info "DeepSeek Coder V1 6.7B (~7GB, proven reliable performance)"
      ;;
    "$MODEL_CODELLAMA_7B")
      info "CodeLlama 7B (~4GB, stable and compatible)"
      ;;
    "$MODEL_STABLE_CODE")
      info "Stable Code 3B (~2GB, lightweight and fast)"
      ;;
    "$MODEL_FAST_QUANT")
      info "CodeLlama Quantized (~2GB, optimized for CPU)"
      ;;
    *)
      info "Selected model (size varies by model)"
      ;;
  esac
  info "This may take several minutes..."
  
  if ollama pull "$MODEL"; then
    success "Model '$MODEL' downloaded successfully"
    return 0
  else
    error "Failed to download model '$MODEL'"
    return 1
  fi
}

setup_config() {
  info "Setting up TermGPT configuration..."
  
  config_dir="$HOME/.config/termgpt"
  if [ ! -d "$config_dir" ]; then
    mkdir -p "$config_dir"
    success "Created config directory: $config_dir"
  fi
  
  # Copy lib and rules files for user installation
  if [ -f "lib/termgpt-check.sh" ]; then
    mkdir -p "$config_dir/lib"
    cp lib/termgpt-check.sh "$config_dir/lib/"
    success "Copied validation library"
  fi
  
  if [ -f "lib/termgpt-history.sh" ]; then
    mkdir -p "$config_dir/lib"
    cp lib/termgpt-history.sh "$config_dir/lib/"
    success "Copied history library"
  fi
  
  if [ -f "lib/termgpt-platform.sh" ]; then
    mkdir -p "$config_dir/lib"
    cp lib/termgpt-platform.sh "$config_dir/lib/"
    success "Copied platform library"
  fi
  
  if [ -f "share/termgpt/rules.txt" ]; then
    cp "share/termgpt/rules.txt" "$config_dir/"
    success "Copied rules file"
  fi
  
  # Create platform configuration
  create_platform_config "$config_dir/platform.conf"
}

create_platform_config() {
  platform_conf="$1"
  os=$(detect_os)
  arch=$(detect_arch)
  
  info "Creating platform configuration for $os/$arch..."
  
  cat > "$platform_conf" << EOF
#!/bin/sh
# Platform configuration generated by TermGPT setup
# Generated on: $(date)
# Platform: $os/$arch

TERMGPT_PLATFORM="$os"
TERMGPT_ARCH="$arch"
TERMGPT_MODEL="$MODEL"

# Source the platform library
if [ -f "\$HOME/.config/termgpt/lib/termgpt-platform.sh" ]; then
  . "\$HOME/.config/termgpt/lib/termgpt-platform.sh"
elif [ -f "/usr/local/lib/termgpt/termgpt-platform.sh" ]; then
  . "/usr/local/lib/termgpt/termgpt-platform.sh"
elif [ -f "/usr/lib/termgpt/termgpt-platform.sh" ]; then
  . "/usr/lib/termgpt/termgpt-platform.sh"
fi

# Detected tools
EOF

  # Detect and save clipboard command
  case "$os" in
    macos)
      echo "# Clipboard: pbcopy (built-in)" >> "$platform_conf"
      ;;
    linux)
      if command -v xclip >/dev/null 2>&1; then
        echo "# Clipboard: xclip (detected)" >> "$platform_conf"
      elif command -v xsel >/dev/null 2>&1; then
        echo "# Clipboard: xsel (detected)" >> "$platform_conf"
      elif command -v wl-copy >/dev/null 2>&1; then
        echo "# Clipboard: wl-copy (detected)" >> "$platform_conf"
      else
        echo "# Clipboard: none detected - install xclip or xsel" >> "$platform_conf"
      fi
      ;;
  esac
  
  # Detect and save URL opener
  case "$os" in
    macos)
      echo "# URL opener: open (built-in)" >> "$platform_conf"
      ;;
    linux)
      if command -v xdg-open >/dev/null 2>&1; then
        echo "# URL opener: xdg-open (detected)" >> "$platform_conf"
      else
        echo "# URL opener: none detected" >> "$platform_conf"
      fi
      ;;
  esac
  
  success "Created platform configuration"
  
  # Copy platform library too
  if [ -f "lib/termgpt-platform.sh" ]; then
    cp lib/termgpt-platform.sh "$config_dir/lib/"
  fi
  
  # Create initial configuration with privacy options
  config_file="$config_dir/config"
  if [ ! -f "$config_file" ]; then
    cat > "$config_file" << EOF
# TermGPT Configuration
# This file is sourced by TermGPT to set environment variables

# History logging (set to false to disable)
TERMGPT_HISTORY=true

# History file location (default: ~/.config/termgpt/history.jsonl)
# TERMGPT_HISTORY_FILE="\$HOME/.config/termgpt/history.jsonl"

# Maximum history entries before rotation (default: 1000)
# TERMGPT_HISTORY_MAX=1000

# Platform override (usually auto-detected)
# TERMGPT_PLATFORM=macos

# Custom rules file location
# TERMGPT_RULES_PATH="\$HOME/.config/termgpt/rules.txt"
EOF
    success "Created configuration file with privacy settings"
    
    echo
    info "Privacy and History Settings:"
    info "  - History logging is ENABLED by default"
    info "  - History is stored locally in: $config_dir/history.jsonl"
    info "  - To disable: run 'termgpt-history disable'"
    info "  - To view/export history: run 'termgpt-history --help'"
  fi
}

main() {
  echo "TermGPT Setup Script"
  echo "===================="
  echo
  
  info "Detecting system: $(detect_os) $(detect_arch)"
  echo
  
  # Check dependencies
  info "Checking dependencies..."
  
  # Check curl (required for this script and termgpt)
  if ! check_command curl; then
    error "curl is required but not installed"
    error "Please install curl and run this script again"
    exit 1
  fi
  
  # Check and install jq
  if ! check_command jq; then
    printf "jq is required. Install it? [y/N] "
    read -r response
    case "$response" in
      [Yy]*) install_jq || exit 1 ;;
      *) error "jq is required. Please install it manually."; exit 1 ;;
    esac
  fi
  
  # Check Python 3 (for URL encoding)
  if ! check_command python3; then
    warn "python3 is not installed (required for 'explain' feature)"
    warn "The tool will work but the 'explain on explainshell.com' feature will not"
  fi
  
  echo
  
  # Check and install Ollama
  if ! check_command ollama; then
    printf "Ollama is required. Install it? [y/N] "
    read -r response
    case "$response" in
      [Yy]*) install_ollama || exit 1 ;;
      *) error "Ollama is required. Please install it from https://ollama.ai"; exit 1 ;;
    esac
  fi
  
  echo
  
  # Start Ollama if needed
  if ! curl -s -f -o /dev/null "$OLLAMA_API" 2>/dev/null; then
    printf "Ollama is not running. Start it? [y/N] "
    read -r response
    case "$response" in
      [Yy]*) start_ollama || exit 1 ;;
      *) warn "Please start Ollama manually with: ollama serve" ;;
    esac
  fi
  
  echo
  
  # Download model
  download_model || exit 1
  
  echo
  
  # Setup configuration
  setup_config
  
  echo
  success "Setup complete!"
  echo
  info "To use TermGPT:"
  info "  ./bin/termgpt \"your natural language command\""
  echo
  info "To add to PATH (optional):"
  info "  export PATH=\"\$PATH:$(pwd)/bin\""
  echo
  
  # Show platform-specific tips
  os=$(detect_os)
  case "$os" in
    macos)
      info "Platform-specific features for macOS:"
      info "  - Clipboard integration with pbcopy"
      info "  - URL opening with 'open' command"
      info "  - Commands will be optimized for macOS"
      ;;
    wsl)
      warn "Windows Subsystem for Linux (WSL) detected"
      info "Note: Performance may be slower than native Linux"
      if [ "$(detect_gpu)" = "none" ]; then
        info "GPU passthrough not detected - consider using smaller models for better performance"
      fi
      info "Platform-specific features for WSL/Linux:"
      if command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1; then
        info "  - Clipboard integration detected"
      else
        warn "  - No clipboard integration (install xclip for clipboard support)"
      fi
      ;;
    linux)
      info "Platform-specific features for Linux:"
      if command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1; then
        info "  - Clipboard integration detected"
      else
        warn "  - No clipboard tool found. Install xclip or xsel for clipboard support"
      fi
      if command -v xdg-open >/dev/null 2>&1; then
        info "  - URL opening with xdg-open"
      fi
      info "  - Commands will be optimized for Linux"
      ;;
  esac
  echo
}

# Run main function
main "$@"