#!/usr/bin/env python3
"""
Token counter for TermGPT - Model-agnostic token estimation

This script provides accurate token counting without requiring model-specific
tokenizers by using a sophisticated heuristic approach that works well across
different LLM tokenizers (CodeLlama, Qwen, Llama, etc.).

The approach combines multiple factors:
1. Character-based estimation with adjustments
2. Word boundary detection 
3. Code/technical content detection
4. Punctuation and special character handling
5. Language complexity analysis

This gives much more accurate results than simple word counting while
remaining dependency-free and model-agnostic.
"""

import sys
import re
import string


def estimate_tokens(text):
    """
    Estimate token count using sophisticated heuristics that work well
    across different LLM tokenizers without requiring model-specific libraries.
    
    Args:
        text (str): Input text to tokenize
        
    Returns:
        int: Estimated token count
    """
    if not text:
        return 0
    
    # Base character count
    char_count = len(text)
    
    # Start with character-based estimation (most tokenizers: ~3.5-4.5 chars/token)
    base_estimate = char_count / 4.0
    
    # Adjustment factors
    adjustment_factor = 1.0
    
    # 1. Word boundary factor
    # More spaces/boundaries typically mean more tokens
    word_count = len(text.split())
    if word_count > 0:
        avg_word_length = char_count / word_count
        if avg_word_length < 4:  # Short words = more tokens
            adjustment_factor *= 1.15
        elif avg_word_length > 8:  # Long words = fewer tokens  
            adjustment_factor *= 0.9
    
    # 2. Code and technical content detection
    code_indicators = [
        r'[{}();[\]]',  # Code brackets and syntax
        r'[=<>!]+',     # Operators
        r'[-_./\\]',    # Technical separators
        r'\$\w+',       # Shell variables
        r'--?\w+',      # Command flags
    ]
    
    code_matches = sum(len(re.findall(pattern, text)) for pattern in code_indicators)
    code_density = code_matches / len(text) if text else 0
    
    if code_density > 0.1:  # High code content
        adjustment_factor *= 1.2  # Code tends to have more tokens per character
    
    # 3. Punctuation density
    punct_count = sum(1 for c in text if c in string.punctuation)
    punct_density = punct_count / len(text) if text else 0
    
    if punct_density > 0.15:  # High punctuation
        adjustment_factor *= 1.1
    
    # 4. Special character handling
    special_chars = len(re.findall(r'[^\w\s]', text))
    if special_chars > char_count * 0.2:  # Lots of special chars
        adjustment_factor *= 1.15
    
    # 5. Repeated patterns (common in prompts)
    # Detect repeated words or phrases that might be tokenized efficiently
    words = text.lower().split()
    if len(words) > 10:
        unique_words = len(set(words))
        repetition_ratio = len(words) / unique_words
        if repetition_ratio > 1.5:  # Lots of repetition
            adjustment_factor *= 0.95  # Slightly fewer tokens due to repetition
    
    # 6. Language complexity
    # Simple heuristic: lots of common English words = standard tokenization
    common_words = {'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 
                   'of', 'with', 'by', 'is', 'are', 'was', 'were', 'have', 'has'}
    
    if word_count > 5:
        common_word_ratio = sum(1 for word in words if word.lower() in common_words) / word_count
        if common_word_ratio > 0.3:  # Lots of common words
            adjustment_factor *= 0.95  # Standard English tokenizes efficiently
    
    # Apply adjustments
    final_estimate = base_estimate * adjustment_factor
    
    # Reasonable bounds (most tokenizers fall in this range)
    min_estimate = char_count / 6.0  # Very efficient tokenization
    max_estimate = char_count / 2.5  # Very inefficient tokenization
    
    final_estimate = max(min_estimate, min(max_estimate, final_estimate))
    
    return int(round(final_estimate))


def main():
    """Main function for command line usage"""
    if len(sys.argv) != 2:
        print("Usage: python3 token-counter.py '<text>'", file=sys.stderr)
        sys.exit(1)
    
    text = sys.argv[1]
    token_count = estimate_tokens(text)
    print(token_count)


if __name__ == "__main__":
    main()