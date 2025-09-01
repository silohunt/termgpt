#!/bin/bash
echo "Testing termgpt-shell initialization..."

# Test each part
echo "1. Testing basic execution:"
echo 'echo "hello"' | ../bin/termgpt-shell || echo "FAILED"

echo "2. Testing with .quit:"
echo '.quit' | ../bin/termgpt-shell || echo "FAILED"

echo "3. Testing help:"
../bin/termgpt-shell --help || echo "FAILED"

echo "Done"