#!/bin/sh
# Test the is_world_writable security function

# Extract just the function for testing
sed -n '/^is_world_writable()/,/^}/p' ../../bin/termgpt > /tmp/test_func.sh
. /tmp/test_func.sh
rm -f /tmp/test_func.sh

echo "Testing is_world_writable() security function..."
echo "=============================================="

# Test setup
TEST_DIR="/tmp/termgpt_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit 1

# Cleanup on exit
trap 'cd /; rm -rf "$TEST_DIR"' EXIT

failures=0
test_count=0

test_permission() {
  local file="$1"
  local perms="$2"
  local expected="$3"
  local desc="$4"
  
  test_count=$((test_count + 1))
  
  # Create test file with specific permissions
  touch "$file"
  chmod "$perms" "$file"
  
  # Test the function
  if is_world_writable "$file"; then
    result="world-writable"
  else
    result="not-writable"
  fi
  
  # Check result
  if [ "$result" = "$expected" ]; then
    echo "✓ Test $test_count PASSED: $desc (chmod $perms)"
  else
    echo "✗ Test $test_count FAILED: $desc (chmod $perms)"
    echo "  Expected: $expected, Got: $result"
    failures=$((failures + 1))
  fi
  
  rm -f "$file"
}

echo
echo "1. Testing standard permission scenarios..."
test_permission "test1.txt" "644" "not-writable" "Standard file (owner write only)"
test_permission "test2.txt" "646" "world-writable" "World-writable file"
test_permission "test3.txt" "666" "world-writable" "All-writable file"
test_permission "test4.txt" "777" "world-writable" "Full permissions"
test_permission "test5.txt" "640" "not-writable" "Group readable"
test_permission "test6.txt" "600" "not-writable" "Owner only"

echo
echo "2. Testing edge cases..."
test_permission "test7.txt" "642" "world-writable" "World write bit set"
test_permission "test8.txt" "643" "world-writable" "World write+execute"
test_permission "test9.txt" "641" "not-writable" "World execute only"
test_permission "test10.txt" "000" "not-writable" "No permissions"

echo
echo "3. Testing non-existent file..."
test_count=$((test_count + 1))
if is_world_writable "/tmp/does_not_exist_$$"; then
  echo "✗ Test $test_count FAILED: Non-existent file reported as world-writable"
  failures=$((failures + 1))
else
  echo "✓ Test $test_count PASSED: Non-existent file correctly reported as not-writable"
fi

echo
echo "4. Testing symlink permissions (not target)..."
test_count=$((test_count + 1))
touch target.txt
chmod 666 target.txt
ln -s target.txt symlink.txt
# Note: We check symlink permissions, not target permissions
# This is correct security behavior - symlinks themselves can't be world-writable
if is_world_writable "symlink.txt"; then
  echo "✗ Test $test_count FAILED: Symlink incorrectly reported as world-writable"
  failures=$((failures + 1))
else
  echo "✓ Test $test_count PASSED: Symlink correctly checks link permissions, not target"
fi
rm -f target.txt symlink.txt

echo
echo "5. Testing directory permissions..."
test_count=$((test_count + 1))
mkdir testdir
chmod 777 testdir
if is_world_writable "testdir"; then
  echo "✓ Test $test_count PASSED: World-writable directory detected"
else
  echo "✗ Test $test_count FAILED: World-writable directory not detected"
  failures=$((failures + 1))
fi
rmdir testdir

echo
echo "=============================================="
echo "Total tests: $test_count"
echo "Passed: $((test_count - failures))"
echo "Failed: $failures"

if [ $failures -eq 0 ]; then
  echo
  echo "✓ All tests passed!"
  exit 0
else
  echo
  echo "✗ Some tests failed!"
  exit 1
fi