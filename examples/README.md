# Code Examples

**Working scripts and pipelines you can run**

---

## 🎯 How to Use These Examples

Each example is a **complete, runnable script** demonstrating a concept.

**To try:**
```bash
cd examples/
./example-name.sh
```

**To learn:** Read the code. Comments explain each step.

---

## 📁 Examples by Topic

### Bash Fundamentals

#### `01-basic-pipeline.sh`
**Concept:** Pipes and composition  
**What it does:** Find, filter, count files
```bash
# Count .txt files with "error" in name
ls *.txt | grep "error" | wc -l
```

---

#### `02-data-processing.sh`
**Concept:** Text processing with grep/sed/awk  
**What it does:** Extract emails from log files
```bash
# Find unique email addresses in logs
grep -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' *.log \
  | sort | uniq
```

---

#### `03-json-processing.sh`
**Concept:** Working with JSON (jq)  
**What it does:** Extract and filter JSON data
```bash
# Get active users from API
curl -s https://api.example.com/users \
  | jq '.[] | select(.active == true) | {name, email}'
```

---

### Think in Bash

#### `04-bash-accessible-wrapper.sh`
**Concept:** Making Python code bash-accessible  
**What it does:** Wraps complex Python in simple bash interface

**Before (hard for agents):**
```python
python complex_script.py --config config.yaml --verbose --output-dir ./reports
```

**After (agent-friendly):**
```bash
./generate-report.sh monthly
```

---

#### `05-composable-pipeline.sh`
**Concept:** Building workflows from small tools  
**What it does:** Data pipeline with multiple steps

```bash
# Each step does ONE thing
./fetch-data.sh source-api \
  | ./transform-data.py \
  | ./validate-data.sh \
  | ./save-to-db.sh
```

---

#### `06-self-documenting-script.sh`
**Concept:** Scripts that explain themselves  
**What it does:** Includes help, usage, examples

```bash
#!/bin/bash
# Self-documenting script example

usage() {
  cat << EOF
Usage: $0 [options] <input-file>

Options:
  -h, --help     Show this help
  -o, --output   Output file (default: stdout)
  -v, --verbose  Verbose mode

Examples:
  $0 data.csv
  $0 --output result.txt data.csv
EOF
}

# ... rest of script
```

---

### Pi Architecture

#### `07-mini-agent-loop.sh`
**Concept:** Simplified agent while loop  
**What it does:** Shows how Pi's loop works

```bash
#!/bin/bash
# Mini agent that processes files

while true; do
  echo "Agent: What should I do?"
  read -p "You: " task
  
  case "$task" in
    "list files")
      ls -la
      ;;
    "count lines")
      wc -l *.txt
      ;;
    "done")
      break
      ;;
    *)
      # "bash" tool - run anything
      eval "$task"
      ;;
  esac
done
```

---

#### `08-skill-creation.sh`
**Concept:** Agent creating its own tools  
**What it does:** Script that writes and uses other scripts

```bash
#!/bin/bash
# Skill creator example

# Agent creates a new skill
cat > check-disk-space.sh << 'EOF'
#!/bin/bash
df -h | grep -v "tmpfs" | awk '{print $5 " " $6}'
EOF

chmod +x check-disk-space.sh

# Agent uses the skill
./check-disk-space.sh
```

---

### Real-World Workflows

#### `09-podcast-summarizer.sh`
**Concept:** Multi-step workflow  
**What it does:** Download → transcribe → summarize podcast

```bash
#!/bin/bash
# Podcast summarization pipeline

URL="$1"
OUTPUT="${2:-summary.md}"

# Step 1: Download
yt-dlp --write-auto-sub --skip-download "$URL"

# Step 2: Clean transcript
python3 << 'PYEOF'
import re
with open("*.vtt") as f:
    text = f.read()
# ... cleaning logic
PYEOF

# Step 3: Summarize
# (call your LLM here)

# Step 4: Format as markdown
echo "# Podcast Summary" > "$OUTPUT"
echo "**Source:** $URL" >> "$OUTPUT"
cat clean-transcript.txt | your-llm-cli "summarize key points" >> "$OUTPUT"
```

---

#### `10-data-pipeline.sh`
**Concept:** Blake's use case - claims data processing  
**What it does:** Extract → enrich → analyze → report

```bash
#!/bin/bash
# Healthcare data pipeline

START_DATE="$1"
END_DATE="$2"

# Extract claims data
./scripts/extract-claims.sh "$START_DATE" "$END_DATE" > claims-raw.csv

# Enrich with NPI data
cat claims-raw.csv | ./scripts/enrich-npi.py > claims-enriched.csv

# Calculate statistics
cat claims-enriched.csv | ./scripts/calculate-stats.py > stats.json

# Generate HTML report
cat stats.json | ./scripts/generate-report.sh > "report-$START_DATE.html"

echo "Report generated: report-$START_DATE.html"
```

---

#### `11-provider-search.sh`
**Concept:** API integration with bash  
**What it does:** Search providers, format results

```bash
#!/bin/bash
# Provider search tool

SPECIALTY="$1"
LOCATION="$2"

# Call Google Places API
curl -s -G "https://maps.googleapis.com/maps/api/place/textsearch/json" \
  --data-urlencode "query=$SPECIALTY $LOCATION" \
  --data-urlencode "key=$GOOGLE_API_KEY" \
  | jq '.results[] | {
      name: .name,
      address: .formatted_address,
      rating: .rating,
      phone: .formatted_phone_number
    }'
```

---

## 🛠️ Running Examples

### Prerequisites

**Most examples need:**
```bash
brew install jq curl python3 node  # Mac
# or
apt-get install jq curl python3 nodejs  # Linux
```

**Some examples need:**
- OpenAI API key (for LLM calls)
- Google API key (for Places API)
- yt-dlp (for YouTube)

---

### Quick Test

```bash
# Clone or navigate to repo
cd ~/Repo/bash-pi-openclaw-education/examples/

# Try a basic example
./01-basic-pipeline.sh

# Try a more complex one
./04-bash-accessible-wrapper.sh

# Try a real-world workflow
./09-podcast-summarizer.sh "https://youtube.com/watch?v=..."
```

---

## 📝 Creating Your Own

**Template:**
```bash
#!/bin/bash
# example-name.sh - Brief description
#
# What it demonstrates: [concept]
# Usage: ./example-name.sh [args]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Your code here
echo "Hello from example script!"
```

**Best practices:**
- Include usage/help
- Add comments
- Make it self-contained
- Show the concept clearly
- Keep it simple

---

## 🎓 Learning Path

**If new to bash:**
1. Start with `01-basic-pipeline.sh`
2. Move to `02-data-processing.sh`
3. Try `03-json-processing.sh`

**If learning "think in bash":**
1. Study `04-bash-accessible-wrapper.sh`
2. Examine `05-composable-pipeline.sh`
3. Build on `06-self-documenting-script.sh`

**If learning Pi concepts:**
1. Understand `07-mini-agent-loop.sh`
2. See `08-skill-creation.sh`
3. Build your own mini-agent

**If building real systems:**
1. Adapt `09-podcast-summarizer.sh`
2. Modify `10-data-pipeline.sh`
3. Customize `11-provider-search.sh`

---

## 🚀 Next Steps

**After trying examples:**
→ Go to `../exercises/` to practice

**To see real workflows:**
→ Check `../04-openclaw-patterns/` for OpenClaw examples

**To build your own:**
→ Start `../05-building-agents/` project
