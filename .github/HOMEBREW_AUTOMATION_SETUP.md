# Homebrew Automation Setup

## Overview

The GitHub Action in `.github/workflows/update-homebrew.yml` automatically updates the Homebrew formula whenever you push a version tag (e.g., `v0.9.4`).

## Setup Required

### 1. Create Personal Access Token (PAT)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Create a new token with these permissions for `silohunt/homebrew-termgpt`:
   - **Contents**: Write (to modify formula file)
   - **Metadata**: Read (to access repo)
   - **Pull requests**: Write (if you want PR-based updates)

### 2. Add Token to Repository Secrets

1. Go to `silohunt/termgpt` repository Settings → Secrets and variables → Actions
2. Add a new repository secret:
   - **Name**: `HOMEBREW_TAP_TOKEN`
   - **Value**: The PAT you created above

## How It Works

1. **Push a version tag**: `git tag v0.9.4 && git push origin v0.9.4`
2. **Action triggers**: Automatically runs when tags matching `v*.*.*` are pushed
3. **Updates formula**: Downloads release tarball, calculates SHA256, updates `termgpt.rb`
4. **Commits changes**: Pushes updated formula to homebrew repository

## Usage

```bash
# Release new version
git tag v0.9.4
git push origin v0.9.4

# That's it! The action handles the rest
```

## Alternative: Manual Script

If you prefer not to use GitHub Actions, here's a script to run locally:

```bash
#!/bin/bash
# update-homebrew.sh
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version> (e.g., 0.9.4)"
    exit 1
fi

VERSION="$1"
TAG="v$VERSION"

echo "Updating Homebrew formula for $TAG..."

# Download and get SHA256
curl -sL "https://github.com/silohunt/termgpt/archive/$TAG.tar.gz" > release.tar.gz
SHA256=$(sha256sum release.tar.gz | cut -d' ' -f1)
rm release.tar.gz

echo "SHA256: $SHA256"

# Clone and update homebrew repo
git clone git@github.com:silohunt/homebrew-termgpt.git temp-homebrew
cd temp-homebrew

# Update formula
sed -i "s|url \".*\"|url \"https://github.com/silohunt/termgpt/archive/$TAG.tar.gz\"|" termgpt.rb
sed -i "s|sha256 \".*\"|sha256 \"$SHA256\"|" termgpt.rb  
sed -i "s|version \".*\"|version \"$VERSION\"|" termgpt.rb

# Commit and push
git add termgpt.rb
git commit -m "Update TermGPT to $TAG

Automated update for release $TAG
SHA256: $SHA256"
git push

# Cleanup
cd ..
rm -rf temp-homebrew

echo "Homebrew formula updated successfully!"
```

## Testing

Test the automation by creating a test tag:
```bash
git tag v0.9.3-test
git push origin v0.9.3-test
```

Then delete it after testing:
```bash
git tag -d v0.9.3-test
git push origin --delete v0.9.3-test
```