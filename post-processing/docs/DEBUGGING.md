# Debugging Post-Processing Issues

A comprehensive guide for troubleshooting and debugging the post-processing system.

## Quick Debugging

### Enable Debug Mode

Add debug output to see what corrections are being applied:

```bash
# Set environment variable
export TERMGPT_DEBUG_POSTPROCESS=1

# Or modify the main library temporarily
apply_all_corrections() {
    local command="$1"
    local original="$1"
    
    echo "DEBUG: Original command: $original" >&2
    
    # Apply each correction with logging
    command=$(apply_security_corrections "$command")
    [ "$original" != "$command" ] && echo "DEBUG: Security correction: $command" >&2
    
    command=$(apply_time_corrections "$command")  
    [ "$original" != "$command" ] && echo "DEBUG: Time correction: $command" >&2
    
    command=$(apply_file_corrections "$command")
    [ "$original" != "$command" ] && echo "DEBUG: File correction: $command" >&2
    
    command=$(apply_platform_corrections "$command")
    [ "$original" != "$command" ] && echo "DEBUG: Platform correction: $command" >&2
    
    echo "DEBUG: Final command: $command" >&2
    printf '%s' "$command"
}
```

### Test Individual Corrections

```bash
# Test specific correction modules
. post-processing/corrections/time.sh
apply_time_corrections "find . -mtime +7"

. post-processing/corrections/platform-macos.sh  
apply_macos_corrections "netstat -anp | grep :80"
```

## Common Issues and Solutions

### Issue 1: Corrections Not Applied

**Symptoms**: Commands that should be corrected remain unchanged

**Debugging Steps**:

1. **Check module loading**:
```bash
# Verify modules are being sourced
ls -la post-processing/corrections/
grep -n "Warning.*not found" ~/.termgpt_debug.log
```

2. **Test pattern matching**:
```bash
# Test if patterns match your input
echo "find . -mtime +7" | grep -q "mtime.*+[0-9]" && echo "Pattern matches"

# Test sed replacement
echo "find . -mtime +7" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g'
```

3. **Check function definitions**:
```bash
# Verify functions are defined
type apply_time_corrections
type apply_platform_corrections
```

**Common Causes**:
- Module files not found (path issues)
- Pattern doesn't match actual input
- Function not properly defined
- Early return preventing correction

### Issue 2: Wrong Corrections Applied

**Symptoms**: Corrections applied when they shouldn't be, or wrong correction

**Debugging Steps**:

1. **Trace correction logic**:
```bash
# Add debug prints to specific correction
apply_time_corrections() {
    local command="$1"
    echo "DEBUG: time input: $command" >&2
    
    # Check each condition
    if printf '%s' "$command" | grep -q "last"; then
        echo "DEBUG: 'last' pattern matched" >&2
        command=$(printf '%s\n' "$command" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g')
        echo "DEBUG: after sed: $command" >&2
    fi
    
    printf '%s' "$command"
}
```

2. **Test regex patterns**:
```bash
# Test individual regex components
echo "find logs from last 5 days -mtime +5" | grep -q "last" && echo "Context match"
echo "find logs from last 5 days -mtime +5" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g'
```

**Common Causes**:
- Overly broad pattern matching
- Regex capturing wrong groups
- Multiple corrections interfering
- Platform detection incorrect

### Issue 3: Performance Problems  

**Symptoms**: Post-processing is slow, command generation takes too long

**Debugging Steps**:

1. **Time individual corrections**:
```bash
time_correction() {
    local start=$(date +%s%N)
    apply_time_corrections "$1" >/dev/null
    local end=$(date +%s%N)
    echo "Time correction: $(( (end - start) / 1000000 ))ms"
}

time_correction "find . -mtime +7"
```

2. **Profile regex patterns**:
```bash
# Test expensive regex patterns
time echo "complex command here" | sed 's/complex-pattern/replacement/g'
```

**Common Causes**:
- Inefficient regex patterns
- Too many separate sed calls
- Complex pattern matching logic
- No early exit optimization

### Issue 4: Platform Detection Issues

**Symptoms**: Wrong platform corrections applied (Linux corrections on macOS, etc.)

**Debugging Steps**:

