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
git clone https://github.com/YOUR-USERNAME/termgpt.git
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

### Automatic Setup (Recommended)
```bash
./setup.sh
```
Detects your platform and installs all dependencies.

### System-wide Installation
```bash
sudo make install
termgpt "your command"
```

### User Installation
```bash
make install-user
export PATH="$PATH:$(pwd)/bin"
termgpt "your command"
```

## Requirements

- Ollama (installed automatically by setup.sh)
- codellama:7b-instruct model (downloaded automatically)
- jq, curl (installed by setup if missing)
- python3 (optional, for explainshell feature)

## Documentation

- Full documentation: `doc/README.md`
- Manual page: `man termgpt` (after installation)
- Development guide: `CLAUDE.md`

## License

This is free software. See LICENSE for details.