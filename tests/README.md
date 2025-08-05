# TermGPT Test Suite

This directory contains all tests for TermGPT, organized by test type:

## Directory Structure

### `/unit/`
Functional unit tests that verify core TermGPT behavior:
- `safety-rules.sh` - Tests dangerous command detection patterns
- `prompt-injection.sh` - Tests LLM prompt injection resistance
- `injection-safety.sh` - Tests shell injection prevention
- `world-writable-check.sh` - Tests file permission security

### `/evaluation/`
Comprehensive evaluation framework with 50+ test scenarios:
- `run_focused_evaluation.sh` - 10 practical commands (95%+ success target)
- `test_hardest_commands.sh` - 15 edge cases (performance boundary testing)
- `run_comprehensive_evaluation.sh` - 50-command full test suite
- `evaluation_50_commands.txt` - Complex test scenarios across 5 categories

### `/integration/` 
Integration tests for system components (planned)

## Running Tests

### Unit Tests
```bash
# Test safety rule patterns
./tests/unit/safety-rules.sh

# Test prompt injection resistance
./tests/unit/prompt-injection.sh

# Test shell injection prevention
./tests/unit/injection-safety.sh

# Test permission security
./tests/unit/world-writable-check.sh
```

### Evaluation Tests
```bash
# Quick performance check (10 practical commands)
cd tests/evaluation && ./run_focused_evaluation.sh

# Edge case testing (15 challenging commands)
cd tests/evaluation && ./test_hardest_commands.sh

# Comprehensive evaluation (50 commands across all categories)
cd tests/evaluation && ./run_comprehensive_evaluation.sh
```

### Full Test Suite
```bash
# Run all unit tests
for test in tests/unit/*.sh; do
  echo "Running $test..."
  bash "$test"
done

# Run evaluation tests
cd tests/evaluation
./run_focused_evaluation.sh
./test_hardest_commands.sh
```

## Test Coverage

### Unit Tests
- **Safety Rules**: Validates regex patterns catch dangerous commands
- **Prompt Injection**: Ensures LLM resists malicious prompt manipulation
- **Shell Injection**: Tests protection against shell injection attacks
- **Permission Security**: Validates file permission checking mechanisms

### Evaluation Framework
- **Performance Validation**: 95%+ success rate on practical daily commands
- **Edge Case Testing**: 80-93% success rate on complex scenarios
- **Multi-Category Coverage**: System, File, Network, Text, and Admin commands
- **Regression Prevention**: Baseline comparison with LLM-only results

### Quality Assurance
- **Post-Processing Pipeline**: Validates intelligent correction system
- **Platform Compatibility**: Tests macOS and Linux specific features
- **Token Counting**: Validates model-agnostic tokenization accuracy
- **REPL Functionality**: Interactive shell mode testing

## Test Results
- **Practical Commands**: 95-100% success rate (validated through focused evaluation)
- **Complex Edge Cases**: 80-93% success rate (comprehensive evaluation)
- **Overall Performance**: 85-95% depending on command complexity
- **Safety Coverage**: 100+ dangerous patterns detected and blocked