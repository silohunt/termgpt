# TermGPT Benchmarking

## Purpose

Compare different LLM models and see how post-processing fixes improve command generation. No fake validation - just show raw outputs for manual inspection.

## Usage

Test different models on the same commands to see quality differences:

```bash
# Test with codellama:7b
TERMGPT_MODEL=codellama:7b-instruct ./benchmark.sh "Find processes using more than 500MB memory"

# Test with larger model
TERMGPT_MODEL=codellama:33b-instruct ./benchmark.sh "Find processes using more than 500MB memory"

# Test with different model family
TERMGPT_MODEL=llama3:8b-instruct ./benchmark.sh "Find processes using more than 500MB memory"
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