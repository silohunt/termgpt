# Comprehensive Evaluation Results - 50 Complex Commands

## Test Configuration
- Model: `codellama:7b-instruct`
- Post-processing: Enabled (modular pipeline)
- Test Date: $(date)
- Commands: 50 complex scenarios across 5 categories

## Results Summary

| Category | Commands | LLM Success | Post-Proc Success | Improvement |
|----------|----------|-------------|-------------------|-------------|

### Command 1: System Monitoring & Performance
**Query:** Find all processes consuming more than 500MB of memory and sort by CPU usage

**LLM Result:** $ ps -eo pid,ppid,%mem,%cpu --sort=-%mem | awk 'BEGIN {FS="[ ]+"} $3 > 0.5 && $4 > 0'
**Valid:** ❌ No

**Post-processing Result:** top -o %MEM | grep '^Mem' | awk '{print $2}' | sort -n  
**Valid:** ✅ Yes

**Improvement:** 🔧 Fixed by post-processing

---


### Command 2: System Monitoring & Performance
**Query:** Show network connections from the last hour that are still active, grouped by process

**LLM Result:** netstat -ntu | awk '$4 ~ /[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}/ {print $5 " " $6}' | sort -k 2n | uniq -c | grep -E '^ *[0-9]+ (.*)$' | grep -E '^ *[0-9]+ ' | cut -d ' ' -f2-
**Valid:** ✅ Yes

**Post-processing Result:** sudo netstat -an | awk '$4 ~ /ESTABLISHED/ {print $7}' | sort -u  
**Valid:** ✅ Yes

**Improvement:** No change

---

