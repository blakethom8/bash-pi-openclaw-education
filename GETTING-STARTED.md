# Getting Started: Your First 30 Minutes

**Welcome! Let's get you oriented.**

---

## 🎯 What This Repository Is

A **hands-on educational guide** to understanding:
1. How agents think (in bash primitives)
2. How to design agent-friendly workflows
3. How Pi and OpenClaw actually work
4. How to build your own agents

**Not** just a bash tutorial. This is about **thinking like an agent**.

---

## 📍 You Are Here

```
bash-pi-openclaw-education/
├── README.md              ← Start here (overview)
├── QUICKSTART.md          ← Fast path (15 min)
├── GETTING-STARTED.md     ← You are here
│
├── 01-bash-fundamentals/  ← Learn bash basics
├── 02-think-in-bash/      ← Mental model shift ⭐
├── 03-pi-architecture/    ← How Pi works ⭐
├── 04-openclaw-patterns/  ← OpenClaw specifics
├── 05-building-agents/    ← Build your own
│
├── examples/              ← Working code
├── exercises/             ← Practice problems
└── notebooks/             ← Interactive (Jupyter)
```

---

## 🚀 Your First 30 Minutes

### Minutes 0-10: Understand Why

**Read this ONE file:**
```bash
open 02-think-in-bash/2.1-philosophy.md
```

**You'll learn:**
- Why "bash is all you need" for agents
- Why Pi chose 4 tools (not 50)
- How this changes everything

**Key quote:**
> "If an LLM can use bash competently, it can access **anything** on your system. No need for 50 specialized tools."

---

### Minutes 10-20: See How It Works

**Run this ONE script:**
```bash
cd examples/
./07-mini-agent-loop.sh
```

**Try these commands:**
```
You: list
You: read README.md
You: bash echo "Hello from agent!"
You: quit
```

**You'll see:** A simplified agent loop in action (read/write/bash tools).

---

### Minutes 20-30: Apply to Your Work

**Read this ONE file:**
```bash
open 02-think-in-bash/2.6-real-world-examples.md
```

**You'll see:**
- Data pipeline (your claims data use case)
- Provider search (your current project)
- House build tracking (your personal project)

All redesigned as bash-accessible workflows.

---

## 🎓 What You'll Understand

### The Core Insight

**Traditional thinking:**
> "I need a specialized tool for each task: report generator, data processor, API client..."

**Agent thinking:**
> "I need bash-accessible interfaces. Then I can compose anything."

### The Pattern

```
Complex Problem
  ↓
Break into steps
  ↓
Each step = bash command
  ↓
Chain together
  ↓
Solution
```

### The Trade-off

**You trade:**
- GUI convenience
- Point-and-click ease
- "Just works" tools

**You gain:**
- Automation (agents can run it)
- Composition (mix and match)
- Extensibility (infinitely customizable)
- Transparency (you can see what's happening)

---

## 🛠️ Three Learning Paths

### Path 1: "Teach me everything" (6-8 hours)

```bash
# Module 1: Bash Fundamentals (2 hours)
open 01-bash-fundamentals/README.md

# Module 2: Think in Bash (2 hours) ⭐
open 02-think-in-bash/README.md

# Module 3: Pi Architecture (2 hours) ⭐
open 03-pi-architecture/README.md

# Module 4: OpenClaw Patterns (1 hour)
open 04-openclaw-patterns/README.md

# Module 5: Build Your Own (2 hours)
open 05-building-agents/README.md
```

**Best for:** Comprehensive understanding, building foundation.

---

### Path 2: "I know bash, teach me agents" (3-4 hours)

```bash
# Skip Module 1, start here:
open 02-think-in-bash/README.md

# Then:
open 03-pi-architecture/README.md

# Then build:
open 05-building-agents/README.md
```

**Best for:** Developers familiar with command line.

---

### Path 3: "Show me NOW" (1 hour)

```bash
# Read the philosophy (15 min)
open 02-think-in-bash/2.1-philosophy.md

# See real examples (15 min)
open 02-think-in-bash/2.6-real-world-examples.md

# Run working code (15 min)
cd examples/
./07-mini-agent-loop.sh
cat 10-data-pipeline.sh

# Adapt to your needs (15 min)
# Copy example, modify for your use case
```

**Best for:** Immediate practical application.

---

## 📖 Must-Read Files

If you only read **3 files**, make them these:

### 1. `02-think-in-bash/2.1-philosophy.md`
**Why bash?** The foundation of everything.

**Key insight:**
> Agents don't need 50 tools. They need bash (which can call anything).

---

### 2. `03-pi-architecture/3.2-four-tools.md`
**How Pi works** with just 4 tools.

**Key insight:**
> read + write + edit + bash = infinite extensibility

---

### 3. `02-think-in-bash/2.5-bash-accessible-design.md`
**How to design** agent-friendly workflows.

**Key insight:**
> Make your workflows accessible through bash, and agents can help.

---

## 🎯 Your Goal

**By the end of this guide:**

You should be able to look at any workflow and think:

> "How would I break this into bash-accessible steps that an agent could run?"

**That's the skill that unlocks agentic systems.**

---

## 💡 Key Concepts (Quick Reference)

### 1. Bash is the Universal Interface
Agents use bash because it can:
- Run any program (Python, Node, etc.)
- Process files (read, write, edit)
- Call APIs (curl)
- Access databases
- Control systems

---

### 2. Composition > Monoliths
**Bad:** One giant tool that does everything

**Good:** Small tools that compose
```bash
fetch.sh | process.py | analyze.sh | report.sh
```

---

### 3. Four Tools Are Enough
Pi agents use:
1. Read files
2. Write files
3. Edit files
4. Execute bash

Everything else = composition of these.

---

### 4. Files = Memory
No complex vector DB needed:
```bash
# Remember something
echo "User prefers Python" >> memory/prefs.txt

# Recall later
grep "Python" memory/prefs.txt
```

---

### 5. Self-Modifying Code
Agents can create their own tools:
```bash
# Agent writes this
cat > my-tool.sh << 'EOF'
#!/bin/bash
# custom functionality
EOF

chmod +x my-tool.sh

# Agent uses it
./my-tool.sh
```

---

## 🚀 Next Steps

**Option 1: Deep dive**
→ Read full curriculum: `README.md`

**Option 2: Quick start**
→ Fast path: `QUICKSTART.md`

**Option 3: Code now**
→ See examples: `examples/README.md`

**Option 4: Practice**
→ Do exercises: `exercises/`

---

## 🎓 Success Criteria

You'll know you "get it" when:

✅ You can explain why Pi only needs 4 tools  
✅ You see a manual workflow and think "how do I bash-ify this?"  
✅ You design systems as composable bash scripts  
✅ You understand why agents love file operations  
✅ You can build a simple agent loop yourself

---

## 💬 Questions?

**"Why bash and not Python?"**  
→ Read: `02-think-in-bash/2.1-philosophy.md`

**"How does Pi actually work?"**  
→ Read: `03-pi-architecture/3.1-core-loop.md`

**"How do I apply this to my work?"**  
→ Read: `02-think-in-bash/2.6-real-world-examples.md`

**"Can I see working code?"**  
→ Check: `examples/` directory

---

## 🎯 Ready?

Pick your path:
- **Learn everything:** `README.md`
- **Fast track:** `QUICKSTART.md`
- **Code first:** `examples/README.md`
- **Practice:** `exercises/`

**Let's build agents that actually work.** 🚀

---

**Created:** 2026-02-09  
**For:** Blake Thomson  
**Source:** Syntax 976 podcast insights + Pi/OpenClaw architecture
