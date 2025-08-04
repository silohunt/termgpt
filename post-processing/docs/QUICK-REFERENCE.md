# Post-Processing Quick Reference

Common tasks and patterns for extending and fine-tuning the post-processing system.

## Quick Tasks

### Add a Simple Pattern Correction

```bash
# 1. Edit the appropriate correction module
vim post-processing/corrections/time.sh  # or files.sh, platform-macos.sh, etc.

# 2. Add your pattern
command=$(printf '%s\n' "$command" | sed 's/old_pattern/new_pattern/g')

# 3. Add a test
vim post-processing/tests/test-time.sh

test_correction "Your test description" \
    "input command" \
    "expected output"

# 4. Run tests
sh post-processing/tests/run-all.sh
```

### Debug a Correction Issue

```bash
# Enable debug mode
export TERMGPT_DEBUG_POSTPROCESS=1

# Test specific correction
. post-processing/corrections/time.sh
apply_time_corrections "your test command"

# Test full pipeline
echo "q" | ./bin/termgpt "your query" 2>&1 | grep DEBUG
```

### Add Platform-Specific Correction

```bash
# For macOS corrections
vim post-processing/corrections/platform-macos.sh

# Add pattern like:
command=$(printf '%s\n' "$command" | sed 's/linux_command/macos_command/g')

# For Linux corrections  
vim post-processing/corrections/platform-linux.sh

# Add pattern like:
command=$(printf '%s\n' "$command" | sed 's/macos_command/linux_command/g')
```

### Monitor Correction Usage

```bash
# Add logging to library
vim post-processing/lib/postprocess.sh

# Add after each correction:
[ "$original" != "$command" ] && echo "$(date): correction_type: $original -> $command" >> ~/.termgpt_corrections.log

# Analyze logs
tail -f ~/.termgpt_corrections.log
grep "time:" ~/.termgpt_corrections.log | head -10
```

## Common Patterns

### Time-Based Corrections

```bash
# Fix "last X days" pattern
if printf '%s' "$command" | grep -q "last.*days"; then
    command=$(printf '%s\n' "$command" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g')
fi

# Fix specific time values
command=$(printf '%s\n' "$command" | sed 's/-mtime +7/-mtime -7/g')  # last week
command=$(printf '%s\n' "$command" | sed 's/-mtime +30/-mtime -30/g') # last month
```

### File Pattern Corrections

```bash
# Add file extension filter
if printf '%s' "$command" | grep -q 'find.*-type f' && ! printf '%s' "$command" | grep -q '\.log'; then
    case "$command" in
        *compress*|*gzip*|*tar*)
            command=$(printf '%s\n' "$command" | sed 's/find \([^ ]*\) -type f/find \1 -name "*.log" -type f/')
            ;;
    esac
fi

# Fix path defaults
command=$(printf '%s\n' "$command" | sed 's|find \. -name "\*.log"|find /var/log -name "*.log"|g')
```

### Platform Command Replacements

```bash
# macOS replacements
command=$(printf '%s\n' "$command" | sed 's/netstat -[a-zA-Z]*p[a-zA-Z]*/netstat -an/g')
command=$(printf '%s\n' "$command" | sed 's/grep UDP/grep -i udp/g')

# Linux replacements  
command=$(printf '%s\n' "$command" | sed 's/| pbcopy/| xclip -selection clipboard/g')
command=$(printf '%s\n' "$command" | sed 's/open /xdg-open /g')
```

### Context-Aware Corrections

```bash
# Apply correction only in specific contexts
case "$command" in
    *"backup"*"config"*)
        command=$(printf '%s\n' "$command" | sed 's/find \./find . -not -path "*\/.git\/*"/g')
        ;;
    *"log"*"compress"*)
        command=$(printf '%s\n' "$command" | sed 's/find \./find \/var\/log/g')
        ;;
esac
```

## Testing Patterns

### Basic Test Template

```bash
test_correction "Description" \
    "input command" \
    "expected output"
```

### Edge Case Testing

