#!/bin/sh
# Test injection safety in apply_platform_corrections

# Extract the function for testing
sed -n '/^apply_platform_corrections()/,/^}/p' ../../bin/termgpt > /tmp/test_inject_func.sh

# Set platform for testing
TERMGPT_PLATFORM="macos"
export TERMGPT_PLATFORM

. /tmp/test_inject_func.sh
rm -f /tmp/test_inject_func.sh

echo "Testing injection safety in apply_platform_corrections..."
echo "========================================================"

failures=0
test_count=0

test_injection() {
  local desc="$1"
  local input="$2"
  local test_file="/tmp/injection_test_$$"
  
  test_count=$((test_count + 1))
  
  # Create a test file that should NOT be created if injection is prevented
  rm -f "$test_file"
  
  # Run the potentially dangerous input through the function
  result=$(apply_platform_corrections "$input" 2>&1)
  
  # Check if injection occurred
  if [ -f "$test_file" ]; then
    echo "✗ Test $test_count FAILED: $desc"
    echo "  Injection succeeded! File $test_file was created"
    echo "  Input: $input"
    failures=$((failures + 1))
    rm -f "$test_file"
  else
    echo "✓ Test $test_count PASSED: $desc"
  fi
}

echo
echo "1. Testing command substitution attempts..."
test_injection "Dollar parentheses" 'netstat -p $(touch /tmp/injection_test_$$)'
test_injection "Backticks" 'netstat -p `touch /tmp/injection_test_$$`'
test_injection "Nested substitution" 'grep UDP$(touch /tmp/injection_test_$$)'

echo
echo "2. Testing special character handling..."
test_injection "Newline injection" 'netstat -p
touch /tmp/injection_test_$$'
test_injection "Semicolon injection" 'netstat -p; touch /tmp/injection_test_$$'
test_injection "Pipe injection" 'netstat -p | touch /tmp/injection_test_$$'
test_injection "And injection" 'netstat -p && touch /tmp/injection_test_$$'

echo
echo "3. Testing echo escape sequences..."
# Some echo implementations interpret these
test_injection "Backslash sequences" 'netstat -p \n touch /tmp/injection_test_$$'
test_injection "Hex sequences" 'netstat -p \x0a touch /tmp/injection_test_$$'

echo
echo "4. Testing quote escaping..."
test_injection "Single quote escape" "netstat -p' touch /tmp/injection_test_$$ '"
test_injection "Double quote escape" 'netstat -p" touch /tmp/injection_test_$$ "'

echo
echo "5. Testing legitimate commands still work..."
test_count=$((test_count + 1))
result=$(apply_platform_corrections "netstat -anp | grep UDP")
expected="netstat -an | grep -i udp"
if [ "$result" = "$expected" ]; then
  echo "✓ Test $test_count PASSED: Legitimate command processed correctly"
else
  echo "✗ Test $test_count FAILED: Legitimate command not processed correctly"
  echo "  Expected: $expected"
  echo "  Got: $result"
  failures=$((failures + 1))
fi

echo
echo "========================================================"
echo "Total tests: $test_count"
echo "Passed: $((test_count - failures))"
echo "Failed: $failures"

if [ $failures -eq 0 ]; then
  echo
  echo "✓ All injection tests passed!"
  exit 0
else
  echo
  echo "✗ SECURITY WARNING: Injection vulnerabilities detected!"
  exit 1
fi