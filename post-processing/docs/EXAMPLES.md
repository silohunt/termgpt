# Post-Processing Examples

Real-world examples of how the post-processing system improves LLM-generated commands.

## Time Corrections

### Finding Recent Files

**User Query**: "find log files from last week"

**LLM Output**: 
```bash
find . -type f -name "*.log" -mtime +7
```

**Issues**:
- Uses `+7` which finds files OLDER than 7 days
- Searches current directory instead of log directory

**Corrected**:
```bash
find /var/log -name "*.log" -type f -mtime -7
```

**Corrections Applied**:
1. Time: Changed `+7` to `-7` (last week = recent files)
2. Files: Changed path from `.` to `/var/log`

### Cleaning Old Files

**User Query**: "delete files older than 30 days"

**LLM Output**: 
```bash
find . -mtime -30 -delete
```

**Issues**:
- Uses `-30` which finds files NEWER than 30 days

**Corrected**:
```bash
find . -mtime +30 -delete
```

**Note**: This is correct usage - no correction needed. The system preserves valid commands.

## Platform Corrections

### Network Monitoring (macOS)

**User Query**: "show processes using network ports"

**LLM Output**: 
```bash
netstat -tulnp | grep LISTEN
```

**Issues**:
- `-p` flag not supported on macOS
- Case-sensitive grep won't match macOS output

**Corrected**:
```bash
netstat -an | grep -i listen
```

### Finding Process by Port (macOS)

**User Query**: "what process is using port 8080"

**LLM Output**: 
```bash
netstat -anp | grep :8080
```

**Issues**:
- macOS netstat can't show process info

**Corrected**:
```bash
lsof -i :8080
```

### Clipboard Operations (Linux)

**User Query**: "copy file contents to clipboard"

**LLM Output**: 
```bash
cat file.txt | pbcopy
```

**Issues**:
- `pbcopy` is macOS-specific

**Corrected**:
```bash
cat file.txt | xclip -selection clipboard
```

## File Pattern Corrections

### Smart Scope Correction

**User Query**: "list all python files"

**LLM Output**: 
```bash
find / -name "*.py"  # Searches entire filesystem!
```

**Issues**:
- Scans entire filesystem (slow, permission errors)
- Not what user typically wants for project files

**Corrected**:
```bash
find . -name "*.py"  # Searches current directory
```

**Context-Aware**: Preserves system searches when appropriate

**User Query**: "search the entire system for config files"

**LLM Output**: 
```bash
find / -name "*.conf"
```

**Preserved** (user explicitly wants system search):
```bash
find / -name "*.conf"  # Kept as-is
```

### Log Compression

**User Query**: "compress old log files"

**LLM Output**: 
```bash
find . -type f -mtime +30 -exec gzip {} \;
```

**Issues**:
- No file filter - would compress ALL old files
- Searches current directory

**Corrected**:
```bash
find /var/log -name "*.log" -type f -mtime +30 -exec gzip {} \;
```

### Backup Operations

**User Query**: "backup all config files"

**LLM Output**: 
```bash
find /etc -type f -name "*.conf" | tar -czf backup.tar.gz -T -
```

**Issues**:
- Good command, but could include .git if in user directory

**Corrected** (if in user directory):
```bash
find /etc -type f -name "*.conf" -not -path "*/.git/*" -not -path "*/.svn/*" | tar -czf backup.tar.gz -T -
```

## Security Corrections

### Permission Changes

**User Query**: "make script executable by everyone"

**LLM Output**: 
```bash
chmod 777 script.sh
```

**Issues**:
- Too permissive - allows write access to everyone

**Corrected**:
```bash
chmod 755 script.sh
```

### Path Quoting

**User Query**: "process files in my documents"

**LLM Output**: 
```bash
find /Users/john/My Documents -type f
```

**Issues**:
- Unquoted path with space will fail

**Corrected**:
```bash
find "/Users/john/My Documents" -type f
```

## Complex Examples

### Multi-Correction Example

**User Query**: "find and compress large log files from last month on my mac"

**LLM Output**: 
```bash
find . -size +100M -mtime +30 | grep .log | xargs gzip
```

**Issues**:
1. Wrong time direction for "from last month"
2. Inefficient grep for file extension
3. No proper file type filter

**Corrected**:
```bash
find /var/log -name "*.log" -type f -size +100M -mtime -30 -exec gzip {} \;
```

**Corrections Applied**:
1. Time: `+30` → `-30` (last month = recent)
2. Files: Added `-name "*.log"` filter
3. Path: `.` → `/var/log`
4. Structure: Removed unnecessary grep, used -exec

### Platform + Time + Security

**User Query**: "show network connections from yesterday"

**LLM Output**: 
```bash
netstat -anp | grep TIME_WAIT | grep -mtime +1
```

**Issues**:
1. `-p` not supported on macOS
2. Wrong time concept (grep doesn't have -mtime)
3. TIME_WAIT case sensitivity

**Corrected**:
```bash
# Note: Network connections are transient - can't filter by date directly
netstat -an | grep -i time_wait
```

## Patterns Not Corrected

The system is smart enough not to "fix" valid commands:

### Valid Time Usage

**Input**: `find /tmp -mtime +7 -delete`  
**Output**: `find /tmp -mtime +7 -delete` (unchanged)

This correctly finds files older than 7 days - no correction needed.

### Platform-Specific When Appropriate

**Input**: `if [[ "$OSTYPE" == "darwin"* ]]; then pbcopy; else xclip; fi`  
**Output**: Unchanged - script already handles platform differences

### Valid Case-Sensitive Grep

**Input**: `ps aux | grep "[P]ython"`  
**Output**: Unchanged - the bracket syntax requires exact case

## Performance Impact

The post-processing adds minimal overhead:

```bash
# Time without post-processing
time echo "find . -mtime +7" | process_llm_output
real    0m0.002s

# Time with post-processing  
time echo "find . -mtime +7" | process_with_corrections
real    0m0.012s
```

Only 10ms added for significantly improved reliability.

## User Feedback Examples

### Before Post-Processing
"The command didn't work on my Mac. It kept saying invalid option -p"

### After Post-Processing
"It just works! The commands now run correctly on my system"

## Future Corrections

Based on user feedback, planned corrections include:

1. **Package Managers**: apt → brew on macOS
2. **Service Management**: systemctl → launchctl  
3. **GNU vs BSD Tools**: Automatic coreutils detection
4. **Shell Differences**: Bash vs zsh vs POSIX sh