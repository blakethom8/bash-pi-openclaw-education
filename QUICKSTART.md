# Quick Start Guide

**Get up and running in 15 minutes**

---

## 🚀 For the Impatient

**Want to jump straight to building?**

```bash
cd ~/Repo/bash-pi-openclaw-education

# Read the philosophy (5 min)
open 02-think-in-bash/2.1-philosophy.md

# See how Pi works (5 min)
open 03-pi-architecture/3.2-four-tools.md

# Try an example (5 min)
cd examples/
./07-mini-agent-loop.sh
```

Done. You now understand the core concepts.

---

## 📚 Three Learning Paths

### Path 1: "I'm new to bash"

**Time:** 2-3 hours

1. **Module 1:** Bash Fundamentals
   - Read: `01-bash-fundamentals/1.2-core-commands.md`
   - Read: `01-bash-fundamentals/1.3-pipes-and-composition.md`
   - Try: `examples/01-basic-pipeline.sh`

2. **Module 2:** Think in Bash
   - Read: `02-think-in-bash/2.1-philosophy.md`
   - Try: `examples/04-bash-accessible-wrapper.sh`

3. **Module 3:** Pi Architecture
   - Read: `03-pi-architecture/README.md`
   - Try: `examples/07-mini-agent-loop.sh`

---

### Path 2: "I know bash, teach me the agent stuff"

**Time:** 1-2 hours

1. **Skip to Module 2:**
   - Read: `02-think-in-bash/2.1-philosophy.md` (why bash for agents)
   - Read: `02-think-in-bash/2.2-problem-decomposition.md` (how to think)
   - Read: `02-think-in-bash/2.5-bash-accessible-design.md` (design patterns)

2. **Module 3: Pi Architecture**
   - Read: `03-pi-architecture/3.1-core-loop.md` (how Pi works)
   - Read: `03-pi-architecture/3.2-four-tools.md` (the 4 tools)
   - Read: `03-pi-architecture/3.4-skills-system.md` (extensibility)

3. **Try it:**
   - Run: `examples/07-mini-agent-loop.sh`
   - Run: `examples/08-skill-creation.sh`

---

### Path 3: "Show me real-world examples NOW"

**Time:** 30 minutes

1. **Read these three:**
   - `02-think-in-bash/2.1-philosophy.md` — Why bash matters
   - `02-think-in-bash/2.6-real-world-examples.md` — Applied examples
   - `03-pi-architecture/3.2-four-tools.md` — Pi's interface

2. **Run these:**
   ```bash
   cd examples/
   
   # Podcast summarizer
   cat 09-podcast-summarizer.sh
   
   # Data pipeline (your use case)
   cat 10-data-pipeline.sh
   
   # Provider search
   cat 11-provider-search.sh
   ```

3. **Adapt one to your needs**

---

## 🎯 Key Concepts (TL;DR)

### 1. Bash is All You Need

> If an agent can use bash, it can do anything on your computer.

**Why?** Bash can:
- Run Python/Node/any program
- Process files (read/write/edit)
- Call APIs (curl)
- Access databases
- Control Docker
- Literally everything

---

### 2. Four Tools Are Enough

Pi agents use **only 4 tools:**
1. Read files
2. Write files
3. Edit files
4. Execute bash commands

Everything else is composition.

---

### 3. Composability > Monoliths

**Bad:**
```python
super_tool --fetch --process --analyze --report
```

**Good:**
```bash
fetch.sh | process.py | analyze.sh | report.sh
```

Each script does ONE thing. Agents compose them.

---

### 4. Make It Bash-Accessible

**Agent-unfriendly:**
> "Log into our web portal, click Export, save CSV, open in Excel..."

**Agent-friendly:**
```bash
./get-data.sh --source=api --output=data.csv
```

Same result, but agent can now run it.

---

## 🛠️ Hands-On Challenges

### Challenge 1: Count Errors

**Task:** Create a script that counts "ERROR" lines in log files.

<details>
<summary>Solution</summary>

```bash
#!/bin/bash
# count-errors.sh
grep -c "ERROR" "$1"
```

Usage:
```bash
./count-errors.sh app.log
```
</details>

---

### Challenge 2: Process JSON

**Task:** Extract names from JSON users array.

**Input (`users.json`):**
```json
{"users": [
  {"name": "Blake", "active": true},
  {"name": "Devon", "active": true}
]}
```

<details>
<summary>Solution</summary>

```bash
cat users.json | jq '.users[] | .name'
```
</details>

---

### Challenge 3: Build a Pipeline

**Task:** Find all Python files, count total lines.

<details>
<summary>Solution</summary>

```bash
find . -name "*.py" | xargs wc -l | tail -1
```
</details>

---

## 📖 Essential Reading

**Must-read files:**

1. **`02-think-in-bash/2.1-philosophy.md`**  
   Why "bash is all you need" (15 min)

2. **`03-pi-architecture/3.2-four-tools.md`**  
   How Pi works with just 4 tools (10 min)

3. **`02-think-in-bash/2.5-bash-accessible-design.md`**  
   How to design agent-friendly systems (15 min)

**Total:** 40 minutes to understand the core concepts.

---

## 🎓 What You'll Learn

### After Module 1 (Bash Fundamentals):
✅ Run bash commands confidently  
✅ Chain commands with pipes  
✅ Process text and JSON  
✅ Write simple scripts

### After Module 2 (Think in Bash):
✅ Break problems into bash steps  
✅ Design agent-friendly workflows  
✅ Know when to use bash vs. Python  
✅ Make your work bash-accessible

### After Module 3 (Pi Architecture):
✅ Understand how agent loops work  
✅ See why 4 tools are enough  
✅ Know how skills extend functionality  
✅ Design self-modifying systems

### After Module 5 (Building Agents):
✅ Build your own mini-agent  
✅ Create bash-accessible workflows  
✅ Design data pipelines  
✅ Apply to your actual work (claims data, reports, etc.)

---

## 🚀 Next Steps

**Option 1: Start learning**
```bash
open 01-bash-fundamentals/README.md
```

**Option 2: Jump to concepts**
```bash
open 02-think-in-bash/README.md
```

**Option 3: See examples**
```bash
cd examples/
ls *.sh
```

**Option 4: Build something**
```bash
open 05-building-agents/README.md
```

---

## 💡 Pro Tips

### Tip 1: Don't memorize commands
Agents don't memorize either — they look things up. Learn the **patterns**, not the syntax.

### Tip 2: Build incrementally
Start with `cat file.txt`, add one pipe at a time: `| grep "text"`, `| sort`, etc.

### Tip 3: Make scripts self-documenting
Include `--help`, usage examples, and comments. Future-you will thank you.

### Tip 4: Test each step
Run each command separately before chaining. Easier to debug.

### Tip 5: Keep it simple
If you can't explain the pipeline in one sentence, break it down further.

---

## 🎯 Your Goal

By the end of this guide, you should be able to:

> "Take any manual workflow and redesign it as a bash-accessible pipeline that agents can run, modify, and extend."

**That's the skill that unlocks agentic systems.**

---

**Ready?** Pick a path above and start learning.

**Questions?** Read the relevant module README.

**Stuck?** Check the examples/ folder for working code.

**Let's build.** 🎯
