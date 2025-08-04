# Post-Processing Architecture

## Overview

The TermGPT post-processing system transforms raw LLM output into reliable, platform-specific shell commands through a modular correction pipeline. This architecture enables small LLMs (3B-7B parameters) to produce production-quality commands.

## Design Principles

1. **Modularity**: Each correction type is isolated in its own module
2. **Composability**: Corrections can be applied in any combination
3. **Testability**: Each module has comprehensive unit tests
4. **Extensibility**: New corrections can be added without modifying existing code
5. **Performance**: Minimal overhead with efficient pattern matching
6. **Safety**: Security corrections applied first to prevent dangerous commands

## System Components

### Core Library (`lib/postprocess.sh`)

The main entry point that orchestrates all corrections:

```sh
apply_all_corrections() {
    local command="$1"
    local platform="${2:-${TERMGPT_PLATFORM:-unknown}}"
    
    # 1. Security (must be first)
    command=$(apply_security_corrections "$command")
    
    # 2. Semantic corrections
    command=$(apply_time_corrections "$command")
    command=$(apply_file_corrections "$command")
    
    # 3. Platform-specific
    command=$(apply_platform_corrections "$command" "$platform")
    
    printf '%s' "$command"
}
```

### Correction Modules

Each module in `corrections/` handles a specific category:

#### 1. Security Module (`security.sh`)
- Prevents dangerous patterns (rm -rf /, chmod 777)
- Fixes unquoted variables and paths with spaces
- Adds safe defaults for wget/curl operations
- Validates command construction

#### 2. Time Module (`time.sh`)
- Fixes temporal logic errors (-mtime +7 vs -7)
- Handles "last week", "yesterday", "recent" patterns
- Corrects ctime and atime confusion
- Context-aware replacements

#### 3. Files Module (`files.sh`)
- Adds appropriate file filters (*.log for log operations)
- Improves default paths (/var/log vs .)
- Adds version control exclusions for backups
- Fixes missing quotes around wildcards

#### 4. Platform Modules
- **macOS** (`platform-macos.sh`): Handles BSD vs GNU differences
- **Linux** (`platform-linux.sh`): Converts macOS-specific commands

### Test Framework

Unit tests in `tests/` validate each correction:

```sh
test_correction() {
    local description="$1"
    local input="$2"
    local expected="$3"
    local actual=$(apply_corrections "$input")
    
    if [ "$actual" = "$expected" ]; then
        echo "✓ $description"
    else
        echo "✗ $description"
    fi
}
```

## Processing Pipeline

### 1. Command Generation
The LLM generates an initial command based on the natural language request.

### 2. Security Check
Security corrections are applied first to prevent any dangerous operations from reaching later stages.

### 3. Semantic Corrections
Time and file corrections fix common logical errors that small LLMs make.

### 4. Platform Adaptation
Platform-specific corrections ensure commands work on the target OS.

### 5. Output
The fully corrected command is returned to the user for review.

## Pattern Matching Strategy

Corrections use a combination of approaches:

1. **Simple sed replacements**: For straightforward substitutions
2. **Context-aware patterns**: Check surrounding text before replacing
3. **Conditional logic**: Apply corrections only when specific conditions are met
4. **Early returns**: Stop processing when a definitive correction is made

Example of context-aware correction:
```sh
# Only fix time when "last" appears in the command
if printf '%s' "$command" | grep -q "last"; then
    command=$(printf '%s\n' "$command" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g')
fi
```

## Integration with TermGPT

The main script sources the post-processing library:

```sh
# Find and load post-processing library
POSTPROCESS_LIB=$(find_postprocess_lib)
if [ -n "$POSTPROCESS_LIB" ]; then
    . "$POSTPROCESS_LIB"
else
    # Fallback to no corrections
    apply_all_corrections() { printf '%s' "$1"; }
fi

# Apply corrections to LLM output
COMMAND=$(apply_all_corrections "$RAW_COMMAND")
```

## Performance Considerations

1. **Lazy Loading**: Modules are sourced only when needed
2. **Early Returns**: Stop processing when possible
3. **Efficient Patterns**: Use anchored regex where possible
4. **Minimal Processes**: Avoid spawning unnecessary subshells

## Future Enhancements

Potential areas for expansion:

1. **Machine Learning**: Train correction patterns from user feedback
2. **Context Awareness**: Use command history for better corrections
3. **Custom Rules**: User-defined correction patterns
4. **Metrics**: Track which corrections are most frequently applied
5. **Caching**: Remember corrections for similar commands

## Debugging

Enable debugging by modifying the main library:

```sh
# Add debugging output
apply_all_corrections() {
    local command="$1"
    local original="$1"
    
    # ... apply corrections ...
    
    if [ "$original" != "$command" ]; then
        echo "DEBUG: Applied corrections:" >&2
        echo "  Original: $original" >&2
        echo "  Corrected: $command" >&2
    fi
    
    printf '%s' "$command"
}
```

## Best Practices

1. **Order Matters**: Apply security corrections first
2. **Test Coverage**: Every correction needs unit tests
3. **Documentation**: Explain why each correction exists
4. **Portability**: Use POSIX-compliant patterns
5. **Fail Safe**: When in doubt, preserve the original command