# TermGPT

A platform-aware shell tool that converts natural language to Unix commands using a local LLM.

## Features

- **Local LLM**: Complete privacy - no cloud dependencies
- **Platform-Aware**: Automatic macOS/Linux compatibility fixes
- **Simple Post-Processing**: Basic platform corrections (BSD vs GNU tools)
- **Interactive Mode**: Review commands before execution
- **Safety Detection**: Warns about dangerous operations
- **Context-Aware Shell**: Interactive mode with conversational context carryover

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

# Or use interactive shell mode
./bin/termgpt shell
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

## Requirements

- **Shell**: POSIX sh (main scripts), some features require bash
- **Dependencies**: `jq`, `curl`, `python3` (optional)
- **LLM Backend**: [Ollama](https://ollama.ai) running locally
- **Platform Tools**: Platform-specific clipboard tools (detected automatically)

## Installation

### Homebrew (Recommended)

```bash
# Install TermGPT
brew tap silohunt/termgpt
brew install termgpt

# Initialize (installs Ollama, downloads model, configures platform)
termgpt init
```

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
- **python3** (recommended, for accurate token counting and explainshell features)
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

### Interactive Shell Mode

TermGPT includes an interactive shell with context awareness:

```bash
# Start interactive shell
termgpt shell

# Example session with context carryover:
$ termgpt shell
TermGPT v0.9.4 (codellama:7b-instruct) - Interactive Mode
Type .help for commands, .quit to exit

termgpt> find all shell scripts
Generated: find . -type f -name "*.sh"

Use: .copy  .explain  .run  .save  .help

termgpt> show their sizes
Generated: find . -type f -name "*.sh" -exec du -h {} +

termgpt> compress the largest one  
Generated: find . -type f -name "*.sh" -exec du -h {} + | sort -hr | head -1 | cut -f2 | xargs gzip

termgpt> .quit
✓ Session saved
```

#### Shell Features
- **Context Awareness**: Maintains context from previous commands for natural conversation
- **Pronoun Resolution**: "find files" → "show their sizes" → "compress them" 
- **Persistent Sessions**: Each session is saved with command history
- **Safety Integration**: Context-aware prompts still go through safety validation

#### Shell Commands
- **Generation**: Type natural language to generate commands
- **Actions**: `.copy`, `.explain`, `.run`, `.save`
- **Control**: `.help`, `.quit`, `.history`, `.config`, `.stats`, `.aliases`

For detailed shell documentation, see `docs/shell-mode.md`.

### Advanced Features
- **Safety Detection**: Warns about dangerous commands
- **Platform Corrections**: Handles macOS/Linux differences
- **Multiple Models**: Switch between different coding models
- **History Tracking**: Local logging for training data (optional)
- **Interactive REPL**: Persistent shell for iterative development

## How It Works

TermGPT uses a simple approach:

1. **LLM Generation**: Local model converts natural language to shell commands
2. **Platform Corrections**: Basic fixes for macOS/Linux compatibility
3. **Safety Check**: Detects dangerous operations
4. **User Review**: Interactive confirmation before execution

### Example Platform Correction

**Input**: `"show network connections"`

**Linux**: `netstat -tulpn`  
**macOS**: `netstat -anvp tcp`

## Testing

```bash
# Run basic unit tests
cd tests/unit && ./run-unit-tests.sh

# Test post-processing modules
cd post-processing/tests && ./run-tests.sh

# Benchmark different models
cd tests/benchmarking && ./benchmark.sh
```

## Documentation

- **Post-processing system**: `post-processing/README.md`
- **Manual page**: `man termgpt` (after installation)

## Roadmap

### Planned Improvements
- [ ] **Full POSIX Compliance**: Migrate remaining bash features to POSIX sh
- [ ] **Extended Platform Support**: Enhanced Windows/WSL compatibility
- [ ] **Model Performance**: Optimization for faster inference

## License

MIT License - see LICENSE file for details.