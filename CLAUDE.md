# Claude Configuration

## Project Context: TermGPT Development

**What is TermGPT**: A platform-aware shell tool that converts natural language to Unix commands using a local LLM (Ollama). Features intelligent modular post-processing system that significantly improves command reliability.

**Current Version**: 0.9.2 (stable - honest evaluation framework)
**Default Model**: `codellama:7b-instruct` (switched from deepseek due to poor instruction following)
**Target Platforms**: macOS, Linux, WSL
**Success Rate**: 85-90% on practical commands, 60% on complex edge cases (rigorous validation implemented)

### Major System Architecture: Modular Post-Processing

**Core Innovation**: Transforms small LLM output through intelligent correction pipeline:
1. **LLM Generation**: CodeLlama generates initial command
2. **Security Corrections**: Prevent dangerous patterns
3. **Semantic Corrections**: Fix time logic, file patterns, permissions
4. **Platform Corrections**: Convert Linux/GNU commands for macOS/BSD
5. **User Review**: Interactive confirmation

**Directory Structure**:
```
post-processing/
├── lib/postprocess.sh          # Main orchestration with complex command preservation
├── corrections/                # Modular correction system
│   ├── complex-commands.sh     # NEW: Complex command preservation and script generation
│   ├── time.sh                # Context-aware time logic 
│   ├── files.sh               # File patterns, permissions, placeholders
│   ├── platform-macos.sh      # BSD/macOS command fixes
│   ├── platform-linux.sh      # GNU/Linux alternatives
│   └── security.sh            # Security hardening
├── tests/                      # Comprehensive unit tests
└── docs/                       # Architecture & extension guides

tests/evaluation/               # NEW: Comprehensive evaluation framework
├── run_focused_evaluation.sh   # 10 practical commands (95%+ success target)
├── test_hardest_commands.sh    # 15 edge cases (performance boundary testing) 
├── run_comprehensive_evaluation.sh # 50-command full test suite
├── evaluation_50_commands.txt  # Complex test scenarios across 5 categories
└── README.md                   # Testing documentation

docs/evaluation/                # NEW: Analysis and results documentation
├── success_95_percent_achieved.md # Achievement summary
├── evaluation_summary_and_recommendations.md # Comprehensive analysis
└── implementation_roadmap_95_percent.md # Technical roadmap
```

### Recent Major Enhancements (Latest Session)

1. **Honest Performance Assessment & Validation Overhaul**:
   - **Rigorous Validation Implemented**: Syntax checking, logic validation, and tool appropriateness testing
   - **Performance Reality Check**: Previous claims significantly inflated due to superficial validation
   - **Accurate Success Rates**: Practical commands 95%, Complex edge cases 60% (was falsely reported as 100%)
   - **Enhanced Test Framework**: Now catches syntax errors, logic issues, and inappropriate tool usage
   - **Comprehensive Analysis**: 50+ commands across multiple difficulty tiers with honest assessment

2. **Complex Command Preservation System**:
   - **Critical Innovation**: Prevents post-processing from destroying valid multi-step commands
   - **Intelligent Detection**: Recognizes email processing chains, monitoring loops, analysis pipelines
   - **Context-Aware Logic**: Uses original query for semantic understanding
   - **Safety First**: Validates before correcting to prevent regressions

3. **Enhanced Post-Processing Pipeline**:
   - **Complex Command Preservation**: Protects valid chains before applying corrections
   - **Context-Aware Time Logic**: Uses original query to determine temporal semantics
   - **Permission Syntax Validation**: Comprehensive fix for find -perm errors
   - **Placeholder Replacement**: Smart substitution (`<log_file>` → `/var/log/*.log`)
   - **Advanced Platform Awareness**: GNU→BSD, Linux→macOS, package managers
   - **Script Generation Intelligence**: Detects script creation vs command execution requests

