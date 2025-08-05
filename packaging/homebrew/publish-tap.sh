#!/bin/bash
set -euo pipefail

# Script to publish TermGPT Homebrew tap

TAP_REPO="silohunt/homebrew-termgpt"
FORMULA_NAME="termgpt"

echo "Publishing TermGPT Homebrew tap..."

# Check if we're in the right directory
if [[ ! -f "termgpt.rb" ]]; then
    echo "Error: termgpt.rb not found. Run this script from the packaging/homebrew directory."
    exit 1
fi

# Instructions for manual setup (since we can't create GitHub repos via CLI without auth)
echo ""
echo "To publish this tap, follow these steps:"
echo ""
echo "1. Create a new GitHub repository named 'homebrew-termgpt' under the silohunt organization"
echo "2. Clone the repository locally:"
echo "   git clone https://github.com/${TAP_REPO}.git"
echo ""
echo "3. Copy the formula and documentation:"
echo "   cp termgpt.rb homebrew-termgpt/"
echo "   cp README.md homebrew-termgpt/"
echo ""
echo "4. Commit and push:"
echo "   cd homebrew-termgpt"
echo "   git add ."
echo "   git commit -m 'Add TermGPT formula v0.8.0'"
echo "   git push origin main"
echo ""
echo "5. Test installation:"
echo "   brew tap silohunt/termgpt"
echo "   brew install termgpt"
echo ""
echo "Formula ready for publishing!"
echo "Formula file: $(pwd)/termgpt.rb"
echo "Documentation: $(pwd)/README.md"