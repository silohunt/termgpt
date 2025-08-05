# TermGPT Homebrew Package

This document describes the Homebrew packaging for TermGPT.

## Quick Installation (Once Published)

```bash
brew tap silohunt/termgpt
brew install termgpt
termgpt init
```

## Package Details

- **Formula Location**: `packaging/homebrew/termgpt.rb`
- **Tap Repository**: `silohunt/homebrew-termgpt` (to be created)
- **Package Name**: `termgpt`
- **Version**: 0.8.0

## Dependencies

- `jq` - JSON processing
- `curl` - HTTP requests  
- `python@3.12` (recommended) - Token counting and explainshell features

## Installation Layout

When installed via Homebrew, TermGPT files are placed as follows:

- **Executables**: `/opt/homebrew/bin/`
  - `termgpt` - Main CLI
  - `termgpt-init` - Setup tool
  - `termgpt-shell` - REPL mode
  - `termgpt-history` - History management

- **Libraries**: `/opt/homebrew/lib/termgpt/`
  - Core libraries and post-processing system
  - Platform detection and token counting

- **Shared Resources**: `/opt/homebrew/share/termgpt/`
  - Safety rules and configuration files

- **Documentation**: 
  - `/opt/homebrew/share/man/man1/termgpt.1`
  - `/opt/homebrew/share/doc/termgpt/`

## Publishing Process

1. **Create Release**: Ensure v0.8.0 tag exists with proper tarball
2. **Create Tap Repository**: `homebrew-termgpt` under silohunt organization
3. **Upload Formula**: Copy `termgpt.rb` and `README.md` to tap repo
4. **Test Installation**: Verify `brew install` works correctly
5. **Update Documentation**: Add Homebrew installation to main README

## Testing

The formula includes tests for:
- Version output (`termgpt --version`)
- Help functionality (`termgpt --help`)
- Subcommand availability (`termgpt-init --help`, `termgpt-shell --help`)

## Caveats

The formula includes post-install instructions for:
- Installing Ollama dependency
- Running initial setup (`termgpt init`)
- Basic usage examples

## Maintenance

To update the formula for new releases:
1. Update `version` and `url` fields
2. Calculate new SHA256: `curl -sL [URL] | shasum -a 256`  
3. Update `sha256` field
4. Test installation
5. Commit to tap repository