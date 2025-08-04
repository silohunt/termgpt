# Evaluation Tests

This directory contains comprehensive evaluation scripts and test data for measuring TermGPT's post-processing effectiveness.

## Test Scripts

### Primary Evaluation Scripts
- **`run_focused_evaluation.sh`** - Tests 10 representative practical commands (baseline measurement)
- **`test_hardest_commands.sh`** - Tests 15 most challenging edge cases (performance limit testing)
- **`test_critical_fixes.sh`** - Tests specific commands that determine 95% success rate achievement

### Comprehensive Testing
- **`run_comprehensive_evaluation.sh`** - Full 50-command test suite across all categories
- **`run_evaluation.sh`** - Original 30-command evaluation framework

### Utility Scripts
- **`debug_inconsistency.sh`** - Debugs LLM non-determinism and command extraction issues
- **`test_extraction_fix.sh`** - Tests command extraction from TermGPT output
- **`fix_evaluation_extraction.sh`** - Fixes command extraction in evaluation scripts

## Test Data

### Command Sets
- **`evaluation_50_commands.txt`** - 50 complex commands across 5 categories
- **`evaluation_commands.txt`** - Original 30-command test set

## Usage

### Quick Performance Check
```bash
cd tests/evaluation
./run_focused_evaluation.sh
```

### Full Evaluation
```bash
cd tests/evaluation  
./test_hardest_commands.sh
```

### Comprehensive Analysis
```bash
cd tests/evaluation
./run_comprehensive_evaluation.sh
```

## Performance Benchmarks

### Current Results (as of latest evaluation)
- **Focused Commands (Practical)**: 90-100% success rate
- **Hardest Commands (Edge Cases)**: 80-93% success rate  
- **Comprehensive (50 Commands)**: 80-90% success rate

### Success Rate Categories
- **Excellent (95%+)**: Practical daily commands
- **Very Good (85-95%)**: Complex multi-step operations
- **Good (80-85%)**: Extreme edge cases and specialized tools

## Architecture

The evaluation framework tests:
1. **LLM Baseline** (with `TERMGPT_DISABLE_POSTPROCESSING=1`)
2. **Post-Processing Enhanced** (full pipeline)
3. **Command Validation** (syntax, length, error patterns)
4. **Performance Metrics** (success rates, improvement measurements)

Results are used to guide post-processing improvements and validate system reliability.