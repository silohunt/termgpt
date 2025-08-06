# TermGPT Evaluation Directory Structure

## Overview
```
tests/evaluation/
├── README.md                           # Main documentation
├── DIRECTORY_STRUCTURE.md              # This file
├── 
├── Core Test Scripts/
├── practical_commands_test.sh          # 10 daily-use commands (Target: 95%+)
├── challenging_commands_test.sh        # 15 hardest edge cases (Target: 60%+) 
├── full_evaluation_suite.sh            # Complete 50+ command test suite
├── llm_consistency_analysis.sh         # LLM variation analysis (cleaned)
├── 
├── Test Data/
├── test_scenarios_50_commands.txt      # Command test scenarios
├── 
├── Support Libraries/
├── lib/
│   └── command_validator.sh            # Rigorous command validation
├── 
├── Organization/
├── results/                            # Future test results (empty)
└── archived/                           # Historical results and deprecated files
    ├── comprehensive_evaluation_results.md
    ├── comprehensive_results.txt
    └── enhanced_evaluation_results.md
```

## File Descriptions

### Core Test Scripts

**`practical_commands_test.sh`** (formerly `run_focused_evaluation.sh`)
- Tests 10 representative commands users run daily
- Target: 95%+ success rate
- Purpose: Validate daily-use reliability
- Run time: ~30 seconds

**`challenging_commands_test.sh`** (formerly `test_hardest_commands.sh`)  
- Tests 15 extremely challenging edge cases
- Target: 60%+ success rate (up from 33% LLM baseline)
- Purpose: Stress test and identify improvement areas
- Run time: ~60 seconds

**`full_evaluation_suite.sh`** (formerly `run_comprehensive_evaluation.sh`)
- Complete test suite with 50+ commands across 5 categories
- Purpose: Overall system assessment and regression detection
- Run time: ~3-5 minutes

**`llm_consistency_analysis.sh`** (formerly `analyze_llm_variations.sh`)
- Analyzes LLM output variations by running same query multiple times  
- Purpose: Understand consistency and post-processing effectiveness
- Cleaned version without emojis/claims, pure data output

### Support Files

**`lib/command_validator.sh`**
- Rigorous validation: syntax, logic, tool appropriateness
- Catches real issues previous validation missed
- Used by all test scripts for accurate assessment

**`test_scenarios_50_commands.txt`** (formerly `evaluation_50_commands.txt`)
- Test command scenarios organized by category
- Used by comprehensive evaluation suite

### Organization

**`results/`** - Current test results and reports
- `comprehensive_evaluation_results.md` - Full suite results (50+ commands)
- `practical_commands_results.md` - Daily-use command results (10 commands)  
- `challenging_commands_results.md` - Edge case results (15 hard commands)
- `llm_consistency_analysis.md` - LLM variation analysis results

**`archived/`** - Historical results when evaluation was less rigorous

## Quick Start

```bash
# Quick daily-use test
./practical_commands_test.sh

# Stress test with hard cases
./challenging_commands_test.sh  

# Full comprehensive evaluation
./full_evaluation_suite.sh

# Check LLM consistency
./llm_consistency_analysis.sh
```

## Changes Made This Session

### Critical Validation Fixes
- **All evaluation scripts** now use `lib/command_validator.sh` for rigorous validation
- **False positive elimination**: No more `while true; do`, `systemd-healthcheck` marked as valid  
- **Honest performance metrics**: Real improvement is 8.2-27 percentage points, not inflated claims
- **Results organization**: Structured output to `results/` folder with detailed analysis

### File Renames (for clarity)
- `run_focused_evaluation.sh` → `practical_commands_test.sh`
- `test_hardest_commands.sh` → `challenging_commands_test.sh`
- `run_comprehensive_evaluation.sh` → `full_evaluation_suite.sh` 
- `analyze_llm_variations.sh` → `llm_consistency_analysis.sh`
- `evaluation_50_commands.txt` → `test_scenarios_50_commands.txt`

### New Documentation
- `EVALUATION_ACCURACY_ANALYSIS.md` - Comprehensive analysis of false positive issues
- `VALIDATION_FIXES.md` - Technical details of validation improvements
- Updated `README.md` with honest performance assessment

### Archived Files  
- Old evaluation results moved to `archived/` folder
- These represent results from when validation was broken

## Current Validation (Rigorous)

All test scripts now use enhanced validation that checks:
- **Syntax**: Shell parsing with `sh -n`, catches quote errors, incomplete loops
- **Logic**: Commands must actually solve the requested task
- **Tools**: Validates appropriate tool usage (fzf vs grep, ps vs top)
- **Completeness**: Rejects placeholders, help text, incomplete responses
- **Tool Existence**: Checks if tools actually exist on system

This provides **honest assessment** instead of **inflated success rates**.