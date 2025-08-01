# TermGPT

A platform-aware, POSIX-compliant shell tool that converts natural language to Unix commands using a local LLM.

## Features

- **Multiple Model Support**: Choose from CodeLlama, Qwen2.5 Coder, Stable Code, and more
- **Platform-Aware**: Optimized for macOS, Linux, and WSL with automatic detection
- **Smart Post-Processing**: Automatically fixes common LLM mistakes and platform issues
- **Local LLM Inference**: Complete privacy - no cloud dependencies
- **Advanced Safety System**: 100+ patterns detect dangerous commands (and growing)
- **Hardware Optimization**: GPU detection for smart model recommendations
- **POSIX Compliant**: Runs on any Unix-like system
- **Interactive Interface**: Review, copy, or explain commands before execution

## Quick Start

```bash
# Clone and setup (auto-detects your platform)
git clone https://github.com/silohunt/termgpt.git
cd termgpt
chmod +x setup.sh
./setup.sh

# Use it - commands optimized for your OS
./bin/termgpt "copy all python files to clipboard"
./bin/termgpt "find files larger than 100MB"
./bin/termgpt "compress the docs folder"
```

## Platform Features

### macOS
- Uses `pbcopy`/`pbpaste` for clipboard operations
- Uses `open` for files and URLs
- Recommends `brew` for package management
- Suggests `mdfind` for searches

### Linux
- Auto-detects `xclip`, `xsel`, or `wl-copy` for clipboard
- Uses `xdg-open` for files and URLs
- Detects package manager (apt/yum/pacman/etc.)
- Optimizes for systemd services

## Installation

### Quick Install from GitHub
```bash
# Clone the repository
git clone https://github.com/silohunt/termgpt.git
cd termgpt

# Run automatic setup
./setup.sh
```

The setup script will:
- Detect your platform (macOS/Linux)
- Install required dependencies (jq, Ollama)
- Download the LLM model (~4GB on first run)
- Configure platform-specific settings

### System-wide Installation
```bash
sudo make install
termgpt "your command"
```

### User Installation (No sudo required)
```bash
# Option 1: Add to PATH
export PATH="$PATH:$(pwd)/bin"
termgpt "your command"

# Option 2: Install to ~/bin
mkdir -p ~/bin
cp bin/termgpt ~/bin/
cp bin/termgpt-history ~/bin/
# Add ~/bin to PATH in your shell config

# Option 3: Use make
make install-user
```

## Model Options

TermGPT supports multiple high-quality coding models:

### Recommended Models
1. **CodeLlama 7B Instruct** (Default) - Best instruction following, platform-aware
2. **Qwen2.5 Coder 7B** - Good performance/memory ratio  
3. **Stable Code 3B** - Lightweight for resource-constrained systems

### Model Selection
```bash
# Use default model
./setup.sh

# Choose specific model
TERMGPT_MODEL=qwen2.5-coder:7b ./setup.sh
TERMGPT_MODEL=stable-code:3b ./setup.sh

# Check current model
termgpt --model
```

## Requirements

- **Ollama** (installed automatically by setup.sh)
- **LLM Model** (downloaded automatically based on your system)
- **jq, curl** (installed by setup if missing)
- **python3** (optional, for explainshell feature)
- **4-6GB RAM** (depending on model choice)

## Privacy & History

TermGPT logs commands locally for LLM fine-tuning (never uploaded):
```bash
# View history
termgpt-history show

# Export for training
termgpt-history export training-data.jsonl

# Disable logging
termgpt-history disable

# Clear all history
termgpt-history clear
```

## Uninstalling

Complete removal with dependency tracking:
```bash
# Dry run (see what would be removed)
./uninstall.sh --dry-run

# Full uninstall
./uninstall.sh
```

## Usage

### Basic Commands
```bash
# Generate commands from natural language
termgpt "find all python files larger than 1MB"
termgpt "show disk usage sorted by size" 
termgpt "compress all log files from last week"

# Check version and model
termgpt --version
termgpt --model

# Get help
termgpt
```

### Advanced Features
- **Safety Detection**: Automatically warns about dangerous commands
- **Platform Optimization**: Commands optimized for your OS (macOS/Linux/WSL)
- **Smart Corrections**: Fixes common mistakes like time semantics and missing file filters
- **Multiple Models**: Switch between different coding models
- **History Tracking**: Local logging for training data (optional)

## How It Works

TermGPT uses a multi-layer approach to generate reliable commands:

1. **LLM Generation**: Local model converts natural language to shell commands
2. **Smart Post-Processing**: Automatically fixes common issues:
   - Platform compatibility (macOS netstat flags, case sensitivity)
   - Time semantics (`-mtime +7` → `-mtime -7` for "last week")
   - File filtering (adds `*.log` for log compression commands)
   - Command optimization (better default paths)
3. **Safety Validation**: 100+ patterns detect dangerous operations
4. **User Review**: Interactive confirmation before execution

### Example Improvements

**Input**: `"compress all log files from last week"`

**Before Post-Processing**:
```bash
find . -type f -mtime +7 -exec gzip {} \;  # Wrong: finds files older than 7 days
```

**After Post-Processing**:
```bash
find /var/log -name "*.log" -type f -mtime -7 -exec gzip {} \;  # Correct: recent log files
```

## Documentation

- **Full documentation**: `doc/README.md`
- **Manual page**: `man termgpt` (after installation)

## License

MIT License - see LICENSE file for details.