```bash
# Test that valid commands aren't changed
test_correction "Don't change valid mtime" \
    "find . -mtime -7" \
    "find . -mtime -7"

# Test complex cases
test_correction "Handle complex find" \
    "find . -type f -mtime +7 -size +100M -exec gzip {} \;" \
    "find . -type f -mtime -7 -size +100M -exec gzip {} \;"
```

### Platform-Specific Tests

```bash
# macOS-specific test
test_macos_correction "Fix netstat on macOS" \
    "netstat -anp | grep :80" \
    "lsof -i :80"

# Linux-specific test  
test_linux_correction "Fix clipboard on Linux" \
    "echo 'test' | pbcopy" \
    "echo 'test' | xclip -selection clipboard"
```

## Debugging Patterns

### Pattern Matching Debug

```bash
# Check if pattern matches
echo "your command" | grep -q "your_pattern" && echo "matches" || echo "no match"

# Test sed replacement
echo "your command" | sed 's/old_pattern/new_pattern/g'

# Debug regex capture groups
echo "find . -mtime +7" | sed -n 's/-mtime +\([0-9][0-9]*\)/captured: \1/p'
```

### Function Testing

```bash
# Test individual correction function
. post-processing/corrections/time.sh
result=$(apply_time_corrections "find . -mtime +7")
echo "Result: $result"

# Test full pipeline
result=$(apply_all_corrections "find . -mtime +7")
echo "Final: $result"
```

### Performance Testing

```bash
# Time a correction
time apply_time_corrections "find . -mtime +7" >/dev/null

# Profile multiple corrections
for i in $(seq 1 100); do
    apply_time_corrections "find . -mtime +7" >/dev/null
done
```

## File Locations

```
post-processing/
├── lib/postprocess.sh          # Main orchestration
├── corrections/
│   ├── time.sh                # Time logic fixes
│   ├── files.sh               # File pattern improvements  
│   ├── platform-macos.sh      # macOS-specific fixes
│   ├── platform-linux.sh      # Linux-specific fixes
│   └── security.sh            # Security hardening
├── tests/
│   ├── run-all.sh             # Run all tests
│   ├── test-time.sh           # Time correction tests
│   └── test-platform.sh       # Platform correction tests
└── docs/
    ├── ARCHITECTURE.md         # System design
    ├── EXTENDING.md            # How to extend
    ├── FINE-TUNING.md          # Optimization guide
    ├── DEBUGGING.md            # Troubleshooting
    └── EXAMPLES.md             # Real examples
```

## Integration Points

### Main Script Integration

```bash
# bin/termgpt sources the library like this:
POSTPROCESS_LIB=$(find_postprocess_lib)
POSTPROCESS_LIB_PATH="$POSTPROCESS_LIB"
export POSTPROCESS_LIB_PATH
. "$POSTPROCESS_LIB"

# Then applies corrections:
COMMAND=$(apply_all_corrections "$RAW_COMMAND")
```

### Adding New Correction Types

```bash
# 1. Create new correction module
vim post-processing/corrections/new-type.sh

# 2. Add to main library
vim post-processing/lib/postprocess.sh
# Add: . "$POSTPROCESS_DIR/corrections/new-type.sh"

# 3. Update pipeline
apply_all_corrections() {
    # ... existing corrections ...
    command=$(apply_new_type_corrections "$command")
    printf '%s' "$command"
}
```

## Common Regex Patterns

```bash
# Time patterns
's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g'   # Fix time direction
's/-mtime +7/-mtime -7/g'                   # Specific week fix

# File patterns  
's/find \([^ ]*\) -type f/find \1 -name "*.log" -type f/'  # Add log filter
's|find \. |find /var/log |g'               # Fix log path

# Platform patterns
's/netstat -[a-zA-Z]*p[a-zA-Z]*/netstat -an/g'  # Remove -p flag
's/grep UDP/grep -i udp/g'                      # Case insensitive
's/| pbcopy/| xclip -selection clipboard/g'     # Linux clipboard

# Security patterns
's/chmod 777/chmod 755/g'                       # Fix permissions
's|rm -rf /[[:space:]]*$|rm -rf /dev/null|g'   # Prevent disaster
```

This quick reference should help users quickly find and implement common post-processing patterns without having to dig through the full documentation.