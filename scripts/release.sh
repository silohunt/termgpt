#!/bin/sh
# Quick release script - updates all version references
# Usage: ./scripts/release.sh <version>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

V="$1"

# Update scripts
sed -i.bak "s/VERSION=\"[0-9.]*\"/VERSION=\"$V\"/" bin/termgpt bin/termgpt-init bin/termgpt-shell

# Update docs
sed -i.bak "s/TermGPT v[0-9.]*/TermGPT v$V/g" README.md docs/shell-mode.md
sed -i.bak "s/(New in v[0-9.]*)/(New in v$V)/g" docs/shell-mode.md

# Clean up backup files
rm bin/*.bak docs/*.bak README.md.bak 2>/dev/null || true

echo "Updated to v$V"
echo "Run: git add -A && git commit -m \"Release v$V\" && git tag v$V && git push origin main --tags"