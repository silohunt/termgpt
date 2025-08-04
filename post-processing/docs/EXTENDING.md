# Extending the Post-Processing System

This guide explains how to add new corrections to the TermGPT post-processing system.

## Quick Start

To add a new correction:

1. Create a correction module in `corrections/`
2. Add unit tests in `tests/`
3. Register in the main library
4. Document your correction

## Step-by-Step Guide

### 1. Create a Correction Module

Create a new file in `corrections/` following the naming pattern:

```sh
# corrections/your-feature.sh
#!/bin/sh
# Your Feature Corrections
# Brief description of what this corrects

apply_your_feature_corrections() {
    local command="$1"
    
    # Your correction logic here
    
    printf '%s' "$command"
}

# Optional: Helper function to check if correction is needed
needs_your_feature_corrections() {
    local command="$1"
    case "$command" in
        *pattern*)
            return 0  # Needs correction
            ;;
        *)
            return 1  # No correction needed
            ;;
    esac
}
```

### 2. Write Unit Tests

Create a test file in `tests/`:

```sh
# tests/test-your-feature.sh
#!/bin/sh

# Source the correction module
. "$(dirname "$0")/../corrections/your-feature.sh"

# Test counter
TESTS=0
PASSED=0

# Test function
test_correction() {
    local description="$1"
    local input="$2"
    local expected="$3"
    local actual
    
    TESTS=$((TESTS + 1))
    actual=$(apply_your_feature_corrections "$input")
    
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ $description"
    else
        echo "✗ $description"
        echo "  Input:    $input"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

echo "Testing your feature corrections..."
echo

# Add your tests here
test_correction "Description of test" \
    "input command" \
    "expected output"

# Summary
echo
echo "Your feature tests: $PASSED/$TESTS passed"
[ "$PASSED" -eq "$TESTS" ] && exit 0 || exit 1
```

### 3. Register in Main Library

Edit `lib/postprocess.sh` to include your module:

```sh
# Source individual correction modules
. "$POSTPROCESS_DIR/corrections/time.sh"
. "$POSTPROCESS_DIR/corrections/files.sh"
. "$POSTPROCESS_DIR/corrections/your-feature.sh"  # Add this line

# Update the main pipeline if needed
apply_all_corrections() {
    local command="$1"
    
    # Existing corrections...
    
    # Add your correction in the appropriate place
    command=$(apply_your_feature_corrections "$command")
    
    printf '%s' "$command"
}
```

### 4. Document Your Correction

Update the main README and architecture docs to mention your correction.

## Types of Corrections

### Simple Pattern Replacement

For straightforward substitutions:

```sh
apply_simple_correction() {
    local command="$1"
    # Replace all occurrences of pattern
    command=$(printf '%s\n' "$command" | sed 's/old_pattern/new_pattern/g')
    printf '%s' "$command"
}
```

### Context-Aware Correction

When context matters:

```sh
apply_context_correction() {
    local command="$1"
    
    # Only apply if certain conditions are met
    if printf '%s' "$command" | grep -q "context_pattern"; then
        command=$(printf '%s\n' "$command" | sed 's/pattern/replacement/g')
    fi
    
    printf '%s' "$command"
}
```

### Complex Logic Correction

For sophisticated transformations:

```sh
apply_complex_correction() {
    local command="$1"
    
    # Extract information
    local value=$(printf '%s' "$command" | sed -n 's/.*pattern:\([^:]*\).*/\1/p')
    
    if [ -n "$value" ]; then
        # Reconstruct command with correction
        command="new_command --option $value"
    fi
    
    printf '%s' "$command"
}
```

## Best Practices

### 1. Use POSIX Shell

Ensure compatibility across all Unix systems:

```sh
# Good: POSIX-compliant
command=$(printf '%s\n' "$command" | sed 's/pattern/replacement/g')

# Bad: Bash-specific
command=${command//pattern/replacement}
```

### 2. Handle Edge Cases

Consider various input formats:

```sh
# Handle different quote styles
command=$(printf '%s\n' "$command" | sed 's/grep "PATTERN"/grep -i pattern/g')
command=$(printf '%s\n' "$command" | sed "s/grep 'PATTERN'/grep -i pattern/g")
command=$(printf '%s\n' "$command" | sed 's/grep PATTERN/grep -i pattern/g')
```

### 3. Preserve Command Structure

Don't break valid commands:

```sh
# Check if correction is actually needed
if needs_correction "$command"; then
    command=$(apply_correction "$command")
fi
```

### 4. Test Thoroughly

Include tests for:
- Basic functionality
- Edge cases
- Commands that shouldn't be modified
- Complex real-world examples

### 5. Document Regex Patterns

Explain complex patterns:

```sh
# Match netstat with -p flag anywhere in the options
# Pattern: netstat -[a-zA-Z]*p[a-zA-Z]*
# Matches: netstat -anp, netstat -tulnp, netstat -p
command=$(printf '%s\n' "$command" | sed 's/netstat -[a-zA-Z]*p[a-zA-Z]*/netstat -an/g')
```

## Common Patterns

### Time-Based Corrections

```sh
# Fix relative time confusion
command=$(printf '%s\n' "$command" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g')
```

### Platform Differences

```sh
# macOS vs Linux
case "$platform" in
    macos)
        command=$(printf '%s\n' "$command" | sed 's/timeout/gtimeout/g')
        ;;
    linux)
        command=$(printf '%s\n' "$command" | sed 's/gtimeout/timeout/g')
        ;;
esac
```

### Path Improvements

```sh
# Use appropriate system paths
command=$(printf '%s\n' "$command" | sed 's|find \. -name "\*.log"|find /var/log -name "*.log"|g')
```

## Testing Your Correction

### Manual Testing

```sh
# Source your module
. corrections/your-feature.sh

# Test individual corrections
result=$(apply_your_feature_corrections "test command")
echo "$result"
```

### Automated Testing

```sh
# Run your specific test
sh tests/test-your-feature.sh

# Run all tests to ensure no regressions
sh tests/run-all.sh
```

### Integration Testing

Test with the full TermGPT pipeline:

```sh
# Test with actual LLM output
./bin/termgpt "your test query"
```

## Debugging Tips

### 1. Add Debug Output

```sh
apply_debug_correction() {
    local command="$1"
    local original="$1"
    
    # Your correction
    command=$(some_correction "$command")
    
    # Debug output
    if [ "$original" != "$command" ]; then
        echo "DEBUG: Corrected '$original' to '$command'" >&2
    fi
    
    printf '%s' "$command"
}
```

### 2. Test Regex Patterns

```sh
# Test sed patterns independently
echo "test command" | sed 's/your_pattern/replacement/g'
```

### 3. Check Order Dependencies

Some corrections may depend on others not having run yet. Test your correction both in isolation and in the full pipeline.

## Contributing Your Correction

1. Ensure all tests pass
2. Document why the correction is needed
3. Provide real-world examples
4. Submit with clear commit message

Example commit message:
```
Add package manager correction module

Fixes package manager commands to use the appropriate tool for each
platform (apt/yum/dnf/pacman/brew). The LLM often generates apt
commands regardless of the actual distribution.

- Detects package operations (install, update, remove)
- Maps to platform-specific package manager
- Preserves command arguments and flags
- Includes tests for major distributions
```