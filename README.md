# TermGPT

A platform-aware, POSIX-compliant shell tool that converts natural language to Unix commands using a local LLM.

## Features

- **Multiple Model Support**: Choose from CodeLlama, Qwen2.5 Coder, Stable Code, and more
- **Platform-Aware**: Optimized for macOS, Linux, and WSL with automatic detection
- **Smart Post-Processing**: 95%+ success rate with intelligent correction pipeline (verified through comprehensive evaluation)
- **Local LLM Inference**: Complete privacy - no cloud dependencies
- **Advanced Safety System**: 100+ patterns detect dangerous commands (and growing)
- **Hardware Optimization**: GPU detection for smart model recommendations
- **POSIX Compliant**: Runs on any Unix-like system
- **Interactive Interface**: Review, copy, or explain commands before execution

## Quick Start

```bash
# Clone and initialize (auto-detects your platform)
git clone https://github.com/silohunt/termgpt.git
cd termgpt
./bin/termgpt init

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

# Initialize TermGPT (replaces setup.sh)
./bin/termgpt init
```

The init command will:
- Detect your platform (macOS/Linux)
- Install required dependencies (jq, Ollama)
- Download the LLM model (~4GB on first run)
- Configure platform-specific settings

#### Init Options
```bash
termgpt init                          # Interactive setup
termgpt init --headless               # Automated setup with defaults
termgpt init --model codellama:13b    # Use specific model
termgpt init --reconfigure            # Update existing installation
termgpt init --check                  # Verify installation
```

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
./bin/termgpt init

# Choose specific model
./bin/termgpt init --model qwen2.5-coder:7b
./bin/termgpt init --model stable-code:3b

# Check current model
termgpt --model
```

## Requirements

- **Ollama** (installed automatically by termgpt init)
- **LLM Model** (downloaded automatically based on your system)
- **jq, curl** (installed by init if missing)
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

For system-wide installations:
```bash
sudo make uninstall
```

For user installations, remove the config directory:
```bash
rm -rf ~/.config/termgpt
# Also remove from PATH in your shell config
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
- **Smart Corrections**: Intelligent post-processing pipeline with 95%+ success rate on practical commands
- **Complex Command Preservation**: Protects valid multi-step commands from over-correction
- **Context-Aware Processing**: Uses original query for semantic understanding
- **Multiple Models**: Switch between different coding models
- **History Tracking**: Local logging for training data (optional)
- **Comprehensive Testing**: Validated against 50+ complex scenarios across 5 categories

## How It Works

TermGPT uses a multi-layer approach to generate reliable commands:

1. **LLM Generation**: Local model converts natural language to shell commands
2. **Smart Post-Processing**: Intelligent correction pipeline with proven 95%+ success rate:
   - **Complex Command Preservation**: Protects valid multi-step commands from over-correction
   - **Platform Compatibility**: Handles macOS/Linux differences (netstat flags, case sensitivity, tool availability)
   - **Context-Aware Corrections**: Uses original query for semantic understanding
   - **Time Logic**: Fixes temporal semantics (`-mtime +7` → `-mtime -7` for "last week")
   - **File Pattern Enhancement**: Adds appropriate filters (`*.log` for log operations)
   - **Path Optimization**: Uses better default locations (`/var/log` for logs, system paths)
   - **Security Corrections**: Removes dangerous patterns while preserving functionality
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

## Testing

TermGPT includes comprehensive evaluation and testing frameworks:

### Run Evaluation Tests
```bash
# Quick performance check (10 practical commands)
cd tests/evaluation && ./run_focused_evaluation.sh

# Edge case testing (15 challenging commands)  
cd tests/evaluation && ./test_hardest_commands.sh

# Comprehensive evaluation (50 commands across all categories)
cd tests/evaluation && ./run_comprehensive_evaluation.sh
```

### Test Results
- **Practical Commands**: 95-100% success rate
- **Complex Edge Cases**: 80-93% success rate
- **Overall Performance**: 85-95% depending on command complexity

See `tests/evaluation/README.md` for detailed testing documentation.

## Documentation

- **Full documentation**: `doc/README.md`
- **Post-processing architecture**: `post-processing/docs/ARCHITECTURE.md`
- **Evaluation results**: `docs/evaluation/`
- **Manual page**: `man termgpt` (after installation)

## License

MIT License - see LICENSE file for details.