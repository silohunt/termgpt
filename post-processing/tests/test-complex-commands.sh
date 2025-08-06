#!/bin/bash

# Test suite for complex command preservation and enhancement functions

# Source the complex commands module to test
. "$(dirname "$0")/../corrections/complex-commands.sh"

# Test counter
TESTS=0
PASSED=0

# Test functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    
    TESTS=$((TESTS + 1))
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ $description"
    else
        echo "✗ $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"
    
    TESTS=$((TESTS + 1))
    if echo "$haystack" | grep -q "$needle"; then
        PASSED=$((PASSED + 1))
        echo "✓ $description"
    else
        echo "✗ $description"
        echo "  Should contain: $needle"
        echo "  Actual output: $haystack"
    fi
}

run_test() {
    "$1"
}

print_summary() {
    echo ""
    echo "Test Summary: $PASSED/$TESTS tests passed"
    if [ "$PASSED" -eq "$TESTS" ]; then
        echo "All tests passed!"
        exit 0
    else
        echo "Some tests failed."
        exit 1
    fi
}

# Test preserve_complex_chains function
test_preserve_email_processing() {
    local input="find /var/mail -type f -name '*.mbox' | while read f; do grep -l 'urgent' \"\$f\" | xargs -I {} formail -s procmail < {}; done"
    local query="Process all urgent emails in mailboxes"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "Email processing chain should be preserved"
}

test_preserve_monitoring_loop() {
    local input="while true; do ps aux | grep -v grep | grep myprocess || echo 'Process not running' | mail -s 'Alert' admin@example.com; sleep 300; done"
    local query="Monitor myprocess and send email alerts every 5 minutes"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "Monitoring loop should be preserved"
}

test_preserve_log_analysis_pipeline() {
    local input="tail -f /var/log/app.log | grep ERROR | while read line; do echo \"\$line\" | sed 's/.*ERROR: //' | cut -d' ' -f1 | sort | uniq -c | sort -rn; done"
    local query="Analyze error patterns in real-time from application logs"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "Log analysis pipeline should be preserved"
}

test_preserve_data_extraction_chain() {
    local input="find . -name '*.csv' -exec head -1 {} \\; | sort -u | awk -F',' '{print NF, \$0}' | sort -n"
    local query="Extract and analyze CSV headers to find unique column structures"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "Data extraction chain should be preserved"
}

test_preserve_system_metrics_collection() {
    local input="{ df -h; free -m; uptime; } | tee /tmp/metrics.txt | grep -E '(available|Mem:|load)' | awk '{print strftime(\"%Y-%m-%d %H:%M:%S\"), \$0}'"
    local query="Collect and timestamp system metrics"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "System metrics collection should be preserved"
}

test_non_complex_command_unchanged() {
    local input="ls -la"
    local query="List all files"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "Simple commands should pass through unchanged"
}

# Test detect_script_generation function
test_detect_health_check_script() {
    local input="echo 'Checking system health...'"
    local query="Create a health check script that monitors CPU, memory, disk usage and network connectivity"
    local result="$(detect_script_generation "$input" "$query")"
    assert_contains "$result" "#!/bin/bash" "Should generate proper script shebang"
    assert_contains "$result" "df -h" "Should include disk usage check"
    assert_contains "$result" "free" "Should include memory check"
    assert_contains "$result" "ping" "Should include network connectivity check"
}

test_detect_backup_script() {
    local input="echo 'Starting backup...'"
    local query="Create a backup script for database and web files"
    local result="$(detect_script_generation "$input" "$query")"
    assert_contains "$result" "#!/bin/bash" "Should generate proper script shebang"
    assert_contains "$result" "tar" "Should include file archiving"
    assert_contains "$result" "tar" "Should include file archiving"
    assert_contains "$result" "date" "Should include timestamp"
}

test_detect_cleanup_script() {
    local input="rm old_files"
    local query="Write a cleanup script to remove temporary files older than 7 days"
    local result="$(detect_script_generation "$input" "$query")"
    assert_contains "$result" "#!/bin/bash" "Should generate proper script shebang"
    assert_contains "$result" "find" "Should use find for file discovery"
    assert_contains "$result" "mtime" "Should check for files older than 7 days"
    assert_contains "$result" "tmp" "Should target temp directories"
}

test_no_script_for_direct_command() {
    local input="find /tmp -mtime +7 -delete"
    local query="Delete temporary files older than 7 days"
    local result="$(detect_script_generation "$input" "$query")"
    assert_equals "$input" "$result" "Direct commands should not trigger script generation"
}

# Test improve_error_analysis function
test_improve_basic_error_grep() {
    local input="grep ERROR /var/log/app.log"
    local query="Extract and analyze error patterns from multiple log files"
    local result="$(improve_error_analysis "$input" "$query")"
    assert_contains "$result" "awk" "Should enhance with awk for pattern analysis"
    assert_contains "$result" "sort" "Should include sorting"
    assert_contains "$result" "uniq -c" "Should count unique patterns"
}

test_improve_multifile_error_analysis() {
    local input="grep -r ERROR /var/log/"
    local query="Find all errors across system logs and group by type"
    local result="$(improve_error_analysis "$input" "$query")"
    assert_contains "$result" "/var/log" "Should target log directory"
    assert_contains "$result" "awk" "Should use awk for grouping"
    assert_contains "$result" "sort -rn" "Should sort by frequency"
}

test_no_improvement_for_complete_analysis() {
    local input="find /var/log -name '*.log' -exec grep ERROR {} + | awk '{print \$5}' | sort | uniq -c | sort -rn"
    local query="Analyze error patterns"
    local result="$(improve_error_analysis "$input" "$query")"
    assert_equals "$input" "$result" "Already complete analysis should not be modified"
}

# Test integration - multiple corrections in sequence
test_integration_complex_preservation_priority() {
    # Complex command should be preserved even if it contains patterns other modules might fix
    local input="find / -name '*.log' | while read f; do grep ERROR \"\$f\" | wc -l; done"
    local query="Count errors in all log files on the system"
    local result="$(preserve_complex_chains "$input" "$query")"
    assert_equals "$input" "$result" "Complex chains should be preserved despite having find / pattern"
}

test_integration_script_generation_trigger() {
    local input="echo 'Monitor system'"
    local query="Create a monitoring script that checks disk space, memory, and running processes every 10 minutes"
    local result="$(detect_script_generation "$input" "$query")"
    assert_contains "$result" "while true" "Should create monitoring loop"
    assert_contains "$result" "sleep 600" "Should sleep for 10 minutes"
    assert_contains "$result" "df -h" "Should check disk space"
    assert_contains "$result" "ps aux" "Should check processes"
}

# Run all tests
echo "Testing complex command preservation..."
run_test test_preserve_email_processing
run_test test_preserve_monitoring_loop
run_test test_preserve_log_analysis_pipeline
run_test test_preserve_data_extraction_chain
run_test test_preserve_system_metrics_collection
run_test test_non_complex_command_unchanged

echo -e "\nTesting script generation detection..."
run_test test_detect_health_check_script
run_test test_detect_backup_script
run_test test_detect_cleanup_script
run_test test_no_script_for_direct_command

echo -e "\nTesting error analysis improvement..."
run_test test_improve_basic_error_grep
run_test test_improve_multifile_error_analysis
run_test test_no_improvement_for_complete_analysis

echo -e "\nTesting integration scenarios..."
run_test test_integration_complex_preservation_priority
run_test test_integration_script_generation_trigger

# Print test summary
print_summary