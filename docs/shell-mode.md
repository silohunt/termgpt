# TermGPT Shell Mode (REPL)

TermGPT Shell Mode provides an interactive REPL (Read-Eval-Print Loop) interface for iterative command development and exploration.

## Quick Start

```bash
# Start interactive shell
termgpt shell

# Start with specific model
termgpt shell --model codellama:13b

# Start with history displayed
termgpt shell --history
```

## Usage Example

```
$ termgpt shell
TermGPT v0.8.0 (codellama:7b-instruct) - Interactive Mode
Type .help for commands, .quit to exit

termgpt> find large files
Generated: find . -type f -size +100M

Use: .copy  .explain  .run  .save  .help

termgpt> .copy
✓ Copied to clipboard

termgpt> compress those files
Generated: find . -type f -size +100M -exec gzip {} \;

termgpt> .save compress-large
✓ Saved alias 'compress-large'

termgpt> .history
Recent commands (last 10):
1. find . -type f -size +100M (copied)
2. find . -type f -size +100M -exec gzip {} \; (saved as compress-large)

termgpt> .quit
✓ Session saved
```

## Command Categories

### Generation Commands
- **Natural language input**: Type any natural language request to generate shell commands
- All existing TermGPT features work: post-processing, safety validation, platform awareness

### Dot Commands (REPL Control)

| Command | Description |
|---------|-------------|
| `.help`, `.h` | Show available commands |
| `.quit`, `.exit`, `.q` | Exit the REPL |
| `.clear`, `.cl` | Clear screen |
| `.history [n]` | Show last n commands (default 10) |
| `.model [name]` | Show current model or switch model |
| `.config` | Show current configuration |
| `.stats` | Show session statistics |
| `.aliases` | List saved command aliases |
| `.debug [on/off]` | Toggle debug mode |
| `.export [file]` | Export session to file |

### Action Commands (For Last Generated Command)

| Command | Description |
|---------|-------------|
| `.copy` | Copy command to clipboard |
| `.explain` | Open command explanation in browser |
| `.run` | Execute command (with confirmation) |
| `.save [name]` | Save command as alias |

## Features

### Session Management
- **Persistent Sessions**: Each shell session is saved with unique ID
- **Command History**: Track all generated commands and actions taken
- **Session Export**: Export session data for analysis or sharing
- **Cross-Session History**: Access history from previous sessions

### Alias System
- **Save Commands**: Save frequently used commands with custom names
- **Persistent Storage**: Aliases are saved between sessions
- **Easy Access**: List and manage saved aliases

### Integration
- **TermGPT History**: Integrates with main TermGPT history system
- **Post-Processing**: All post-processing corrections apply
- **Safety Validation**: Same safety checks as single-command mode
- **Platform Awareness**: Inherits platform-specific configurations

## Configuration

### Environment Variables
- `TERMGPT_MODEL`: Override default model
- `TERMGPT_HISTORY`: Enable/disable history logging
- `TERMGPT_HISTORY_FILE`: Custom history file location

### Files
- **Sessions**: `~/.config/termgpt/sessions/session-*.json`
- **Aliases**: `~/.config/termgpt/aliases.conf`
- **History**: `~/.config/termgpt/history.jsonl` (shared with main TermGPT)

## Advanced Usage

### Command Chaining
```
termgpt> find python files
Generated: find . -name "*.py" -type f

termgpt> .copy
✓ Copied to clipboard

termgpt> count lines in those files
Generated: find . -name "*.py" -type f -exec wc -l {} +

termgpt> .run
Preview: find . -name "*.py" -type f -exec wc -l {} +
Continue? [y/N] y
Running command...
```

### Session Export
```
termgpt> .export my-session.json
✓ Session exported to: my-session.json

termgpt> .stats
Session Statistics:
  Session ID: 1725456789-12345
  Started: 2025-01-01T12:00:00Z
  Commands generated: 5
  Actions taken:
      3 copied
      1 saved as alias
      1 executed
```

## Benefits

1. **Iterative Development**: Build complex workflows step by step
2. **Context Preservation**: Commands remember what you were working on
3. **Learning Tool**: History shows command evolution
4. **Productivity**: Quick access to frequently used patterns
5. **Safety**: Same validation as single-command mode with confirmation prompts

## Keyboard Shortcuts

- **Ctrl+C**: Exit gracefully (saves session)
- **Ctrl+D**: Exit gracefully (saves session)
- **Tab**: (Future: Command completion)
- **Arrow Keys**: (Future: Command history navigation)