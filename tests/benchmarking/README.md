# TermGPT Benchmarking

## Purpose

Compare different LLM models and see how post-processing fixes improve command generation. No fake validation - just show raw outputs for manual inspection.

## Usage

The benchmark now correctly shows post-processing by applying corrections to the SAME LLM output (not running the LLM twice).

```bash
# Basic usage
./benchmark.sh "find large files"

# Test different models
./benchmark.sh "find large files" codellama:33b-instruct

# Commands that trigger post-processing fixes:
./benchmark.sh "show network connections on port 80"  # May trigger netstat -p fix
./benchmark.sh "find files modified last week"         # Triggers mtime +7 -> -7 fix
./benchmark.sh "compress log files"                    # May add *.log filter
```

## Post-Processing Fixes

The benchmark shows both LLM output and post-processed result, highlighting fixes:

**Simple Platform Fixes We Keep:**
- macOS: `netstat -p` → `netstat -an` (removes unsupported flag)
- macOS: `grep UDP` → `grep -i udp` (case sensitivity)
- Time logic: `find -mtime +7` → `find -mtime -7` (last week vs older than week)
- Log compression: Adds `.log` filter when missing

**Example Output:**
```
Query: "show network connections on port 80"

LLM Output:
  netstat -tulpn | grep :80

Post-processed:
  netstat -an | grep :80
  
Fix Applied: Removed unsupported -p flag for macOS compatibility
```

## Contributing Fixes

Found a simple, targeted fix that improves compatibility? Add to:
- `post-processing/corrections/platform-macos.sh` (macOS fixes)
- `post-processing/corrections/platform-linux.sh` (Linux fixes) 
- `post-processing/corrections/common.sh` (universal fixes)

Keep fixes simple and focused on compatibility, not semantic changes.

## Commands

All test commands are in `commands.txt` - feel free to add your own use cases.