1. **Check platform detection**:
```bash
echo "Platform: ${TERMGPT_PLATFORM:-unknown}"
cat ~/.config/termgpt/platform.conf | grep TERMGPT_PLATFORM
```

2. **Test platform-specific corrections**:
```bash
TERMGPT_PLATFORM=macos apply_platform_corrections "netstat -anp"
TERMGPT_PLATFORM=linux apply_platform_corrections "pbcopy"
```

**Common Causes**:
- Platform config not loaded
- Environment variable not set
- Platform detection logic incorrect

## Advanced Debugging Techniques

### Correction Pipeline Tracing

Create a detailed trace of the entire correction pipeline:

```bash
trace_corrections() {
    local command="$1"
    local step=0
    
    echo "=== Correction Pipeline Trace ==="
    echo "Input: $command"
    
    # Trace each step
    local result
    result=$(apply_security_corrections "$command")
    step=$((step + 1))
    echo "Step $step (security): $result"
    
    result=$(apply_time_corrections "$result")  
    step=$((step + 1))
    echo "Step $step (time): $result"
    
    result=$(apply_file_corrections "$result")
    step=$((step + 1))
    echo "Step $step (files): $result"
    
    result=$(apply_platform_corrections "$result")
    step=$((step + 1))
    echo "Step $step (platform): $result"
    
    echo "Final: $result"
    echo "================================"
}

# Usage
trace_corrections "find . -mtime +7 -name *.log"
```

### Pattern Testing Harness

Create a test harness for debugging specific patterns:

```bash
#!/bin/sh
# debug-patterns.sh

test_pattern() {
    local pattern="$1"
    local replacement="$2"
    local test_input="$3"
    local expected="$4"
    
    echo "Testing pattern: $pattern"
    echo "Input: $test_input"
    
    local result=$(echo "$test_input" | sed "s/$pattern/$replacement/g")
    echo "Result: $result"
    
    if [ "$result" = "$expected" ]; then
        echo "✓ PASS"
    else
        echo "✗ FAIL (expected: $expected)"
    fi
    echo "---"
}

# Test various patterns
test_pattern '-mtime +\([0-9][0-9]*\)' '-mtime -\1' \
             'find . -mtime +7' 'find . -mtime -7'

test_pattern 'netstat -[a-zA-Z]*p[a-zA-Z]*' 'netstat -an' \
             'netstat -anp | grep :80' 'netstat -an | grep :80'
```

### Integration Testing with LLM

Test the full pipeline with actual LLM integration:

```bash
#!/bin/sh
# debug-integration.sh

debug_full_pipeline() {
    local query="$1"
    
    echo "=== Full Pipeline Debug ==="
    echo "Query: $query"
    
    # Show LLM response before post-processing
    echo "\n--- LLM Raw Output ---"
    # Temporarily disable post-processing
    apply_all_corrections() { printf '%s' "$1"; }
    raw_output=$(echo "q" | ./bin/termgpt "$query" 2>/dev/null | grep "Generated Command:" | cut -d: -f2-)
    echo "Raw: $raw_output"
    
    # Re-enable and show corrected output
    echo "\n--- Post-Processed Output ---"
    unset -f apply_all_corrections
    processed_output=$(echo "q" | ./bin/termgpt "$query" 2>/dev/null | grep "Generated Command:" | cut -d: -f2-)
    echo "Processed: $processed_output"
    
    # Show what changed
    if [ "$raw_output" != "$processed_output" ]; then
        echo "\n--- Changes Applied ---"
        echo "Before: $raw_output"
        echo "After:  $processed_output"
    else
        echo "\n--- No Changes Applied ---"
    fi
    
    echo "=========================="
}

# Test specific queries
debug_full_pipeline "find log files from last week"
debug_full_pipeline "show processes using port 8080"
```

## Common Debugging Patterns

### 1. Correction Not Triggering

```bash
# Check if the input matches your expected pattern
check_pattern_match() {
    local input="$1"
    local pattern="$2"
    
    if printf '%s' "$input" | grep -q "$pattern"; then
        echo "✓ Pattern '$pattern' matches input"
    else
        echo "✗ Pattern '$pattern' does not match input"
        echo "Input: '$input'"
    fi
}

check_pattern_match "find . -mtime +7" "mtime.*+[0-9]"
check_pattern_match "find . -mtime +7" "last"  # Should not match
```

