# TermGPT Homebrew Tap

This is the official Homebrew tap for TermGPT - a platform-aware shell tool that converts natural language to Unix commands using local LLM.

## Installation

```bash
brew tap silohunt/termgpt
brew install termgpt
```

## Getting Started

After installation, you'll need to set up Ollama and initialize TermGPT:

```bash
# Install Ollama (if not already installed)
brew install ollama

# Start Ollama service
brew services start ollama
# OR run manually: ollama serve

# Initialize TermGPT
termgpt init

# Start using TermGPT
termgpt "find all python files larger than 1MB"
termgpt shell  # Interactive REPL mode
```

## What's Included

- `termgpt` - Main command-line interface
- `termgpt-init` - Setup and configuration tool
- `termgpt-shell` - Interactive REPL mode
- `termgpt-history` - Command history management

## Requirements

- macOS 10.15+ or Linux
- Ollama (for local LLM inference)
- 4-6GB RAM (depending on model choice)

## Documentation

- `man termgpt` - Manual page
- [GitHub Repository](https://github.com/silohunt/termgpt)
- [Technical Documentation](https://github.com/silohunt/termgpt/blob/main/doc/README.md)

## Support

If you encounter issues:
1. Check `termgpt --help`
2. Run `termgpt init --check` to verify installation
3. [Open an issue](https://github.com/silohunt/termgpt/issues) on GitHub