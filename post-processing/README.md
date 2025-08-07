# TermGPT Post-Processing System

## Overview

Post-processing fixes platform compatibility issues and common command generation problems. The system uses separate modules for different platforms and correction types.

## Architecture

```
post-processing/
├── lib/
│   └── postprocess.sh          # Main coordination logic
└── corrections/
    ├── common.sh               # Platform-agnostic fixes
    ├── platform-macos.sh       # macOS-specific corrections
    └── platform-linux.sh       # Linux-specific corrections
```

## Design

- Essential corrections only
- Platform compatibility fixes
- Modular structure for contributions
- Graceful degradation if modules are missing

## Adding Corrections

### macOS Corrections (`platform-macos.sh`)
Common fixes:
- Remove unsupported `netstat -p` flag → `netstat -an`
- Fix case sensitivity: `grep UDP` → `grep -i udp`
- Use `lsof` instead of `netstat -p` combinations

### Linux Corrections (`platform-linux.sh`)
Potential additions:
- Package manager differences (`apt` vs `yum` vs `pacman`)
- GNU-specific flags that don't work on BSD systems

### Common Corrections (`common.sh`)
Cross-platform fixes:
- Time logic: `find -mtime +7` → `find -mtime -7` for "last week"
- Add `.log` extension for compression commands targeting log files

## Contributing

1. Identify the issue: Does the LLM generate incorrect commands for your platform?
2. Choose the right module: Platform-specific or common correction?
3. Keep it simple: Focus on compatibility, not semantic changes
4. Test the fix works and doesn't break other cases

## Testing

The system maintains the same `apply_platform_corrections()` interface, so existing tests work without modification.