### 2. Sed Pattern Issues

```bash
# Debug sed patterns step by step
debug_sed() {
    local input="$1"
    local pattern="$2"
    local replacement="$3"
    
    echo "Input: $input"
    echo "Pattern: $pattern"
    echo "Replacement: $replacement"
    
    # Test if pattern matches at all
    if echo "$input" | grep -q "$pattern"; then
        echo "✓ Basic pattern matches"
    else
        echo "✗ Basic pattern does not match"
        return 1
    fi
    
    # Test sed substitution
    local result=$(echo "$input" | sed "s/$pattern/$replacement/g")
    echo "Result: $result"
    
    # Show what was captured
    local captured=$(echo "$input" | sed -n "s/$pattern/\1/p")
    echo "Captured: $captured"
}

debug_sed "find . -mtime +7" "-mtime +\([0-9][0-9]*\)" "-mtime -\1"
```

### 3. Function Definition Issues

```bash
# Check if functions are properly defined
check_functions() {
    local functions="apply_time_corrections apply_file_corrections apply_macos_corrections apply_linux_corrections apply_security_corrections"
    
    for func in $functions; do
        if type "$func" >/dev/null 2>&1; then
            echo "✓ $func is defined"
        else
            echo "✗ $func is NOT defined"
        fi
    done
}

check_functions
```

## Error Recovery

### Graceful Degradation

Ensure the system works even when corrections fail:

```bash
apply_safe_correction() {
    local command="$1"
    local original="$command"
    
    # Try correction with error handling
    if command=$(apply_risky_correction "$command" 2>/dev/null); then
        # Verify the result makes sense
        if [ -n "$command" ] && [ "$command" != "null" ]; then
            printf '%s' "$command"
        else
            # Fall back to original
            printf '%s' "$original"
        fi
    else
        # Fall back to original on any error
        printf '%s' "$original"  
    fi
}
```

### Correction Validation

Validate corrections before applying:

```bash
validate_correction() {
    local original="$1"
    local corrected="$2"
    
    # Basic sanity checks
    [ -z "$corrected" ] && return 1
    [ "$corrected" = "null" ] && return 1
    
    # Command structure checks
    case "$corrected" in
        "rm -rf /"*) return 1 ;;  # Dangerous commands
        *"&&"*"rm"*) return 1 ;;  # Suspicious patterns
    esac
    
    # Length check (corrections shouldn't drastically change length)
    local orig_len=${#original}
    local corr_len=${#corrected}
    local ratio=$((corr_len * 100 / orig_len))
    
    # Reject if length changed by more than 300%
    [ $ratio -gt 300 ] && return 1
    
    return 0
}
```

## Performance Debugging

### Bottleneck Identification

```bash
profile_corrections() {
    local command="$1"
    
    local start end duration
    
    # Profile each correction type
    start=$(date +%s%N)
    apply_security_corrections "$command" >/dev/null
    end=$(date +%s%N)
    duration=$(( (end - start) / 1000000 ))
    echo "Security: ${duration}ms"
    
    start=$(date +%s%N)
    apply_time_corrections "$command" >/dev/null
    end=$(date +%s%N)
    duration=$(( (end - start) / 1000000 ))
    echo "Time: ${duration}ms"
    
    # ... repeat for other corrections
}

profile_corrections "find . -mtime +7 -name '*.log' | grep pattern"
```

## Logging and Monitoring

### Structured Logging

```bash
log_correction() {
    local level="$1"
    local module="$2"  
    local original="$3"
    local corrected="$4"
    local reason="$5"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $level [$module] $reason: '$original' -> '$corrected'" >> ~/.termgpt_corrections.log
}

# Usage in corrections
apply_time_corrections() {
    local command="$1"
    local original="$command"
    
    if printf '%s' "$command" | grep -q "last.*-mtime +"; then
        command=$(printf '%s\n' "$command" | sed 's/-mtime +\([0-9][0-9]*\)/-mtime -\1/g')
        log_correction "INFO" "time" "$original" "$command" "fixed_temporal_logic"
    fi
    
    printf '%s' "$command"  
}
```

This comprehensive debugging documentation should help users troubleshoot any issues they encounter with the post-processing system and understand how to extend it effectively.