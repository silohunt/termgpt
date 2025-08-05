# Contributing to TermGPT

Thank you for your interest in contributing to TermGPT! This document provides guidelines for contributing to the project.

## How to Contribute

All contributions must be submitted via pull request. Direct commits to the main branch are restricted.

### Process

1. **Fork the repository**
   - Click the "Fork" button on GitHub
   - Clone your fork locally: `git clone https://github.com/YOUR-USERNAME/termgpt.git`

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make your changes**
   - Follow the existing code style (POSIX sh compliance)
   - Test your changes thoroughly
   - Update documentation if needed

4. **Test your changes**
   ```bash
   # Run unit tests
   for test in tests/unit/*.sh; do bash "$test"; done
   
   # Run evaluation tests
   cd tests/evaluation && ./run_focused_evaluation.sh
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Provide a clear description of your changes

## Guidelines

### Code Style
- **POSIX Compliance**: All shell scripts must be POSIX sh compatible (no bash/zsh specific features)
- **Safety First**: Any new commands must be validated against safety rules
- **Platform Awareness**: Consider both macOS and Linux compatibility

### Safety Rules
When adding new safety patterns to `share/termgpt/rules.txt`:
- Use the format: `[SEVERITY] pattern|description`
- Test patterns thoroughly
- Include comments explaining what the pattern catches

### Testing
- All changes must pass existing tests
- Add new tests for new functionality
- Test on both macOS and Linux when possible

### Documentation
- Update README.md if adding new features
- Update man page if changing command syntax
- Include examples in your PR description

## What We're Looking For

### Welcome Contributions
- Additional safety rules for dangerous commands
- Platform-specific optimizations
- Bug fixes with test cases
- Documentation improvements
- Performance optimizations

### Please Discuss First
- Major architectural changes
- New dependencies
- Changes to core behavior
- New features that alter user experience

Open an issue to discuss before starting work on major changes.

## Pull Request Checklist

Before submitting your PR, ensure:

- [ ] Code follows POSIX sh standards
- [ ] All tests pass (`./tests/termgpt-test.sh`)
- [ ] New features have tests
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] PR description explains the changes

## Questions?

If you have questions about contributing, please open an issue for discussion.

Thank you for helping make TermGPT better and safer!