# Fine-Tuning the Post-Processing System

This guide covers how to fine-tune, debug, and optimize the post-processing system based on real-world usage patterns.

## Understanding Correction Patterns

### Analyzing LLM Output Patterns

Before adding corrections, analyze what patterns your LLM consistently gets wrong:

```bash
# Enable debug mode to see before/after corrections
export TERMGPT_DEBUG_POSTPROCESS=1

# Run commands and collect patterns
./bin/termgpt "find files from last week" 2>&1 | grep "DEBUG:"
./bin/termgpt "show network connections" 2>&1 | grep "DEBUG:"
```

### Common Pattern Categories

1. **Temporal Logic**: Time direction confusion (`+7` vs `-7`)
2. **Platform Commands**: Linux commands on macOS, vice versa
3. **Path Defaults**: Generic paths vs specific system paths
4. **Case Sensitivity**: System output case matching
5. **Flag Compatibility**: GNU vs BSD tool differences

## Data-Driven Fine-Tuning

### 1. Collect Usage Data

Track what corrections are most frequently applied:

```bash
# Add to post-processing library for metrics
apply_all_corrections() {
    local command="$1"
    local original="$1"
    
    # Apply corrections and track which ones fire
    for correction_type in security time files platform; do
        local corrected=$(apply_${correction_type}_corrections "$command")
        if [ "$command" != "$corrected" ]; then
            echo "$(date): $correction_type: $command -> $corrected" >> ~/.termgpt_corrections.log
        fi
        command="$corrected"
    done
    
    printf '%s' "$command"
}
```

### 2. Analyze Correction Frequency

```bash
# Most common corrections
cat ~/.termgpt_corrections.log | cut -d: -f2 | sort | uniq -c | sort -nr

# Time-based analysis
grep "time:" ~/.termgpt_corrections.log | head -10

# Platform-specific issues
grep "platform:" ~/.termgpt_corrections.log | head -10
```

### 3. Identify Missing Patterns

Look for commands that fail after post-processing:

```bash
# Track failed commands (add to termgpt main script)
if ! "$COMMAND" --help >/dev/null 2>&1; then
    echo "$(date): FAILED: $COMMAND" >> ~/.termgpt_failures.log
fi
```

## Iterative Improvement Process

### Phase 1: Pattern Discovery

1. **Deploy with logging**: Enable correction tracking
2. **Collect data**: Run for 1-2 weeks with real usage
3. **Analyze patterns**: Find most common issues
4. **Prioritize**: Focus on high-frequency problems

### Phase 2: Correction Development

1. **Write tests first**: Create failing tests for new patterns
2. **Implement corrections**: Add to appropriate modules
3. **Test thoroughly**: Ensure no regressions
4. **Deploy incrementally**: Test with subset of users

### Phase 3: Validation

1. **A/B testing**: Compare with/without new corrections
2. **Success metrics**: Track command success rates
3. **User feedback**: Monitor reported issues
4. **Performance impact**: Measure correction overhead

## Advanced Correction Techniques

### Context-Aware Corrections

Use surrounding text to make better decisions:

```bash
apply_smart_path_correction() {
    local command="$1"
    
    # Different corrections based on context
    case "$command" in
        *"backup"*"config"*)
            # Backup operations should exclude temp files
            command=$(echo "$command" | sed 's/find \./find . -not -path "*\/tmp\/*"/g')
            ;;
        *"log"*"compress"*)
            # Log compression should target /var/log
            command=$(echo "$command" | sed 's/find \./find \/var\/log/g')
            ;;
        *"find"*"user"*"files"*)
            # User file operations should start from home
            command=$(echo "$command" | sed 's/find \./find ~\//g')
            ;;
    esac
    
    printf '%s' "$command"
}
```

### Multi-Step Corrections

Handle complex transformations:

```bash
apply_package_manager_correction() {
    local command="$1"
    local platform="${TERMGPT_PLATFORM:-unknown}"
    
    # Extract package name and operation
    local operation=""
    local package=""
    
    case "$command" in
        *"apt install"*)
            operation="install"
            package=$(echo "$command" | sed -n 's/.*apt install \([^ ]*\).*/\1/p')
            ;;
        *"apt update"*)
            operation="update"
            ;;
        *"apt search"*)
            operation="search"
            package=$(echo "$command" | sed -n 's/.*apt search \([^ ]*\).*/\1/p')
            ;;
    esac
    
    if [ -n "$operation" ]; then
        case "$platform" in
            macos)
                case "$operation" in
                    install) command="brew install $package" ;;
                    update) command="brew update && brew upgrade" ;;
                    search) command="brew search $package" ;;
                esac
                ;;
            # Add other platforms as needed
        esac
    fi
    
    printf '%s' "$command"
}
```

### Confidence-Based Corrections

Only apply corrections when confident:

```bash
apply_confident_correction() {
    local command="$1"
    local confidence=0
    
    # Calculate confidence based on multiple signals
    case "$command" in
        *"find"*"-mtime +"*"last"*) confidence=$((confidence + 80)) ;;
        *"netstat"*"-p"*) 
            if [ "$TERMGPT_PLATFORM" = "macos" ]; then
                confidence=$((confidence + 90))
            fi
            ;;
    esac
    
    # Only apply if confidence > threshold
    if [ $confidence -gt 70 ]; then
        # Apply correction
        command=$(do_correction "$command")
    fi
    
    printf '%s' "$command"
}
```

## Performance Optimization

### Efficient Pattern Matching

Optimize regex patterns for speed:

