# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TermGPT is a platform-aware, POSIX sh-based tool that converts natural language prompts into POSIX-compliant shell commands using a local LLM (Ollama with CodeLlama 7B). It automatically detects the operating system and available tools to provide optimized command generation while maintaining strict safety validation. The entire codebase is 100% POSIX-compliant and runs on any Unix-like system.

**Recent Major Improvements:**
- Comprehensive history logging system for LLM fine-tuning data collection
- Enhanced security with fixed shell injection vulnerabilities 
- Complete uninstaller for safe testing and clean removal
- Fixed JSONL format issues for proper history storage
- Added missing safety rules for dangerous find operations
- Improved platform detection and configuration

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

# Managing history
termgpt-history show           # View recent commands
termgpt-history stats          # Show usage statistics
termgpt-history export data.jsonl  # Export for LLM training
termgpt-history disable        # Turn off history logging
termgpt-history clear          # Clear all history
```

### Setting Up Development Environment
```bash
# Make scripts executable
chmod +x bin/termgpt bin/termgpt-history
chmod +x lib/termgpt-check.sh lib/termgpt-platform.sh lib/termgpt-history.sh
chmod +x tests/termgpt-test.sh
chmod +x setup.sh uninstall.sh

# Run setup to install dependencies and configure platform
./setup.sh

# Ensure Ollama is running
# The tool expects Ollama at http://localhost:11434
```

### Testing and Safety
```bash
# Run complete uninstallation (with dry-run option)
./uninstall.sh --dry-run

# Test in Docker container
docker build -f test/Dockerfile.alpine-local -t termgpt-test .
docker run -it --rm termgpt-test

# Run automated tests
./test/test-in-container.sh
```

## Project Structure

The project follows POSIX/FHS conventions with platform-aware architecture:
```
termgpt/
├── bin/
│   ├── termgpt                  # Main executable
│   └── termgpt-history          # History management tool
├── lib/
│   ├── termgpt-check.sh         # Validation library
│   ├── termgpt-platform.sh      # Platform detection & tool mapping
│   └── termgpt-history.sh       # History logging functions
├── share/termgpt/rules.txt      # Dangerous command patterns (109 rules)
├── test/                        # Testing infrastructure
│   ├── Dockerfile.alpine        # Alpine Linux test environment
│   ├── Dockerfile.alpine-local  # Local code testing
│   └── test-in-container.sh     # Automated test runner
├── doc/README.md                # Full documentation
├── man/man1/termgpt.1           # Manual page
├── tests/termgpt-test.sh        # Unit test suite
├── Makefile                     # Installation rules
├── setup.sh                     # Quick setup script with platform detection
├── uninstall.sh                 # Complete removal tool
└── CLAUDE.md                    # This file
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
   - Logs interaction to history (JSONL format)
   - Presents platform-aware interactive menu

2. **bin/termgpt-history**: History management utility
   - Shows recent command history with formatting
   - Exports history in JSONL/Claude/CSV formats
   - Provides usage statistics and analytics
   - Manages privacy settings (enable/disable logging)
   - Rotates history files at 1000 entries

3. **lib/termgpt-platform.sh**: Platform detection and tool mapping
   - Detects macOS vs Linux and available tools
   - Provides functions for clipboard, URL opening, package management
   - Generates platform-specific context for LLM prompts
   - Handles graceful fallbacks when tools are missing

4. **lib/termgpt-check.sh**: Command safety validation library
   - Implements multi-level severity checking (CRITICAL, HIGH, MEDIUM, LOW)
   - Uses regex patterns from share/termgpt/rules.txt
   - Returns severity level and matching rule
   - Supports multiple rules file locations

5. **lib/termgpt-history.sh**: History logging library
   - Logs all interactions in JSONL format
   - Captures platform context, timestamps, safety levels
   - Provides JSON escaping for safe storage
   - Implements automatic rotation at 1000 entries
   - Formats data for LLM fine-tuning

6. **share/termgpt/rules.txt**: Comprehensive dangerous command patterns
   - Format: `[SEVERITY] pattern|description`
   - Patterns can be regex or literal strings
   - Prevents system damage, data loss, security risks
   - Now includes find -delete patterns

### Key Design Decisions
- **Local-first**: Uses Ollama instead of cloud APIs for privacy
- **Safety by default**: Commands are checked before display, not execution
- **Platform-aware**: Automatically detects and optimizes for macOS/Linux
- **POSIX compliance**: Pure sh with no shell-specific features
- **Flexible configuration**: Supports development, system, and user installations
- **Graceful degradation**: Works even when optional tools are missing
- **Privacy-conscious**: History logging can be disabled with `termgpt-history disable`
- **Training-ready**: History exported in JSONL format for LLM fine-tuning
- **Clean removal**: Complete uninstaller removes all traces of installation

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
- History stored in `~/.config/termgpt/history.jsonl` (JSONL format)
- Security fixes: No more eval usage, all commands properly escaped
- JSONL format: Each line is a complete JSON object (no pretty printing)

## Testing Approach

The test suite includes multiple layers:

1. **Unit Tests** (`tests/termgpt-test.sh`):
   - Tests each severity level with representative dangerous commands
   - Expects specific matches for known dangerous patterns
   - Returns exit code 1 on any test failure
   - Coverage includes file operations, network access, system modifications

2. **Integration Tests** (`test/test-in-container.sh`):
   - Tests setup.sh functionality
   - Validates uninstaller behavior
   - Checks POSIX compliance
   - Runs unit tests in clean environment

3. **Container Testing** (Alpine Linux):
   - Provides isolated test environment
   - Validates cross-platform compatibility
   - Tests with minimal dependencies
   - Supports both GitHub and local code testing

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
6. **Security hardening**: Fixed eval usage, command injection vulnerabilities
7. **History system**: JSONL format for LLM training, privacy controls included
8. **Clean uninstall**: Complete removal script with dependency tracking
9. **Testing infrastructure**: Docker-based testing for safe validation

## Critical Security Fixes Applied

1. **Shell Injection**: Replaced `eval "$CLIPBOARD_CMD"` with safe case statements
2. **Command Injection**: Fixed unsafe command construction in multiple places  
3. **File Sourcing**: Validated all sourced files exist before loading
4. **JSON Format**: Fixed malformed JSON in history by using compact JSONL
5. **Safety Rules**: Added missing `find.*-delete` pattern detection

## History System Details

The history system captures:
- User prompts and generated commands
- Platform context (OS, shell, available tools)
- Safety levels for dangerous commands
- User actions (copied, explained, dismissed)
- Timestamps and session IDs

Export formats:
- **JSONL**: Raw format for direct LLM training
- **Claude**: Formatted for Anthropic Claude fine-tuning
- **CSV**: Simple format for analysis

Privacy features:
- Disable with: `termgpt-history disable`
- Clear all data: `termgpt-history clear`
- Auto-rotation at 1000 entries
- Local storage only (no cloud sync)