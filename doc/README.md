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

The init command automatically detects your platform and configures everything:

```bash
git clone https://github.com/silohunt/termgpt.git
cd termgpt
./bin/termgpt init
```

The initialization process:
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

TermGPT converts natural language descriptions into shell commands using a local LLM with intelligent post-processing for reliability and safety.

### Command Processing Pipeline

TermGPT uses a sophisticated multi-stage pipeline to ensure reliable command generation:

#### 1. Natural Language Processing
The local LLM model analyzes your request and generates an initial shell command.

#### 2. Smart Post-Processing
Commands are automatically improved through platform-aware corrections:

**Platform Compatibility Fixes**:
- macOS: Removes unsupported `netstat -p` flags → uses `netstat -an` or `lsof`
- macOS: Fixes case sensitivity (`grep UDP` → `grep -i udp`)
- Linux: Preserves GNU-specific options

**Semantic Corrections**:
- Time logic: `"from last week"` uses `-mtime -7` (not `+7`)
- File filtering: Log operations get `*.log` filters automatically
- Path optimization: Uses meaningful defaults (`/var/log` vs `.`)

**Security Hardening**:
- Prevents shell injection in post-processing
- Uses `printf` instead of `echo` for safety
- Fail-safe error handling

#### 3. Safety Validation
- 100+ regex patterns detect dangerous operations
- Multi-level warnings (CRITICAL, HIGH, MEDIUM, LOW)
- User confirmation required for risky commands

#### 4. Interactive Review
- View generated command before execution
- Copy to clipboard or explain on explainshell.com
- Optional history logging for improvement

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

### Post-Processing Examples

See how TermGPT automatically improves generated commands:

#### Time-Based Commands
```bash
# Input: "compress all log files from last week"
# Raw LLM:    find . -type f -mtime +7 -exec gzip {} \;
# Corrected:  find /var/log -name "*.log" -type f -mtime -7 -exec gzip {} \;

# Input: "show files modified in the last 3 days"  
# Raw LLM:    find . -mtime +3
# Corrected:  find . -mtime -3
```

#### Platform-Specific Fixes
```bash
# Input: "list UDP connections" (on macOS)
# Raw LLM:    netstat -anp | grep UDP
# Corrected:  netstat -an | grep -i udp

# Input: "show processes using port 80" (on macOS)
# Raw LLM:    netstat -tulnp | grep :80
# Corrected:  lsof -i :80
```

#### File Type Intelligence
```bash
# Input: "compress log artifacts"
# Raw LLM:    find . -type f -exec gzip {} \;
# Corrected:  find . -name "*.log" -type f -exec gzip {} \;
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
- **Regeneration**: Run `termgpt init --reconfigure` to update

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
- `TERMGPT_DISABLE_POSTPROCESSING`: Set to `1` to disable post-processing (evaluation mode)

## Testing & Evaluation

TermGPT includes a comprehensive evaluation framework that validates performance across different command complexity levels.

### Evaluation Framework

The testing system validates TermGPT's effectiveness through multiple evaluation tiers:

#### Performance Benchmarks (Current Results)
- **Practical Daily Commands**: **95-100%** success rate
- **Complex Multi-step Operations**: 87-93% success rate  
- **Extreme Edge Cases**: 80-85% success rate
- **Overall Performance**: 85-95% depending on command complexity

#### Test Categories
1. **System Monitoring & Performance** (10 commands)
2. **Advanced File Operations** (10 commands)
3. **Network & Security** (10 commands)
4. **Text Processing & Data Analysis** (10 commands)
5. **System Administration & Automation** (10 commands)

### Running Evaluations

#### Quick Performance Check
```bash
cd tests/evaluation
./run_focused_evaluation.sh
```
Tests 10 representative practical commands to validate core functionality.

#### Edge Case Testing  
```bash
cd tests/evaluation
./test_hardest_commands.sh
```
Tests 15 most challenging scenarios to identify performance boundaries.

#### Comprehensive Evaluation
```bash
cd tests/evaluation
./run_comprehensive_evaluation.sh
```
Full 50-command test suite across all categories with detailed analysis.

### Evaluation Architecture

The evaluation system measures:

1. **LLM Baseline Performance**: Raw model output without post-processing
2. **Post-Processing Enhancement**: Full pipeline with intelligent corrections
3. **Command Validation**: Syntax, logic, and safety checks
4. **Success Rate Metrics**: Quantitative performance measurement

#### Key Evaluation Features
- **Automated Testing**: Non-interactive evaluation mode (`--eval` flag)
- **Baseline Comparison**: LLM vs post-processed results
- **Command Extraction**: Robust parsing of generated commands
- **Validation Logic**: Multi-criteria success assessment
- **Performance Tracking**: Historical improvement measurement

### Post-Processing Achievements

The intelligent correction pipeline provides:

#### Complex Command Preservation
- **Problem**: Post-processing can destroy valid multi-step commands
- **Solution**: Preservation logic that detects and protects complex chains
- **Result**: Prevents regressions while enabling improvements

#### Context-Aware Corrections
- **Time Logic**: Semantic understanding of temporal references
- **Platform Awareness**: macOS vs Linux command differences
- **File Pattern Enhancement**: Intelligent filtering based on context
- **Path Optimization**: Better default locations for operations

#### Proven Results
- **67% → 80%** (Original 30-command evaluation)
- **80% → 93%** (15 hardest commands with improvements)
- **90% → 100%** (10 practical commands with enhancements)

### Documentation

Detailed evaluation results and analysis available in:
- `docs/evaluation/` - Comprehensive analysis and results
- `tests/evaluation/README.md` - Test framework documentation  
- `post-processing/docs/ARCHITECTURE.md` - Technical implementation details