```bash
# Slow: Multiple sed calls
command=$(echo "$command" | sed 's/pattern1/replacement1/g')
command=$(echo "$command" | sed 's/pattern2/replacement2/g')
command=$(echo "$command" | sed 's/pattern3/replacement3/g')

# Fast: Single sed call with multiple patterns
command=$(echo "$command" | sed -e 's/pattern1/replacement1/g' \
                                -e 's/pattern2/replacement2/g' \
                                -e 's/pattern3/replacement3/g')
```

### Early Exit Optimization

Skip unnecessary processing:

```bash
apply_time_corrections() {
    local command="$1"
    
    # Quick check - skip if no time-related content
    case "$command" in
        *"mtime"*|*"ctime"*|*"atime"*|*"last"*|*"recent"*) ;;
        *) printf '%s' "$command"; return ;;
    esac
    
    # Apply time corrections only if needed
    # ... correction logic ...
}
```

### Caching Results

Cache expensive pattern matching:

```bash
# Global cache
_correction_cache=""

apply_cached_correction() {
    local command="$1"
    local cache_key=$(echo "$command" | sha256sum | cut -d' ' -f1)
    
    # Check cache
    local cached=$(echo "$_correction_cache" | grep "^$cache_key:" | cut -d: -f2-)
    if [ -n "$cached" ]; then
        printf '%s' "$cached"
        return
    fi
    
    # Apply correction and cache result
    local result=$(do_expensive_correction "$command")
    _correction_cache="$_correction_cache\n$cache_key:$result"
    
    printf '%s' "$result"
}
```

## Testing and Validation

### Regression Testing

Maintain a comprehensive test suite:

```bash
# tests/regression-suite.sh
#!/bin/sh

# Test known good corrections
test_regression() {
    local input="$1"
    local expected="$2"
    local description="$3"
    
    local actual=$(apply_all_corrections "$input")
    
    if [ "$actual" = "$expected" ]; then
        echo "✓ $description"
    else
        echo "✗ REGRESSION: $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

# Add all previously working corrections
test_regression "find . -mtime +7" "find . -mtime -7" "Time direction fix"
test_regression "netstat -anp" "lsof -i :" "macOS netstat correction"
# ... more tests
```

### Integration Testing

Test with real LLM output:

```bash
# tests/integration-test.sh
#!/bin/sh

test_queries=(
    "find log files from yesterday"
    "show network connections" 
    "compress old files"
    "backup config files"
)

for query in "${test_queries[@]}"; do
    echo "Testing: $query"
    result=$(echo "q" | ./bin/termgpt "$query" | grep "Generated Command:")
    echo "Result: $result"
    echo "---"
done
```

### A/B Testing Framework

Compare correction effectiveness:

```bash
# Enable A/B testing mode
export TERMGPT_AB_TEST=true
export TERMGPT_AB_GROUP="control"  # or "experimental"

# In post-processing library
apply_all_corrections() {
    local command="$1"
    
    case "${TERMGPT_AB_GROUP:-control}" in
        control)
            # Apply standard corrections
            command=$(apply_standard_corrections "$command")
            ;;
        experimental)
            # Apply new experimental corrections
            command=$(apply_experimental_corrections "$command")
            ;;
    esac
    
    # Log for analysis
    echo "$(date),${TERMGPT_AB_GROUP:-control},$1,$command" >> ~/.termgpt_ab_test.log
    
    printf '%s' "$command"
}
```

## Monitoring and Metrics

### Key Metrics to Track

1. **Correction Rate**: % of commands that needed correction
2. **Success Rate**: % of corrected commands that work
3. **Performance**: Correction processing time
4. **User Satisfaction**: Commands accepted vs dismissed

### Monitoring Script

```bash
#!/bin/sh
# monitoring/analyze-corrections.sh

LOG_FILE="$HOME/.termgpt_corrections.log"

echo "Post-Processing Analytics"
echo "========================"

echo "\nCorrection Frequency:"
grep -o "^[^:]*:" "$LOG_FILE" | sort | uniq -c | sort -nr

echo "\nMost Common Patterns:"
grep "time:" "$LOG_FILE" | head -5
grep "platform:" "$LOG_FILE" | head -5

echo "\nPerformance:"
echo "Total corrections: $(wc -l < "$LOG_FILE")"
echo "Average per day: $(expr $(wc -l < "$LOG_FILE") / $(expr $(date +%s) - $(stat -f %B "$LOG_FILE")) / 86400)"
```

## Future Enhancement Areas

### Machine Learning Integration

Potential areas for ML enhancement:

1. **Pattern Discovery**: Automatically find new correction patterns
2. **Context Understanding**: Better context-aware corrections
3. **User Preference Learning**: Adapt to individual user patterns
4. **Confidence Scoring**: ML-based confidence for corrections

### Advanced Features

1. **Custom Rules**: User-defined correction patterns
2. **Command History**: Learn from user's command history
3. **Platform Detection**: Better automatic platform detection
4. **Semantic Understanding**: Understand command intent, not just syntax

## Best Practices Summary

1. **Start Simple**: Begin with high-confidence, high-frequency patterns
2. **Test Thoroughly**: Every correction needs comprehensive tests
3. **Monitor Continuously**: Track what's working and what isn't
4. **Iterate Based on Data**: Let usage patterns drive improvements
5. **Document Everything**: Explain why each correction exists
6. **Performance First**: Keep corrections fast and efficient
7. **User Experience**: Corrections should be invisible when they work

This iterative, data-driven approach ensures the post-processing system continues to improve and adapt to real-world usage patterns.