# TermGPT - Developer Presentation Notes

## What It Is
- Local shell command generator using Ollama + CodeLlama
- POSIX-compliant, runs on macOS/Linux
- No cloud dependencies - everything runs locally

## Core Features

### 1. Natural Language → Shell Commands
```bash
termgpt "find all python files modified today"
# Generates: find . -name "*.py" -mtime 0
```

### 2. Built-in Safety Validation
- 109 regex patterns for dangerous commands
- Multi-level severity (CRITICAL/HIGH/MEDIUM/LOW)
- Warns before showing risky commands

### 3. Platform Awareness
- Detects macOS vs Linux automatically
- Uses appropriate tools (pbcopy vs xclip, etc.)
- Generates OS-optimized commands

### 4. History Logging (Key for LLM Training)
- Every interaction logged in JSONL format
- Captures: prompt → command → user action → platform context
- Privacy controls (can disable/clear)

## Why It's Useful Now

### For Daily Work
- Faster than context-switching to ChatGPT/Claude
- No need to remember exact syntax
- Safe exploration of complex commands
- Stays in terminal workflow

### For Learning Patterns
- See what commands colleagues actually need
- Identify common tasks across team
- Discover knowledge gaps

## LLM Fine-Tuning Potential

### Data Collection Built-In
```json
{
  "conversation": [
    {"role": "user", "content": "compress all logs from last week"},
    {"role": "assistant", "content": "find . -name '*.log' -mtime -7 | tar -czf logs_last_week.tar.gz -T -"}
  ],
  "platform": "macos",
  "user_action": "copied"
}
```

### What Makes This Data Valuable
1. **Real-world usage** - Not synthetic/generated
2. **Platform context** - OS-specific optimizations
3. **User validation** - Shows which commands were actually used
4. **Safety labels** - Teaches risk assessment

### Future Applications
- Train specialized models for your tech stack
- Build company-specific command generators
- Create domain-specific assistants (DevOps, Security, Data)
- Improve onboarding with common task patterns

## Live Demo Commands (Tested & Ready)

### 1. Safety Detection (Shows CRITICAL Warning)
```bash
termgpt "delete all temporary files"
# Generates: rm -rf /tmp/*
# Shows: "CRITICAL: Dangerous command matched pattern"
```

### 2. Platform Awareness (macOS clipboard)
```bash
termgpt "copy all my shell scripts to clipboard" 
# Generates: pbcopy < ~/.bashrc
# Uses platform-specific pbcopy command
```

### 3. Complex File Operations
```bash
termgpt "find all python files larger than 1MB"
# Generates: find . -type f -name '*.py' -size +1M

termgpt "find files modified in the last 2 hours" 
# Generates: find . -type f -mmin -120
```

### 4. System Administration
```bash
termgpt "show me disk usage sorted by size"
# Generates: du -hs /* | sort -hr

termgpt "compress all log files from this week"
# Generates: find /var/log -type f -mtime +7 -exec gzip {} \;
```

### 5. Show Training Data Export
```bash
termgpt-history export demo-data.jsonl
# Shows the conversation data being collected for fine-tuning
```

**Demo Flow**: Start with simple commands, show safety detection, then demonstrate the export feature to tie back to LLM training value.

## Implementation Details
- 100% POSIX shell (no bash/zsh dependencies)
- ~500 lines of code total
- No external dependencies except Ollama
- MIT licensed

### How Simple Local LLM Integration Actually Is
**The entire LLM interaction is just 3 lines:**
```bash
JSON=$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false}')
curl -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" -d "$JSON"
```

**That's it.** No API keys, no SDKs, no auth - just HTTP POST to localhost.

- Any shell script can become AI-powered in minutes
- No vendor lock-in, rate limits, or internet dependency  
- The real engineering is in safety, UX, and prompt design - not LLM integration

## Testing & Quality
- Comprehensive test suite (109 safety patterns validated)
- Docker-based testing (Alpine Linux minimal environment)
- Automated test runner (`./test/test-in-container.sh`)
- Tests POSIX compliance, safety rules, installation/uninstall
- Complete uninstaller for clean removal
- Cross-platform validation (macOS/Linux)

## Getting Started

**Repository**: https://github.com/silohunt/termgpt

```bash
git clone https://github.com/silohunt/termgpt.git
cd termgpt
./setup.sh  # Installs ALL dependencies automatically
```

### What setup.sh handles:
- Detects platform (macOS/Linux)
- Installs jq if missing
- Installs Ollama if needed
- Downloads CodeLlama model (~4GB)
- Creates config directories
- No manual dependency hunting

### Installation Options
```bash
# Development (run from project)
./bin/termgpt "command"

# User install (no sudo)
make install-user

# System-wide
sudo make install
```

## Contributing & Feedback

I'd love your feedback and contributions! 

- **Additional safety patterns** - Help identify more dangerous command patterns
- **Platform-specific optimizations** - Windows support, more Linux distros
- **Use case insights** - What commands do you look up most often?
- **Fine-tuning ideas** - Domain-specific models (DevOps, Security, Data Science)

**How to contribute:**
- Open issues for bugs, feature requests, or safety patterns
- Submit PRs following the CONTRIBUTING.md guidelines
- Share your usage patterns and command history exports
- Test on different platforms and report compatibility issues

**Repository**: https://github.com/silohunt/termgpt

## Discussion Points
- What commands do you look up most often?
- Would team-specific fine-tuning be valuable?
- Privacy concerns with command logging?
- Integration ideas with existing tools?