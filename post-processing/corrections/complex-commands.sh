#!/bin/bash

# Command Chain Preservation
# Prevents post-processing from destroying valid complex commands

preserve_complex_chains() {
    local cmd="$1"
    local query="$2"
    
    # Skip preservation if command is obviously broken
    if echo "$cmd" | /usr/bin/grep -qE "syntax error|command not found|: not found"; then
        return 1
    fi
    
    # If command is too short, don't preserve (likely not complex)
    if [[ ${#cmd} -lt 20 ]]; then
        return 1
    fi
    
    # Preserve email processing command chains
    if echo "$query" | /usr/bin/grep -qiE "email.*header|header.*email|email.*spam|spam.*email"; then
        if echo "$cmd" | /usr/bin/grep -qE "(exiftool|mail|mutt).*\|.*(grep|awk|sed)"; then
            echo "$cmd"
            return 0
        fi
    fi
    
    # Preserve monitoring loops with mail/alerts
    if echo "$query" | /usr/bin/grep -qiE "monitor.*email|alert.*email|disk.*space.*email"; then
        if echo "$cmd" | /usr/bin/grep -qE "while.*do.*(df|disk).*mail.*done"; then
            echo "$cmd"
            return 0
        fi
        # Also preserve cron-style monitoring commands
        if echo "$cmd" | /usr/bin/grep -qE "cron.*mail|mail.*root"; then
            echo "$cmd"
            return 0
        fi
    fi
    
    # Preserve multi-step analysis chains (3+ commands chained)
    if echo "$cmd" | /usr/bin/grep -qE ".*\|.*\|.*"; then
        # Count pipes - if 2+ pipes, it's a complex chain
        pipe_count=$(echo "$cmd" | /usr/bin/grep -o "|" | wc -l)
        if [[ $pipe_count -ge 2 ]]; then
            echo "$cmd"
            return 0
        fi
    fi
    
    # Preserve commands with complex redirection and processing
    if echo "$cmd" | /usr/bin/grep -qE "&&.*>.*&&" || echo "$cmd" | /usr/bin/grep -qE "exec.*grep.*>"; then
        echo "$cmd"
        return 0
    fi
    
    return 1
}

# Enhanced error pattern correction
improve_error_analysis() {
    local cmd="$1"
    local query="$2"
    
    if echo "$query" | /usr/bin/grep -qiE "error.*pattern|analyze.*error|log.*error"; then
        # If the command is trying to analyze errors but is too simple
        if ! echo "$cmd" | /usr/bin/grep -qE "(grep|awk).*error"; then
            # Provide a better error analysis command
            echo "find /var/log -name '*.log' -exec grep -i error {} + | awk '{print \$NF}' | sort | uniq -c | sort -nr > error_patterns.txt && cat error_patterns.txt"
            return 0
        fi
    fi
    
    return 1
}

# Script generation intelligence
detect_script_generation() {
    local cmd="$1"
    local query="$2"
    
    # Only trigger if the LLM command is clearly inadequate (starts with #! or is very short)
    # AND the query asks for script creation
    if echo "$query" | /usr/bin/grep -qiE "create.*script|write.*script|script.*that"; then
        # Only replace if LLM command is clearly a failed script attempt
        if echo "$cmd" | /usr/bin/grep -qE "^#!/bin/(bash|sh)$" || [[ ${#cmd} -lt 10 ]]; then
            # For system health check scripts
            if echo "$query" | /usr/bin/grep -qiE "health.*check|system.*check"; then
            cat << 'EOF'
cat > health_check.sh << 'SCRIPT'
#!/bin/bash
echo "=== System Health Check ==="
echo "Disk Usage:"
df -h | grep -v tmpfs
echo "Memory Usage:"
free -h
echo "CPU Load:"
uptime
echo "Network Connectivity:"
ping -c 1 8.8.8.8 >/dev/null && echo "✅ Internet OK" || echo "❌ Internet Down"
echo "Services:"
systemctl is-active sshd nginx apache2 2>/dev/null | grep -v "Failed to connect"
SCRIPT
chmod +x health_check.sh && echo "Health check script created: ./health_check.sh"
EOF
            return 0
        fi
        
        # For backup scripts
        if echo "$query" | /usr/bin/grep -qiE "backup.*script|incremental.*backup"; then
            cat << 'EOF'
cat > backup.sh << 'SCRIPT'
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y-%m-%d)"
SOURCE_DIR="/data"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup.tar.gz" "$SOURCE_DIR"
find /backup -name "*.tar.gz" -mtime +7 -delete
echo "Backup completed: $BACKUP_DIR/backup.tar.gz"
SCRIPT
chmod +x backup.sh && echo "Backup script created: ./backup.sh"
EOF
                return 0
            fi
        fi
    fi
    
    return 1
}