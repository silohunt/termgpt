#!/bin/bash
# Comprehensive evaluation of CodeLlama output

commands=(
    "find log files that were modified in the last 3 days"
    "delete backup files older than 30 days"
    "compress log files from last week"  
    "show files created yesterday in the home directory"
    "find config files modified within the past hour"
    "show which process is using port 8080"
    "list all UDP connections on the system"
    "find processes consuming more than 50% CPU"
    "show network connections from external IPs"
    "kill all processes matching nginx"
    "backup all configuration files excluding temporary ones"
    "find duplicate files in the current directory tree"
    "compress all log files larger than 100MB from system directories"
    "copy all python files to a backup directory preserving structure"
    "find files with specific permissions 644 in user directories"
    "show disk usage of directories larger than 1GB sorted by size"
    "monitor system memory usage in real time"
    "list all installed packages that were updated last month"
    "show system services that failed to start"
    "display running processes sorted by memory usage"
    "find all files containing specific error patterns in log directories"
    "extract IP addresses from log files and count occurrences"
    "search for TODO comments in all source code files"
    "find files with specific content and replace text across multiple files"
    "grep for patterns case-insensitively in compressed files"
    "copy the current directory path to clipboard"
    "save system information to a file and copy to clipboard"
    "list directory contents and copy to clipboard"
    "show current git branch and copy to clipboard"
    "export environment variables and copy to clipboard"
)

echo "CodeLlama Evaluation Results"
echo "==========================="
echo

for i in "${!commands[@]}"; do
    num=$((i + 1))
    echo "Test $num: ${commands[$i]}"
    echo "---"
    result=$(echo "q" | ./bin/termgpt "${commands[$i]}" 2>/dev/null | grep -A1 "Generated Command:" | tail -1)
    echo "Output: $result"
    echo
done