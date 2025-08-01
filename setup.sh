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

# Configuration
# Available models (in order of recommendation):
# - deepseek-coder-v2:16b    - Best overall (MoE, 338 langs, 128K context) ~8GB
# - qwen2.5-coder:7b         - Great performance/memory ratio ~6GB  
# - deepseek-coder:6.7b      - Proven reliable ~7GB
# - codellama:7b-instruct    - Original default ~4GB
DEFAULT_MODEL="deepseek-coder:6.7b"  # Using proven V1 for stability
FAST_MODEL="codellama:7b-instruct-q4_0"
SMALL_MODEL="stable-code:3b"
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

# Recommend model based on hardware
recommend_model() {
  gpu_type=$(detect_gpu)
  os=$(detect_os)
  
  # Check for WSL without GPU
  if [ "$os" = "wsl" ] && [ "$gpu_type" = "none" ]; then
    warn "WSL detected without GPU passthrough" >&2
    info "WSL performance can be significantly slower than native Linux" >&2
    info "Recommended model: $SMALL_MODEL (small code model for better WSL performance)" >&2
    info "For best quality (slower): TERMGPT_MODEL=$DEFAULT_MODEL ./setup.sh" >&2
    echo "$SMALL_MODEL"
    return
  fi
  
  case "$gpu_type" in
    nvidia|amd|apple_silicon)
      info "GPU detected: $gpu_type" >&2
      info "Recommended model: $DEFAULT_MODEL (full precision for best quality)" >&2
      echo "$DEFAULT_MODEL"
      ;;
    *)
      info "No GPU detected - CPU only" >&2
      warn "Note: Quantized models may produce incorrect results for complex commands" >&2
      info "Recommended model: $DEFAULT_MODEL (full precision for safety)" >&2
      info "For faster performance, you can use:" >&2
      info "  TERMGPT_MODEL=$FAST_MODEL ./setup.sh  (quantized)" >&2
      info "  TERMGPT_MODEL=$SMALL_MODEL ./setup.sh  (small model)" >&2
      echo "$DEFAULT_MODEL"
      ;;
  esac
}

# Allow override via environment variable
if [ -n "${TERMGPT_MODEL:-}" ]; then
  MODEL="$TERMGPT_MODEL"
  info "Using model from TERMGPT_MODEL environment variable: $MODEL"
else
  MODEL=$(recommend_model)
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
  
  # Check if stdin is available
  if [ -t 0 ]; then
    printf "Do you want to proceed? [y/N] "
    read -r response
  else
    warn "No input available, skipping Ollama installation"
    response="n"
  fi
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
  if [ "$MODEL" = "$FAST_MODEL" ]; then
    info "Quantized model (~2GB, optimized for CPU performance)"
  elif [ "$MODEL" = "$SMALL_MODEL" ]; then
    info "Small code model (~2GB, optimized for speed)"
  else
    info "Full precision model (~4GB, best quality)"
  fi
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
    # Check if stdin is available
    if [ -t 0 ]; then
      printf "jq is required. Install it? [y/N] "
      read -r response
    else
      error "jq is required but not installed"
      error "Run with interactive terminal or install jq manually"
      response="n"
    fi
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
    # Check if stdin is available
    if [ -t 0 ]; then
      printf "Ollama is required. Install it? [y/N] "
      read -r response
    else
      error "Ollama is required but not installed"
      error "Run with interactive terminal or install Ollama manually"
      response="n"
    fi
    case "$response" in
      [Yy]*) install_ollama || exit 1 ;;
      *) error "Ollama is required. Please install it from https://ollama.ai"; exit 1 ;;
    esac
  fi
  
  echo
  
  # Start Ollama if needed
  if ! curl -s -f -o /dev/null "$OLLAMA_API" 2>/dev/null; then
    # Check if stdin is available
    if [ -t 0 ]; then
      printf "Ollama is not running. Start it? [y/N] "
      read -r response
    else
      error "Ollama is not running"
      error "Please start Ollama manually: ollama serve"
      response="n"
    fi
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
  
  # Show completion message with model info
  echo "====================================="
  success "TermGPT setup completed!"
  echo "====================================="
  echo
  info "Model installed: $MODEL"
  echo
  info "To use a different model, run:"
  echo "  TERMGPT_MODEL=deepseek-coder-v2:16b ./setup.sh  # Best overall (MoE)"
  echo "  TERMGPT_MODEL=qwen2.5-coder:7b ./setup.sh       # Fast & accurate"
  echo "  TERMGPT_MODEL=codellama:7b-instruct ./setup.sh  # Original default"
  echo
}

# Run main function
main "$@"