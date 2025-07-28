# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TermGPT is a platform-aware, POSIX sh-based tool that converts natural language prompts into POSIX-compliant shell commands using a local LLM (Ollama with CodeLlama 7B). It automatically detects the operating system and available tools to provide optimized command generation while maintaining strict safety validation. The entire codebase is 100% POSIX-compliant and runs on any Unix-like system.

## Common Development Commands

### Running Tests
```bash
cd tests
./termgpt-test.sh
# To see only failures:
./termgpt-test.sh | grep -B1 "NO MATCH"
```

### Using TermGPT
```bash
# Run from project root
./bin/termgpt "your natural language request"

# Or if installed in PATH
termgpt "list all python files"
```

### Setting Up Development Environment
```bash
# Make scripts executable
chmod +x bin/termgpt
chmod +x lib/termgpt-check.sh
chmod +x tests/termgpt-test.sh

# Ensure Ollama is running
# The tool expects Ollama at http://localhost:11434
```

## Project Structure

The project follows POSIX/FHS conventions with platform-aware architecture:
```
termgpt/
├── bin/termgpt                  # Main executable
├── lib/
│   ├── termgpt-check.sh         # Validation library
│   └── termgpt-platform.sh     # Platform detection & tool mapping
├── share/termgpt/rules.txt      # Dangerous command patterns
├── doc/README.md                # Full documentation
├── man/man1/termgpt.1           # Manual page
├── tests/termgpt-test.sh        # Test suite
├── Makefile                     # Installation rules
└── setup.sh                    # Quick setup script with platform detection
```

Installation locations:
- System: `/usr/local/{bin,lib/termgpt,share/termgpt}`
- User: `~/.config/termgpt/` with platform-specific configuration

## Architecture and Key Components

### Core Flow
1. **bin/termgpt**: Main entry point with platform-aware orchestration
   - Sources platform configuration for OS-specific optimizations
   - Builds context-aware prompts with platform hints
   - Validates input length (2000 token limit)
   - Calls Ollama API with enhanced prompt
   - Extracts command from LLM response
   - Validates command safety
   - Presents platform-aware interactive menu

2. **lib/termgpt-platform.sh**: Platform detection and tool mapping
   - Detects macOS vs Linux and available tools
   - Provides functions for clipboard, URL opening, package management
   - Generates platform-specific context for LLM prompts
   - Handles graceful fallbacks when tools are missing

3. **lib/termgpt-check.sh**: Command safety validation library
   - Implements multi-level severity checking (CRITICAL, HIGH, MEDIUM, LOW)
   - Uses regex patterns from share/termgpt/rules.txt
   - Returns severity level and matching rule
   - Supports multiple rules file locations

4. **share/termgpt/rules.txt**: Comprehensive dangerous command patterns
   - Format: `[SEVERITY] pattern|description`
   - Patterns can be regex or literal strings
   - Prevents system damage, data loss, security risks

### Key Design Decisions
- **Local-first**: Uses Ollama instead of cloud APIs for privacy
- **Safety by default**: Commands are checked before display, not execution
- **Platform-aware**: Automatically detects and optimizes for macOS/Linux
- **POSIX compliance**: Pure sh with no shell-specific features
- **Flexible configuration**: Supports development, system, and user installations
- **Graceful degradation**: Works even when optional tools are missing

### Platform Intelligence
- **Detection**: Automatically identifies OS and architecture during setup
- **Tool mapping**: Maps functionality to available platform tools
- **Context injection**: LLM receives platform-specific hints for better commands
- **Smart fallbacks**: Handles missing tools gracefully with helpful messages

### Important Implementation Details
- The main script uses `set -eu` for strict POSIX error handling
- JSON parsing with `jq` for reliable API communication
- Command extraction looks for text between triple backticks
- Token counting is approximate (1 token ≈ 4 characters)
- Multi-location file resolution for different installation types
- Platform configuration stored in `~/.config/termgpt/platform.conf`

## Testing Approach

The test suite (`tests/termgpt-test.sh`) validates the safety checking mechanism:
- Tests each severity level with representative dangerous commands
- Expects specific matches for known dangerous patterns
- Returns exit code 1 on any test failure
- Coverage includes file operations, network access, system modifications

## Platform-Specific Features

### Command Generation Enhancements
- **macOS**: Generates commands using `pbcopy`, `open`, `brew`, `mdfind`
- **Linux**: Uses `xclip`/`xsel`, `xdg-open`, detected package managers
- **Fallbacks**: Provides helpful messages when tools are unavailable

### Configuration Management
- **Automatic setup**: `setup.sh` detects platform and configures optimally
- **Multiple installations**: Supports development, system, and user modes
- **Tool detection**: Identifies available clipboard/URL/package tools

## Development Notes

1. **Pure POSIX**: All scripts use only POSIX sh features for maximum compatibility
2. **Multi-location support**: Files resolved from development, system, or user locations
3. **Platform abstraction**: Platform-specific logic isolated in `termgpt-platform.sh`
4. **Automated dependency handling**: `setup.sh` installs and configures everything
5. **Comprehensive documentation**: README, man page, and inline help all updated