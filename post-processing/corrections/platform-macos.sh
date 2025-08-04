#!/bin/sh
# macOS Platform Corrections
# Fixes Linux-specific commands to work on macOS

apply_macos_corrections() {
    local command="$1"
    
    # Replace netstat -p combinations with lsof when looking for ports
    # Do this BEFORE removing -p flag generically
    if printf '%s' "$command" | grep -q "netstat.*-.*p.*grep.*:[0-9]"; then
        # Extract the port number and replace with lsof
        port=$(printf '%s' "$command" | sed -n 's/.*grep.*:\([0-9][0-9]*\).*/\1/p')
        if [ -n "$port" ]; then
            command="lsof -i :$port"
            # Return early to avoid further processing
            printf '%s' "$command"
            return
        fi
    fi
    
    # Fix netstat -p (not supported on macOS)
    command=$(printf '%s\n' "$command" | sed 's/netstat -[a-zA-Z]*p[a-zA-Z]*/netstat -an/g')
    
    # Fix case sensitivity for system output (macOS uses lowercase)
    command=$(printf '%s\n' "$command" | sed 's/grep [^|]*UDP[^|]*/grep -i udp/g')
    command=$(printf '%s\n' "$command" | sed 's/grep "UDP"/grep -i "udp"/g')
    command=$(printf '%s\n' "$command" | sed 's/grep '\''UDP'\''/grep -i '\''udp'\''/g')
    
    # Same for TCP - need to handle quotes properly
    command=$(printf '%s\n' "$command" | sed 's/grep [^|]*TCP[^|]*/grep -i tcp/g')
    command=$(printf '%s\n' "$command" | sed 's/grep "TCP"/grep -i "tcp"/g')
    command=$(printf '%s\n' "$command" | sed "s/grep 'TCP'/grep -i 'tcp'/g")
    
    # Fix ps options (BSD vs GNU)
    command=$(printf '%s\n' "$command" | sed 's/ps -aux/ps aux/g')
    command=$(printf '%s\n' "$command" | sed 's/ps -ef/ps aux/g')
    
    # Fix readlink (macOS doesn't have -f by default)
    command=$(printf '%s\n' "$command" | sed 's/readlink -f/readlink/g')
    
    # Fix sed -i (macOS requires backup extension)
    case "$command" in
        *"sed -i"*"s/"*)
            if ! printf '%s' "$command" | grep -q "sed -i[[:space:]]*''"; then
                command=$(printf '%s\n' "$command" | sed "s/sed -i[[:space:]]/sed -i '' /g")
            fi
            ;;
    esac
    
    # Fix stat command (different syntax)
    command=$(printf '%s\n' "$command" | sed 's/stat -c[[:space:]]*"%[a-zA-Z]"/stat -f "%p"/g')
    
    # Fix du --max-depth (macOS uses -d)
    command=$(printf '%s\n' "$command" | sed 's/--max-depth=1/-d 1/g')
    command=$(printf '%s\n' "$command" | sed 's/--max-depth=2/-d 2/g')
    command=$(printf '%s\n' "$command" | sed 's/--max-depth 1/-d 1/g')
    command=$(printf '%s\n' "$command" | sed 's/--max-depth 2/-d 2/g')
    
    # Fix sort -h (human readable) - not available on older macOS
    command=$(printf '%s\n' "$command" | sed 's/sort -h/sort -n/g')
    
    # Fix awk field references that might be GNU-specific
    command=$(printf '%s\n' "$command" | sed 's/awk.*\$5[^0-9]/awk "$1"/g')
    
    # Fix date command differences
    command=$(printf '%s\n' "$command" | sed 's/date --date=/date -j -f "%Y-%m-%d" /g')
    
    # Fix grep -P (Perl regex) - not available on macOS
    command=$(printf '%s\n' "$command" | sed 's/grep -P/grep -E/g')
    
    # Fix find -printf (GNU extension) 
    command=$(printf '%s\n' "$command" | sed 's/-printf[^[:space:]]*/\\-print/g')
    
    # Fix xargs -r (GNU extension) - not needed on BSD
    command=$(printf '%s\n' "$command" | sed 's/xargs -r/xargs/g')
    
    # Fix head/tail -c (character count) vs -c (bytes)
    # BSD uses -c for bytes, GNU uses -c for chars and --bytes for bytes
    command=$(printf '%s\n' "$command" | sed 's/head --bytes=/head -c /g')
    command=$(printf '%s\n' "$command" | sed 's/tail --bytes=/tail -c /g')
    
    # Fix package manager commands for macOS
    command=$(printf '%s\n' "$command" | sed 's/apt install/brew install/g')
    command=$(printf '%s\n' "$command" | sed 's/apt update/brew update/g')
    command=$(printf '%s\n' "$command" | sed 's/apt search/brew search/g')
    command=$(printf '%s\n' "$command" | sed 's/apt list/brew list/g')
    
    # Fix invalid brew flags (from evaluation)
    command=$(printf '%s\n' "$command" | sed 's/brew list --updated --last-month/brew list/g')
    command=$(printf '%s\n' "$command" | sed 's/--last-month//g')
    command=$(printf '%s\n' "$command" | sed 's/--updated//g')
    
    # Fix service management (systemctl vs launchctl)
    command=$(printf '%s\n' "$command" | sed 's/systemctl --failed/launchctl list | grep -v "^\-"/g')
    command=$(printf '%s\n' "$command" | sed 's/systemctl start/launchctl load/g')
    command=$(printf '%s\n' "$command" | sed 's/systemctl stop/launchctl unload/g')
    command=$(printf '%s\n' "$command" | sed 's/systemctl status/launchctl list/g')
    
    # Fix grep --color (not always available)
    command=$(printf '%s\n' "$command" | sed 's/grep --color[[:space:]]/grep /g')
    
    # Fix /dev/clipboard (doesn't exist on any platform)
    command=$(printf '%s\n' "$command" | sed 's/> \/dev\/clipboard$/ | pbcopy/g')
    command=$(printf '%s\n' "$command" | sed 's/>> \/dev\/clipboard$/ | pbcopy/g')
    
    printf '%s' "$command"
}

# Check if command has macOS compatibility issues
has_macos_issues() {
    local command="$1"
    case "$command" in
        *"netstat"*"-p"*|*"grep"*"UDP"*|*"ps -"*|*"sed -i"*|*"stat -c"*)
            return 0  # Has macOS issues
            ;;
        *)
            return 1  # No macOS issues
            ;;
    esac
}