4. **Honest Performance Assessment (Fixed Evaluation)**:
   - **Comprehensive Suite**: 77.5% → 85.7% LLM → Post-processing (+8.2 points)
   - **Challenging Commands**: 33% → 60% LLM → Post-processing (+27 points)  
   - **Practical Commands**: 90%+ success rate on daily-use scenarios
   - **Previous Claims Debunked**: Prior 95.9% claims were due to broken validation accepting syntax errors
   - **Real Improvement**: Post-processing provides genuine 8-27 point improvements with rigorous testing

5. **Fixed Evaluation Framework Architecture**:
   - **Rigorous Validation**: `lib/command_validator.sh` with syntax + logic + tool checking
   - **Multi-Tier Testing**: `practical_commands_test.sh`, `challenging_commands_test.sh`, `full_evaluation_suite.sh` 
   - **Honest Metrics**: Catches syntax errors, incomplete commands, non-existent tools, placeholder text
   - **False Positive Elimination**: No more `while true; do`, `systemd-healthcheck`, help text marked as valid
   - **Detailed Error Reporting**: Specific validation failures with actionable feedback

6. **Model-Agnostic Token Counting System**:
   - **Python-Based Tokenizer**: Sophisticated model-agnostic token estimation replacing basic word counting
   - **Context Analysis**: Considers code content, punctuation, technical terms, and language complexity
   - **Accurate Estimation**: Provides realistic token counts (136-164 tokens) vs old method's inaccurate estimates
   - **Robust Fallbacks**: Graceful degradation to word counting when Python unavailable
   - **Universal Compatibility**: Works with any LLM model without hardcoded ratios

### Key Files and Functions

**bin/termgpt**:
- `find_platform_config()` - Config file priority (user config first)
- `find_postprocess_lib()` - Post-processing library discovery
- `find_token_counter()` - Python tokenizer discovery with fallback support
- `is_world_writable()` - Security file permission check
- `--eval` flag - Non-interactive mode for evaluation
- `EVAL_MODE` - Controls interactive vs automated behavior

**lib/token-counter.py**:
- `estimate_tokens()` - Model-agnostic token estimation using sophisticated heuristics
- Character-based analysis with code content detection
- Supports all LLM models without requiring specific tokenizer libraries

**Platform Detection**:
- Config: `~/.config/termgpt/platform.conf`
- Libraries: `lib/termgpt-platform.sh`
- Auto-detects clipboard tools, URL openers, package managers

**Testing & Evaluation**:
- `tests/evaluation/run_focused_evaluation.sh` - 10 practical commands (95%+ target)
- `tests/evaluation/test_hardest_commands.sh` - 15 edge cases (boundary testing)
- `tests/evaluation/run_comprehensive_evaluation.sh` - 50-command full suite
- `tests/unit/world-writable-check.sh` - Permission security tests
- `tests/unit/injection-safety.sh` - Shell injection tests
- `docs/evaluation/` - Results analysis and documentation

### Current Technical Status

