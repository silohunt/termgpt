# TermGPT

A platform-aware, POSIX-compliant shell tool that converts natural language to Unix commands using a local LLM.

## Features

- Platform-aware command generation (macOS/Linux optimized)
- Local LLM inference for privacy (no cloud dependencies)
- Built-in safety checks against dangerous commands
- Intelligent clipboard and URL handling per platform
- 100% POSIX shell compliant - runs anywhere
- Interactive command review and execution

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

## Requirements

- Ollama (installed automatically by setup.sh)
- codellama:7b-instruct model (downloaded automatically)
- jq, curl (installed by setup if missing)
- python3 (optional, for explainshell feature)

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

## Documentation

- Full documentation: `doc/README.md`
- Manual page: `man termgpt` (after installation)

## License

MIT License - see LICENSE file for details.