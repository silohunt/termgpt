# TermGPT Release Process

## Overview

TermGPT uses semantic versioning (X.Y.Z) and automated Homebrew formula updates via GitHub Actions.

## Prerequisites

- Ensure all changes are committed
- Verify tests pass: `./bin/termgpt --eval "list files"`
- You must have push access to the main repository

## Release Steps

### 1. Update Version Numbers

Run the release script with the new version:

```bash
./scripts/release.sh 0.9.5
```

This updates version strings in:
- `bin/termgpt`
- `bin/termgpt-init` 
- `bin/termgpt-shell`
- `README.md`
- `docs/shell-mode.md`

### 2. Review Changes

Verify the version updates look correct:

```bash
git diff
./bin/termgpt --version  # Should show new version
```

### 3. Commit and Tag

```bash
git add -A
git commit -m "Release v0.9.5"
git tag v0.9.5
```

### 4. Push to GitHub

```bash
git push origin main --tags
```

### 5. Automated Homebrew Update

Once the tag is pushed, GitHub Actions automatically:
1. Downloads the release tarball
2. Calculates SHA256 hash
3. Updates the Homebrew formula in `silohunt/homebrew-termgpt`
4. Commits and pushes the formula update

You can monitor the action at: https://github.com/silohunt/termgpt/actions

### 6. Create GitHub Release (Optional)

1. Go to https://github.com/silohunt/termgpt/releases
2. Click "Draft a new release"
3. Select your tag (e.g., v0.9.5)
4. Add release notes describing changes
5. Publish release

## Version Numbering Guidelines

- **Major (X.0.0)**: Breaking changes, major architecture updates
- **Minor (0.X.0)**: New features, significant improvements
- **Patch (0.0.X)**: Bug fixes, minor improvements, documentation updates

## Rollback Process

If something goes wrong after release:

```bash
# Delete remote tag
git push --delete origin v0.9.5

# Delete local tag
git tag -d v0.9.5

# Revert commits if needed
git revert HEAD

# Fix issues and re-release
```

## Notes

- The `HOMEBREW_TAP_TOKEN` secret must be configured in GitHub for automatic updates
- Version consistency is critical - always use the release script
- Test the release locally before pushing tags
- Homebrew users will get updates automatically via `brew upgrade`

## Quick Reference

Complete release in one line (after running release.sh):

```bash
git add -A && git commit -m "Release v0.9.5" && git tag v0.9.5 && git push origin main --tags
```