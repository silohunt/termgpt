#!/bin/sh
# Test suite for platform corrections

# Source the correction modules
. "$(dirname "$0")/../corrections/platform-macos.sh"
. "$(dirname "$0")/../corrections/platform-linux.sh"

# Test counter
TESTS=0
PASSED=0

# Test function
test_macos_correction() {
    local description="$1"
    local input="$2"
    local expected="$3"
    local actual
    
    TESTS=$((TESTS + 1))
    actual=$(apply_macos_corrections "$input")
    
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ [macOS] $description"
    else
        echo "✗ [macOS] $description"
        echo "  Input:    $input"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

test_linux_correction() {
    local description="$1"
    local input="$2"
    local expected="$3"
    local actual
    
    TESTS=$((TESTS + 1))
    actual=$(apply_linux_corrections "$input")
    
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ [Linux] $description"
    else
        echo "✗ [Linux] $description"
        echo "  Input:    $input"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

echo "Testing platform corrections..."
echo

# macOS corrections
echo "macOS-specific corrections:"
test_macos_correction "Convert netstat -p with port to lsof" \
    "netstat -anp | grep :80" \
    "lsof -i :80"

test_macos_correction "Fix UDP case sensitivity" \
    "netstat -an | grep UDP" \
    "netstat -an | grep -i udp"

test_macos_correction "Fix TCP case sensitivity" \
    "netstat -an | grep 'TCP'" \
    "netstat -an | grep -i tcp"  # Quotes are removed by sed

test_macos_correction "Replace netstat -p with lsof" \
    "netstat -tlnp | grep :8080" \
    "lsof -i :8080"

test_macos_correction "Fix ps aux syntax" \
    "ps -aux | grep nginx" \
    "ps aux | grep nginx"

test_macos_correction "Fix ps -ef syntax" \
    "ps -ef | grep python" \
    "ps aux | grep python"

test_macos_correction "Fix sed -i syntax" \
    "sed -i s/foo/bar/g file.txt" \
    "sed -i '' s/foo/bar/g file.txt"

test_macos_correction "Fix stat -c syntax" \
    "stat -c \"%a\" file.txt" \
    "stat -f \"%p\" file.txt"

test_macos_correction "Fix du --max-depth" \
    "du --max-depth=1 /var" \
    "du -d 1 /var"

test_macos_correction "Fix /dev/clipboard redirect" \
    "pwd > /dev/clipboard" \
    "pwd  | pbcopy"

test_macos_correction "Fix du --max-depth syntax" \
    "du --max-depth=1 /var" \
    "du -d 1 /var"

test_macos_correction "Fix sort -h to -n" \
    "du -d 1 | sort -h" \
    "du -d 1 | sort -n"

test_macos_correction "Fix grep -P to -E" \
    "grep -P 'pattern' file.txt" \
    "grep -E 'pattern' file.txt"

test_macos_correction "Fix apt to brew install" \
    "apt install nginx" \
    "brew install nginx"

test_macos_correction "Fix systemctl to launchctl" \
    "systemctl --failed" \
    "launchctl list | grep -v \"^\-\""

test_macos_correction "Fix invalid brew flags" \
    "brew list --updated --last-month" \
    "brew list"

echo

# Linux corrections
echo "Linux-specific corrections:"
test_linux_correction "Replace pbcopy with xclip" \
    "echo 'test' | pbcopy" \
    "echo 'test' | xclip -selection clipboard"

test_linux_correction "Replace pbpaste with xclip" \
    "pbpaste > file.txt" \
    "xclip -selection clipboard -o > file.txt"

test_linux_correction "Replace open with xdg-open" \
    "open file.pdf" \
    "xdg-open file.pdf"

test_linux_correction "Replace mdfind with find" \
    "mdfind 'kMDItemFSName == *.txt'" \
    "find . -name 'kMDItemFSName == *.txt'"

test_linux_correction "Replace launchctl list" \
    "launchctl list | grep com.apple" \
    "systemctl list-units | grep com.apple"

test_linux_correction "Replace caffeinate" \
    "caffeinate -t 3600" \
    "systemd-inhibit --what=sleep -t 3600"

test_linux_correction "Replace diskutil list" \
    "diskutil list" \
    "lsblk"

# Summary
echo
echo "Platform correction tests: $PASSED/$TESTS passed"
[ "$PASSED" -eq "$TESTS" ] && exit 0 || exit 1