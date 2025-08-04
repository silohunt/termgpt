#!/bin/sh
# Linux Platform Corrections
# Fixes macOS-specific commands to work on Linux

apply_linux_corrections() {
    local command="$1"
    
    # Fix pbcopy/pbpaste (macOS clipboard)
    command=$(printf '%s\n' "$command" | sed 's/| pbcopy/| xclip -selection clipboard/g')
    command=$(printf '%s\n' "$command" | sed 's/pbpaste/xclip -selection clipboard -o/g')
    
    # Fix open command (macOS file opener)
    command=$(printf '%s\n' "$command" | sed 's/^open /xdg-open /g')
    command=$(printf '%s\n' "$command" | sed 's/| open /| xdg-open /g')
    
    # Fix mdfind (macOS Spotlight)
    command=$(printf '%s\n' "$command" | sed 's/mdfind/find . -name/g')
    
    # Fix launchctl (macOS service management)
    command=$(printf '%s\n' "$command" | sed 's/launchctl list/systemctl list-units/g')
    command=$(printf '%s\n' "$command" | sed 's/launchctl start/systemctl start/g')
    command=$(printf '%s\n' "$command" | sed 's/launchctl stop/systemctl stop/g')
    
    # Fix dscacheutil (macOS DNS cache)
    command=$(printf '%s\n' "$command" | sed 's/dscacheutil -flushcache/systemctl restart systemd-resolved/g')
    
    # Fix caffeinate (macOS sleep prevention)
    case "$command" in
        *"caffeinate"*)
            # No direct Linux equivalent, use systemd-inhibit
            command=$(printf '%s\n' "$command" | sed 's/caffeinate/systemd-inhibit --what=sleep/g')
            ;;
    esac
    
    # Fix say command (macOS text-to-speech)
    command=$(printf '%s\n' "$command" | sed 's/say /espeak /g')
    
    # Fix diskutil (macOS disk management)
    command=$(printf '%s\n' "$command" | sed 's/diskutil list/lsblk/g')
    command=$(printf '%s\n' "$command" | sed 's/diskutil info/lsblk -f/g')
    
    printf '%s' "$command"
}

# Check if command has Linux compatibility issues
has_linux_issues() {
    local command="$1"
    case "$command" in
        *"pbcopy"*|*"pbpaste"*|*"open "*|*"mdfind"*|*"launchctl"*)
            return 0  # Has Linux issues
            ;;
        *)
            return 1  # No Linux issues
            ;;
    esac
}