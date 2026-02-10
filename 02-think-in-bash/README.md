# Module 2: Think in Bash

**The mental model shift: designing systems agents can operate**

---

## 🎯 Module Goals

This is where it clicks. You'll learn to:
- See problems as **bash-solvable steps**
- Design workflows that are **bash-accessible**
- Understand when bash is (and isn't) the right tool
- Build systems that **agents can extend**

**Time:** 2-3 hours

---

## 💡 The Core Insight

> **"Bash is all you need"** doesn't mean "only use bash."  
> It means: **"Make your workflows accessible through bash."**

**Example:**

**Bad design** (agent can't help):
- Data locked in proprietary database UI
- Complex GUI-only workflows
- APIs that require 50 lines of config

**Good design** (agent-friendly):
```bash
# Simple bash interface
./get-data.sh --source=claims --output=report.csv
```

Agent can now:
- Run your workflow
- Modify it
- Compose it with other tools
- Debug when it breaks

---

## 📋 Lessons

### 2.1 The "Bash is All You Need" Philosophy
**File:** `2.1-philosophy.md`

- Why Pi chose bash (vs. 50 specialized tools)
- The Unix philosophy: small tools, composed
- Extensibility through bash commands
- Real-world examples (OpenClaw, Pi, Cloudbot)

---

### 2.2 Breaking Problems Into Bash-Solvable Steps
**File:** `2.2-problem-decomposition.md`

**Example problem:** "Generate a weekly claims report"

**Non-bash thinking:**
> "I need a report generator tool with templates and SQL integration"

**Bash thinking:**
1. Extract data → `./extract-claims.sh start_date end_date`
2. Process → `cat claims.csv | ./process-claims.py`
3. Generate report → `./generate-report.sh claims-processed.csv`
4. Send → `./email-report.sh report.pdf`

**Why better:** Each step is:
- Testable independently
- Replaceable
- Composable
- Debuggable

---

### 2.3 Composability: Building Blocks → Complex Workflows
**File:** `2.3-composability.md`

**The Agent Mental Model:**

```
Problem
  ↓
Decompose into steps
  ↓
Each step = bash command
  ↓
Chain with pipes/scripts
  ↓
Solution
```

**Real example:** Podcast summarization

```bash
# Not one monolithic tool, but composed steps:
download-podcast.sh "$URL" \
  | transcribe-audio.sh \
  | clean-transcript.py \
  | summarize-with-llm.sh \
  > summary.md
```

Each script:
- Does ONE thing
- Accepts stdin or file
- Outputs to stdout or file
- Can be used alone or composed

---

### 2.4 When to Use Bash (vs. specialized tools)
**File:** `2.4-when-to-use-bash.md`

**Use bash when:**
✅ Gluing tools together  
✅ File operations (read/write/move)  
✅ Simple text processing  
✅ Quick automation  
✅ System tasks

**Don't use bash for:**
❌ Complex data structures (use Python/Node)  
❌ Mathematical computation (use Python/R)  
❌ API-heavy logic (use Python/Node)  
❌ When a specialized tool exists (use jq for JSON, not awk)

**The pattern:**
```bash
# Bash as orchestrator
./fetch-data.sh \
  | python process-complex-data.py \
  | jq '.results[]' \
  | ./save-to-db.sh
```

Bash = glue. Python/jq/etc = specialized processing.

---

### 2.5 Making Your Workflows Bash-Accessible
**File:** `2.5-bash-accessible-design.md`

**Bad:** Locked-in workflow
```python
# run_report.py - requires Python environment, config files, etc.
from mycompany.reports import ReportGenerator
from mycompany.db import Database

config = load_config("config.yaml")
db = Database(config)
generator = ReportGenerator(db)
report = generator.generate("weekly")
report.save()
```

**Good:** Bash-accessible wrapper
```bash
#!/bin/bash
# generate-report.sh

# Set up environment
source venv/bin/activate

# Run with simple interface
python -c "
from mycompany.reports import ReportGenerator
report = ReportGenerator().generate('$1')
print(report)
" > "report-$1.md"
```

Now an agent can:
```bash
./generate-report.sh weekly
./generate-report.sh monthly
cat report-weekly.md | ./email-to-team.sh
```

---

### 2.6 Real-World Examples
**File:** `2.6-real-world-examples.md`

**Example 1: Data Pipeline (Blake's Use Case)**

```bash
# Claims data → Report
./extract-claims-data.sh 2026-01-01 2026-01-31 \
  | ./enrich-with-npi-data.py \
  | ./calculate-statistics.py \
  | ./generate-html-report.sh \
  > reports/2026-01-claims.html
```

**Example 2: Provider Search Tool**

```bash
# Search providers → Format results
./search-providers.sh "cardiologist Los Angeles" \
  | jq '.results[]' \
  | ./format-for-liaison.sh \
  > provider-list.md
```

**Example 3: House Build Tracker**

```bash
# Scrape building department → Notify
./check-permit-status.sh "Orinda" "Blake Thomson" \
  | grep "APPROVED\|DENIED" \
  && ./notify-phone.sh "Permit status updated!"
```

---

## 🛠️ Hands-On Exercise: Redesign a Workflow

**Your task:** Take a manual workflow you do regularly and redesign it bash-style.

**Template:**
```bash
# Step 1: What's the manual process?
# - Open spreadsheet
# - Filter data
# - Copy to email
# - Send

# Step 2: Break into bash steps
# 1. Extract data
# 2. Filter
# 3. Format
# 4. Send

# Step 3: Create bash script
./extract-data.sh source.xlsx \
  | ./filter-rows.py --criteria="active" \
  | ./format-email.sh \
  | ./send-email.sh team@company.com
```

**Location:** `../exercises/module2/redesign-workflow.md`

---

## 📊 Before & After Comparison

### Scenario: Generate healthcare provider report

**Before (Agent can't help):**
1. Open proprietary software
2. Click through menus
3. Export to Excel
4. Copy-paste into Word template
5. Save as PDF
6. Email manually

**After (Agent-friendly):**
```bash
./generate-provider-report.sh \
  --region="Los Angeles" \
  --specialty="Cardiology" \
  --output-format="pdf" \
  --email="team@cedars-sinai.org"
```

**Now agent can:**
- Run it automatically (cron job)
- Modify parameters on the fly
- Chain with other workflows
- Debug if something breaks
- Add features (new filters, formats, etc.)

---

## 🎓 Knowledge Check

After this module, you should be able to:

1. **Identify bash-unfriendly designs**  
   Example: What makes this hard for agents?
   > "Use our web portal to download the report"

2. **Decompose problems into bash steps**  
   Example: How would you break down "analyze sales data"?

3. **Recognize when NOT to use bash**  
   Example: When should you use Python instead?

4. **Design bash-accessible interfaces**  
   Example: Convert a complex Python script into a simple bash command

**Check your answers:** `knowledge-check-answers.md`

---

## 💡 Key Principles

### 1. **Interface, not implementation**
```bash
# Agent sees this:
./process-data.sh input.csv

# Under the hood, it could be:
# - Bash script
# - Python
# - Go binary
# - Docker container
# Doesn't matter — same interface
```

---

### 2. **Composition over monoliths**
```bash
# Don't build:
super-tool --fetch --process --analyze --report

# Build:
fetch.sh | process.sh | analyze.sh | report.sh
```

---

### 3. **Small, focused tools**
Each script:
- Does ONE thing
- Has clear input/output
- Can be tested alone
- Plays well with others

---

### 4. **Discoverable and modifiable**
Agent can:
```bash
ls *.sh              # discover tools
cat fetch.sh         # read implementation
./fetch.sh --help    # learn usage
vim fetch.sh         # modify if needed
```

---

## 🚀 Next Steps

**Ready for Pi?**  
→ Go to `../03-pi-architecture/`

You now understand **how to design for agents**. Module 3 shows you how Pi implements these ideas.

---

**Pro tip:** The best agent workflows are ones you'd be happy using manually. If `./generate-report.sh` is easier than clicking through a GUI, you've designed it right.