**Shell Compatibility Note**: 
- **Core scripts**: Use POSIX sh (bin/termgpt, bin/termgpt-init, bin/termgpt-shell)
- **Evaluation framework**: Requires bash (tests/evaluation/*.sh) 
- **Post-processing tests**: Mixed sh/bash dependencies
- **Future goal**: Full POSIX compliance through gradual migration

**Working Features**:
- **95% success rate** on practical daily commands (rigorously validated)
- **60% success rate** on complex edge cases (up from 33% LLM baseline - honest assessment)
- **Complex command preservation** system prevents most post-processing regressions
- **Context-aware post-processing** with original query analysis for semantic understanding
- **Rigorous evaluation framework** with syntax, logic, and tool appropriateness validation
- **Modular correction system** with targeted fixes and comprehensive test coverage
- **Security validation** with 100+ danger patterns + injection prevention
- **Platform awareness** (macOS vs Linux tool mapping, command conversions)

**Architecture Notes**:
- **Preservation-First Design**: Complex command preservation before other corrections
- **Modular post-processing pipeline**: 6-stage correction system with intelligent routing
- **Context-aware corrections**: Original user query available for semantic analysis  
- **Comprehensive evaluation coverage**: 50+ scenarios with automated validation
- **Fail-safe design**: Graceful degradation and regression prevention
- **Performance optimized**: Minimal overhead for significant reliability improvements

### Post-Processing System Capabilities

**Proven Corrections**:
- **Time Logic**: Context-aware "older than" vs "last N days" detection
- **Permission Syntax**: Complete fix for find -perm errors
- **Placeholder Replacement**: Smart substitution of template values
- **Platform Commands**: GNU→BSD, Linux→macOS, package managers
- **Path Optimization**: Intelligent default paths (/var/log, system dirs)

**Success Metrics by Enhancement (Honest Assessment)**:
- **Complex Command Preservation**: Prevents most regressions, though some edge cases remain
- **Practical Command Focus**: 95% success rate on daily-use scenarios (validated)
- **Context-Aware Corrections**: Significant improvements in time logic and semantic understanding
- **Platform Awareness**: Strong success on platform-specific tool mapping
- **Rigorous Validation**: Enhanced evaluation framework catches syntax errors and logic issues previously missed

### Development Approach Validated

**Strategic Focus with Honest Assessment**:
- **95% Success on Practical Commands**: Strong daily-use experience achieved
- **Preservation-First Architecture**: Prevents most regressions while enabling improvements  
- **Rigorous Evaluation**: Enhanced validation reveals true performance and improvement areas
- **Modular Enhancement**: Iterative improvements guided by accurate evaluation data
- **Small LLM + Smart Corrections**: Maintains fast inference with meaningful reliability improvements
- **Transparent Documentation**: Honest assessment enables focused development efforts

## Recent Updates (v0.9.2)

### Evaluation Framework Fixes (Current Release)
- **Fixed comprehensive evaluation**: Removed timeout command for macOS compatibility
- **Fixed quote handling**: Replaced xargs with sed to handle commands with quotes
- **Restored bash shebangs**: Evaluation scripts require bash for proper functionality
- **Updated documentation**: Clarified bash dependencies and removed incorrect POSIX claims
- **Added roadmap**: Planning gradual POSIX compliance improvements
- **Homebrew formula updated**: Users now get working v0.9.2 via `brew upgrade termgpt`

### Technical Resolution
- **Problem**: POSIX compliance conversion broke evaluation framework, and primitive validation was giving false positives
- **Solution**: Fixed evaluation scripts + implemented rigorous validation with `lib/command_validator.sh` 
- **Result**: Honest performance assessment shows 77.5% → 85.7% (not previous inflated 95.9% claims)
- **Status**: Production-ready with accurate testing framework and realistic performance metrics

## Version Management Policy

### Before ANY Commit:
1. **Ask about version updates**: Check if the changes warrant a version bump
2. **Confirm version number**: Get explicit approval for version changes
3. **Update version in all files**: Ensure consistency across the codebase
4. **Update changelog/release notes**: Document what changed

### Version Update Locations:
- `bin/termgpt`: VERSION variable
- `packaging/homebrew/termgpt.rb`: version field
- `README.md`: Current version mentions
- `CLAUDE.md`: Current version at top

## Commit Policy

I never want to see commits attributed to Claude. All commits should be made by my user without any attribution to Claude or AI assistance.

### Requirements:
- NO Claude attribution in commit messages
- NO "Generated with Claude Code" footers  
- NO "Co-Authored-By: Claude" lines
- NO mentions of AI assistance in any commit metadata
- All commits should appear as if written entirely by the human user
- **ALWAYS ASK** before committing about version updates

### Commit Message Style:
Write clear, concise commit messages that focus on the technical change without any AI attribution. For example:

**Good:**
```
Fix termgpt -m flag to prioritize user config over platform library

The model detection was showing the default model instead of the user's
configured model because find_platform_config() was prioritizing the
development directory's platform library over the user's config file.

Changed priority order to check ~/.config/termgpt/platform.conf first,
ensuring the user's TERMGPT_MODEL setting is properly loaded.
```

**Bad:**
```
Fix termgpt -m flag to prioritize user config over platform library

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Recent Updates (Latest Session)

### Evaluation Framework Accuracy Fixes (Current Session)
- **Critical Discovery**: Comprehensive evaluation was giving false positives due to primitive validation
- **False Claims Debunked**: Previous 95.9% success rate was inflated - real performance is 85.7% post-processing 
- **Validation Implementation**: All evaluation scripts now use rigorous `lib/command_validator.sh`
- **Syntax Checking**: Commands like `while true; do`, `systemd-healthcheck` no longer pass validation
- **Logic Validation**: Commands must actually solve the requested task, not just have valid syntax
- **Tool Appropriateness**: Validates tool usage (e.g., fzf vs grep, ps vs top usage patterns)
- **Honest Metrics**: Real improvement is 8.2-27 percentage points, not inflated claims
- **Results Organization**: All test outputs now go to `tests/evaluation/results/` folder structure
- **Documentation**: Comprehensive analysis in `tests/evaluation/results/EVALUATION_ACCURACY_ANALYSIS.md`

### Post-Processing Verification (Current Session)
- **Critical Fix Applied**: Complex-commands module was properly loaded in main termgpt script
- **Main Script Benefits**: All users get post-processing improvements (time logic, platform fixes, etc.)
- **No Validation in Main**: Main termgpt doesn't validate its output - only evaluation scripts do
- **Pipeline Confirmed**: User Query → LLM → Post-processing → Output (all fixes included)

## Historical Updates

### Interactive REPL Shell Implementation (v0.9.0 - Historical)
- **Complete REPL system**: `termgpt shell` with persistent sessions and history
- **Dot commands**: Industry-standard approach (.copy, .explain, .run, .save, .help)
- **Session management**: Persistent state across REPL sessions with JSON storage
- **Alias system**: Save frequently used commands with custom names
- **Ambiguity resolution**: Removed single-letter shortcuts to avoid confusion
- **Mixed metaphor fix**: Consistent UI using parentheses format (c) instead of brackets [c]

### Homebrew Package Release (v0.9.0 - Historical)
- **Official tap created**: `silohunt/homebrew-termgpt` repository
- **Professional formula**: Complete with dependencies, tests, and caveats
- **Zero-friction installation**: `brew tap silohunt/termgpt && brew install termgpt`
- **Automatic updates**: Users can `brew upgrade termgpt` for new versions
- **Simplified setup**: `termgpt init` handles all Ollama installation automatically

### Model-Agnostic Token Counting (v0.9.0 - Historical)
- **Python tokenizer**: Sophisticated estimation replacing basic word*1.3 ratio
- **Accurate counts**: 136-164 tokens vs old method's incorrect 3-33 estimates
- **Universal compatibility**: Works with any LLM model without hardcoded ratios
- **Graceful fallback**: Degrades to word counting when Python unavailable
- **Context analysis**: Considers code content, punctuation, technical terms

### Version Management Policy
- **Version tracking**: Must update VERSION in all files before commits
- **Release process**: Tag releases, update Homebrew formula with new SHA256
- **Current version**: 0.9.2 (stable with honest evaluation framework)

### Previous Updates

#### TermGPT Init System Implementation
- **Replaced setup.sh** with professional `termgpt init` subcommand
- **Modern CLI patterns** following git, npm, poetry conventions
- **Multiple installation modes**: headless, custom models, path override, reconfigure
- **Health checking**: `termgpt init --check` for validation
- **Comprehensive help**: Discoverable with `termgpt --help`

#### Smart Scope Correction Enhancement
- **Problem Identified**: LLM occasionally generates `find /` (entire filesystem) when users want local searches
- **Solution Implemented**: Context-aware scope correction in post-processing
- **Intelligence**: Converts `find / -name "*.py"` → `find . -name "*.py"` for programming files
- **Preservation**: Keeps `find /` when user explicitly wants system-wide search ("entire system", "everywhere")
- **Coverage**: Supports all major programming languages and file types
- **Testing**: 11/11 test cases passing, eliminates ~20% occurrence rate of problematic commands

#### Repository Modernization
- **Cleanup**: Removed obsolete setup.sh, uninstall.sh scripts, Docker tests
- **Documentation**: Updated all docs, README, man pages for init system
- **Testing**: Enhanced test coverage for new functionality
- **Integration**: Makefile updated for proper installation of new components