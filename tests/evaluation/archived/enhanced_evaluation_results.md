# Enhanced Post-Processing Evaluation Results

## Test Configuration
- Model: `codellama:7b-instruct`
- Runs per command: 3
- Date: Tue Aug  5 18:33:24 EEST 2025
- Focus: Demonstrating small LLM + post-processing effectiveness

## Key Findings


### Command 1: Find all processes consuming more than 500MB of memory
- LLM Success Rate: 66.6% (2/3)
- Post-Processing Success Rate: 100.0% (3/3)
- Improvement: 33.4 percentage points
- LLM Variation:        3 different commands
- Post-proc Variation:        3 different commands

**LLM Commands:**
- `ps -eo pid,ppid,comm,rsz=size | awk '$4 > 524288000'`
- `ps -eo pid,%mem | awk '$2>500 {print $1}'`
- `$ ps -eo pid,cmd,%mem | awk '$3>0.5'`

**Post-processed Commands:** 
- `ps aux | grep -v "^UID\|Name" | awk '{if ($4 > 500) print $1}' | xargs kill -9`
- `ps -Ao pid,comm,%mem | awk '$3>500{print $1}'`
- `ps -eo pid,command,%mem | grep "^[[:digit:]][[:digit:]]\+" | awk '$2>0.5' | sort -k1 -n`


### Command 2: Show files larger than 1GB modified in the last week
- LLM Success Rate: 100.0% (3/3)
- Post-Processing Success Rate: 100.0% (3/3)
- Improvement: 0 percentage points
- LLM Variation:        3 different commands
- Post-proc Variation:        2 different commands

**LLM Commands:**
- `find . -type f -size +1G -mtime -7`
- `find . -type f -size +1G -mtime -7 -print`
- `find / -type f -size +1G -mtime -7`

**Post-processed Commands:** 
- `find / -type f -size +1G -mtime -7 -ls`
- `find . -type f -size +1G -mtime -7`
- `find / -type f -size +1G -mtime -7 -ls`


### Command 3: List all processes listening on port 80 or 443
- LLM Success Rate: 100.0% (3/3)
- Post-Processing Success Rate: 100.0% (3/3)
- Improvement: 0 percentage points
- LLM Variation:        3 different commands
- Post-proc Variation:        3 different commands

**LLM Commands:**
- `netstat -tulpn | grep LISTEN | grep '80\|443'`
- `netstat -anp | grep ':80\|:443'`
- `lsof -i :80,:443 | grep LISTEN`

**Post-processed Commands:** 
- `lsof -i :80`
- `sudo lsof -i :80 || sudo lsof -i :443`
- `lsof -i :443`

