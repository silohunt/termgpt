#!/bin/bash

# Fix command extraction in all evaluation scripts
echo "🔧 Fixing Command Extraction in Evaluation Scripts"
echo "=================================================="

# Fix extraction pattern: replace "| xargs 2>/dev/null || echo" with "| sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'"

files_to_fix=(
    "run_focused_evaluation.sh"
    "test_hardest_commands.sh" 
    "test_critical_fixes.sh"
    "run_comprehensive_evaluation.sh"
)

for file in "${files_to_fix[@]}"; do
    if [ -f "$file" ]; then
        echo "Fixing $file..."
        
        # Create backup
        cp "$file" "$file.bak"
        
        # Fix the extraction pattern
        sed -i '' 's/| xargs 2>\/dev\/null || echo ""/| sed '\''s\/^[[:space:]]*\/\/'\'' | sed '\''s\/[[:space:]]*$\/\/'\''/' "$file"
        
        echo "  ✅ Fixed extraction in $file"
    else
        echo "  ⚠️  File $file not found"
    fi
done

echo
echo "🧪 Testing fix with focused evaluation..."
./run_focused_evaluation.sh