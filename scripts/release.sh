#!/bin/bash
# TermGPT Release Script
# Automates version bumping, tagging, and Homebrew formula updates

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version> (e.g., 0.9.4)"
    echo "This will:"
    echo "  1. Update VERSION in all scripts"
    echo "  2. Commit changes"
    echo "  3. Create and push git tag"  
    echo "  4. Update Homebrew formula"
    exit 1
fi

NEW_VERSION="$1"
TAG="v$NEW_VERSION"

echo "🚀 Releasing TermGPT $NEW_VERSION"

# Update version in all files
echo "📝 Updating version numbers..."
sed -i '' "s/VERSION=\"[0-9]\+\.[0-9]\+\.[0-9]\+\"/VERSION=\"$NEW_VERSION\"/" bin/termgpt bin/termgpt-init bin/termgpt-shell

echo "✅ Updated version to $NEW_VERSION"

# Commit changes
echo "📦 Committing version bump..."
git add bin/termgpt bin/termgpt-init bin/termgpt-shell
git commit -m "Bump version to $NEW_VERSION"

# Create and push tag
echo "🏷️  Creating release tag..."
git tag "$TAG"
git push origin main
git push origin "$TAG"

# Update Homebrew formula
echo "🍺 Updating Homebrew formula..."
curl -sL "https://github.com/silohunt/termgpt/archive/$TAG.tar.gz" > /tmp/release.tar.gz
SHA256=$(shasum -a 256 /tmp/release.tar.gz | cut -d' ' -f1)
rm /tmp/release.tar.gz

git clone git@github.com:silohunt/homebrew-termgpt.git /tmp/homebrew
cd /tmp/homebrew

sed -i '' "s|url \".*\"|url \"https://github.com/silohunt/termgpt/archive/$TAG.tar.gz\"|" termgpt.rb
sed -i '' "s|sha256 \".*\"|sha256 \"$SHA256\"|" termgpt.rb  
sed -i '' "s|version \".*\"|version \"$NEW_VERSION\"|" termgpt.rb

git add termgpt.rb
git commit -m "Update TermGPT to $TAG"
git push

cd - > /dev/null
rm -rf /tmp/homebrew

echo "🎉 Release $NEW_VERSION completed!"