# Testing Notes for TermGPT

This document outlines key testing scenarios and known behaviors for TermGPT testers.

## Platform-Specific Command Generation

TermGPT uses post-processing to automatically correct platform-specific command issues. The LLM generates general commands, then a correction layer fixes platform incompatibilities.

### macOS Testing Focus Areas

**Network Commands**:
- `termgpt "list open udp connections"` should generate `netstat -an | grep -i udp` (not `grep UDP`)
- `termgpt "show which process is using port 80"` should use `lsof` not `netstat -p`
- Any `netstat -p` usage should be automatically removed/corrected

**Case Sensitivity**:
- Commands involving UDP/TCP should use case-insensitive search on macOS
- Test both uppercase and lowercase protocol references in requests

**Expected Corrections**:
- `grep UDP` → `grep -i udp`
- `netstat -anp` → `netstat -an`
- `netstat -p | grep` → `lsof -i` (when appropriate)

### Linux Testing Focus Areas

**Network Commands**:
- `netstat -p` should be preserved (supported on Linux)
- Case sensitivity should match Linux netstat output patterns

## Model Performance

**Current Default**: `codellama:7b-instruct`
- Best instruction following and platform awareness
- Generates clean, focused commands
- May need post-processing for platform edge cases

**Alternative Models**:
- `qwen2.5-coder:7b` - Good alternative if available
- `stable-code:3b` - Lightweight option for resource-constrained systems

## Common Test Scenarios

### Network & Process Commands
```bash
termgpt "list open udp connections"
termgpt "show processes using port 22"
termgpt "find which process is listening on port 80"
termgpt "display network connections"
```

### File Operations
```bash
termgpt "find all python files larger than 1MB"
termgpt "list files modified today"
termgpt "show disk usage by directory"
```

### System Information
```bash
termgpt "show system memory usage"
termgpt "display running processes"
termgpt "check disk space"
```

## Expected Behaviors

### Good Signs ✅
- Single, focused commands (no compound `&&` chains)
- No unwanted clipboard operations unless requested
- No URL opening unless requested
- Platform-appropriate flags and syntax
- Commands work without modification

### Red Flags ❌
- Commands with `netstat -p` on macOS
- Case-sensitive `grep UDP` on macOS that returns no results
- Compound commands with clipboard/URL operations not requested
- Commands that fail due to unsupported flags
- Overly complex multi-step commands for simple requests

## Testing Workflow

1. **Generate Command**: Run termgpt with test scenario
2. **Check Generated Command**: Verify it looks appropriate for your platform
3. **Test Execution**: Copy and run the command manually
4. **Verify Results**: Ensure command works and produces expected output
5. **Report Issues**: Note any commands that fail or produce incorrect results

## Known Issues & Workarounds

### macOS Specific
- Some network commands may need `sudo` for full information
- `lsof` commands may require elevated privileges for complete process info
- BSD vs GNU command differences are automatically handled via post-processing

### Performance Notes
- First run may be slower (model loading)
- Subsequent runs should be faster
- GPU systems will have better performance than CPU-only

## Reporting Bugs

When reporting issues, please include:
- Platform (macOS version, Linux distro)
- Exact command used: `termgpt "your request"`
- Generated command output
- Error message or unexpected behavior
- Expected vs actual command behavior

## Post-Processing Debug

If you suspect post-processing issues, check:
1. What the LLM originally generated
2. What the final corrected command became
3. Whether the correction was appropriate for your platform

The post-processing function `apply_platform_corrections()` in `bin/termgpt` handles these corrections automatically.