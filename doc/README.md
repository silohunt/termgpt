# TermGPT

A platform-aware, POSIX-compliant shell tool that converts natural language to Unix commands using a local LLM (Ollama).

## Overview

TermGPT bridges the gap between natural language and shell commands by leveraging a local Large Language Model. It provides platform-specific optimizations while maintaining strict POSIX compliance, ensuring compatibility across all Unix-like systems.

## Key Features

### Platform Intelligence
- **Automatic OS Detection**: Recognizes macOS, Linux distributions, and architecture
- **Smart Command Generation**: Provides platform-optimized commands (e.g., `pbcopy` on macOS, `xclip` on Linux)
- **Tool Discovery**: Automatically detects available clipboard, URL, and package management tools
- **Context-Aware Prompts**: LLM receives platform-specific context for better command generation

### Privacy & Performance
- **Local LLM Inference**: Uses Ollama for complete privacy - no data sent to cloud services
- **Fast Response Times**: Local processing eliminates network latency
- **Offline Operation**: Works without internet connection once setup

### Safety & Security
- **Comprehensive Safety Checks**: Multi-level validation against dangerous command patterns
- **Command Review**: Never executes commands automatically - always requires user confirmation
- **Ruleset-Based Filtering**: Extensible pattern matching for critical, high, medium, and low-risk commands
- **User Override**: Safety rules can be customized per user

### Usability
- **Interactive Menu**: Simple options to copy, explain, or dismiss generated commands
- **Clipboard Integration**: Platform-appropriate clipboard operations
- **Web Integration**: Opens commands in explainshell.com for detailed explanations
- **Cross-Platform**: Single codebase runs on macOS, Linux, BSD, and other Unix systems

## Installation

TermGPT supports multiple installation methods to accommodate different use cases and environments.

### Automatic Setup (Recommended)

The setup script automatically detects your platform and configures everything:

```bash
git clone https://github.com/silohunt/termgpt.git
cd termgpt
chmod +x setup.sh
./setup.sh
```

The setup process:
1. **Platform Detection**: Identifies your OS (macOS/Linux) and architecture
2. **Dependency Installation**: Installs jq, curl, and platform-specific tools
3. **Ollama Setup**: Downloads and configures Ollama LLM server
4. **Model Download**: Pulls the codellama:7b-instruct model (~4GB)
5. **Platform Configuration**: Creates optimized config for your system
6. **Tool Detection**: Identifies available clipboard/URL tools

### System-Wide Installation

For multi-user systems or permanent installation:

```bash
sudo make install
```

This installs to `/usr/local/` following FHS conventions:
- Binary: `/usr/local/bin/termgpt`
- Libraries: `/usr/local/lib/termgpt/`
- Data: `/usr/local/share/termgpt/`
- Documentation: `/usr/local/share/doc/termgpt/`
- Manual: `/usr/local/share/man/man1/termgpt.1`

### User-Only Installation

For single-user installation without root access:

```bash
make install-user
export PATH="$PATH:$(pwd)/bin"
```

Configuration stored in `~/.config/termgpt/`

### Manual Installation

For advanced users or custom environments:

1. **Dependencies**: Install jq, curl, python3 (optional)
2. **Ollama**: Install from https://ollama.ai
3. **Service**: Start with `ollama serve`
4. **Model**: Download with `ollama pull codellama:7b-instruct`
5. **Configuration**: Create platform config manually

## Usage

### Basic Usage

```bash
termgpt "your natural language request"
```

Examples:
```bash
termgpt "list all python files"
termgpt "find files larger than 100MB"
termgpt "create a tar archive of the docs folder"
termgpt "copy all log files to the backup directory"
```

### Interactive Menu

After generating a command, TermGPT presents options:
- **[c]** Copy to clipboard (platform-aware)
- **[e]** Explain on explainshell.com
- **[q]** Quit without action

### Platform-Specific Examples

**macOS**:
```bash
termgpt "copy current directory path to clipboard"
# Generates: pwd | pbcopy

termgpt "open current directory in Finder"
# Generates: open .
```

**Linux**:
```bash
termgpt "copy current directory path to clipboard"  
# Generates: pwd | xclip -selection clipboard

termgpt "open current directory in file manager"
# Generates: xdg-open .
```

## Configuration

### Platform Configuration

TermGPT automatically creates platform-specific configuration:
- **Location**: `~/.config/termgpt/platform.conf`
- **Content**: Detected OS, tools, and optimizations
- **Regeneration**: Run `./setup.sh` again to update

### Custom Rules

Safety rules can be customized:
- **System Rules**: `share/termgpt/rules.txt`
- **User Rules**: `~/.config/termgpt/rules.txt` (overrides system)
- **Environment**: `export TERMGPT_RULES_PATH=/path/to/custom/rules.txt`

Rule format:
```
[CRITICAL] pattern|description
[HIGH] pattern|description  
[MEDIUM] pattern|description
[LOW] pattern|description
```

### Environment Variables

- `TERMGPT_PLATFORM`: Override detected platform
- `TERMGPT_RULES_PATH`: Custom rules file location
- `TERMGPT_MODEL`: Change LLM model (default: codellama:7b-instruct)
