# TermGPT Post-Processing System

## Overview

The post-processing system transforms raw LLM output into reliable, platform-specific shell commands. This modular architecture allows small LLMs to produce high-quality results by fixing common mistakes and platform incompatibilities.

## Why Post-Processing?

Small LLMs (3B-7B parameters) often struggle with:
- Platform-specific command variations (macOS vs Linux)
- Semantic understanding (time directions, file patterns)
- Command syntax consistency
- Edge cases and special scenarios

Post-processing bridges this gap, making small models viable for production use.

## Architecture

```
post-processing/
├── corrections/           # Individual correction modules
│   ├── time.sh           # Time semantic corrections
│   ├── files.sh          # File pattern improvements
│   ├── platform-macos.sh # macOS-specific fixes
│   ├── platform-linux.sh # Linux-specific fixes
│   └── security.sh       # Security hardening
├── tests/                # Unit tests for each module
│   ├── test-time.sh
│   ├── test-files.sh
│   └── test-platform.sh
├── docs/                 # Documentation
│   ├── ARCHITECTURE.md   # System design
│   ├── EXTENDING.md      # How to add corrections
│   └── EXAMPLES.md       # Real-world examples
└── lib/
    └── postprocess.sh    # Main post-processing library

```

## Quick Start

### Using Post-Processing

```bash
# Source the main library
. post-processing/lib/postprocess.sh

# Apply all corrections
corrected=$(apply_all_corrections "$raw_command")

# Apply specific corrections
corrected=$(apply_time_corrections "$raw_command")
corrected=$(apply_platform_corrections "$corrected" "macos")
```

### Adding New Corrections

1. Create a new module in `corrections/`
2. Add unit tests in `tests/`
3. Register in the main pipeline
4. Document the correction

See [EXTENDING.md](docs/EXTENDING.md) for detailed instructions.

## Correction Categories

### 1. Time Semantics
Fixes temporal logic confusion in find commands.
- `"last week"` → `-mtime -7` (not `+7`)
- `"older than 30 days"` → `-mtime +30`
- `"from yesterday"` → `-mtime -1`

### 2. File Patterns
Adds intelligent file filters based on context.
- Log compression → adds `*.log` filter
- Backup operations → excludes `.git`, `.svn`
- Archive creation → smart defaults

### 3. Platform Compatibility
Handles OS-specific command variations.
- macOS: `netstat -p` → `lsof`
- macOS: Case-insensitive grep for system output
- Linux: Preserves GNU-specific options

### 4. Path Optimization
Improves default paths and locations.
- Log operations → `/var/log` instead of `.`
- System files → appropriate system directories
- User files → home directory awareness

### 5. Security Hardening
Prevents common security issues.
- Quote handling for spaces in paths
- Injection prevention
- Safe command construction

## Examples

### Before and After

**Time Confusion**
```bash
# LLM Output:  find . -mtime +7 -name "*.log"
# Corrected:   find /var/log -mtime -7 -name "*.log"
```

**Platform Issues**
```bash
# LLM Output:  netstat -anp | grep :80
# Corrected:   lsof -i :80  # on macOS
```

**Missing Filters**
```bash
# LLM Output:  find . -type f -exec gzip {} \;
# Corrected:   find . -name "*.log" -type f -exec gzip {} \;
```

## Testing

Run all post-processing tests:
```bash
./post-processing/tests/run-all.sh
```

Run specific test suite:
```bash
./post-processing/tests/test-time.sh
./post-processing/tests/test-platform.sh
```

## Documentation

- **[QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** - Common tasks and patterns ⚡
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and components
- **[EXTENDING.md](docs/EXTENDING.md)** - How to add new corrections
- **[FINE-TUNING.md](docs/FINE-TUNING.md)** - Data-driven optimization and improvement
- **[DEBUGGING.md](docs/DEBUGGING.md)** - Troubleshooting and debugging guide
- **[EXAMPLES.md](docs/EXAMPLES.md)** - Real-world correction examples

## Contributing

The post-processing system is designed for extensibility. Common patterns that could benefit from correction:
- Package manager variations (apt/yum/brew)
- Service management (systemctl/service/launchctl)
- Path separators and quoting
- Common typos and abbreviations

See [EXTENDING.md](docs/EXTENDING.md) for contribution guidelines and [FINE-TUNING.md](docs/FINE-TUNING.md) for data-driven improvement strategies.

## Philosophy

Post-processing enables a "best of both worlds" approach:
- **Small LLMs**: Fast, private, resource-efficient
- **Smart corrections**: Production-quality output
- **Modular design**: Easy to maintain and extend
- **Platform-aware**: Works everywhere

This approach makes local LLMs practical for real-world command generation.