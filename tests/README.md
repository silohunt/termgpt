# TermGPT Test Suite

This directory contains all tests for TermGPT, organized by test type:

## Directory Structure

### `/unit/`
Functional unit tests that verify core TermGPT behavior:
- `safety-rules.sh` - Tests dangerous command detection patterns
- `prompt-injection.sh` - Tests LLM prompt injection resistance

### `/container/`
Infrastructure and integration tests using Docker:
- `Dockerfile.alpine` - Alpine Linux container for testing
- `Dockerfile.alpine-local` - Local build testing
- `test-in-container.sh` - Run tests inside containers

## Running Tests

### Unit Tests
```bash
# Test safety rule patterns
./tests/unit/safety-rules.sh

# Test prompt injection resistance
./tests/unit/prompt-injection.sh
```

### Container Tests
```bash
# Build and run tests in Alpine container
cd tests/container

# Option 1: Using test script (recommended)
./test-in-container.sh

# Option 2: Manual Docker commands
# Build the test container
docker build -t termgpt-test -f Dockerfile.alpine .

# Run tests inside container
docker run --rm -it termgpt-test

# Option 3: Test with local development version
docker build -t termgpt-test-local -f Dockerfile.alpine-local ../..
docker run --rm -it -v $(pwd)/../..:/termgpt termgpt-test-local
```

### Full Test Suite
```bash
# Run all unit tests
for test in tests/unit/*.sh; do
  echo "Running $test..."
  bash "$test"
done

# Run container tests
cd tests/container && ./test-in-container.sh
```

## Test Coverage

- **Safety Rules**: Validates regex patterns catch dangerous commands
- **Prompt Injection**: Ensures LLM resists malicious prompt manipulation
- **Cross-Platform**: Container tests verify behavior across different environments

## Container Testing Details

The container tests help ensure TermGPT works correctly across different Linux distributions:

1. **Alpine Linux Test**: Minimal environment to test POSIX compliance
2. **Local Development Test**: Mount local code for rapid iteration
3. **Multi-Platform**: Can extend with Ubuntu, Debian, etc. containers

Container tests verify:
- Installation process works correctly
- Dependencies are properly detected/installed
- Commands work in minimal environments
- Platform detection functions correctly