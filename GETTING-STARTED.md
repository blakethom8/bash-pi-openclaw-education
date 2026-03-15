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
├── 03-pi-architecture/    ← How Pi works ⭐ (pi-mono)
├── 04-openclaw-patterns/  ← OpenClaw specifics
├── 05-building-agents/    ← Build your own (real code)
├── 06-gemini-cli-comparison/ ← Gemini CLI vs Pi/OpenClaw
├── 07-where-agents-live/  ← VMs, daemons, sandboxing ⭐
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

### The Infrastructure Reality

The LLM (Claude, Gemini) runs on Anthropic's/Google's servers. Everything else — your agent loop, your files, your bash commands — runs on **your machine**. Module 7 unpacks exactly what this means.

---

## 🛠️ Four Learning Paths

### Path 1: "Teach me everything" (10-12 hours)

```bash
open 01-bash-fundamentals/README.md   # Bash basics (2 hrs)
open 02-think-in-bash/README.md       # Mental model (2 hrs) ⭐
open 03-pi-architecture/README.md     # Pi internals (2 hrs) ⭐
open 04-openclaw-patterns/README.md   # OpenClaw (2 hrs)
open 05-building-agents/README.md     # Build agents (3 hrs)
open 06-gemini-cli-comparison/README.md  # Compare (1 hr)
open 07-where-agents-live/README.md   # Infrastructure (2 hrs)
```

**Best for:** Comprehensive understanding, building a solid foundation.

---

### Path 2: "I know bash, teach me agents" (4-5 hours)

```bash
open 02-think-in-bash/2.1-philosophy.md   # Why bash for agents
open 03-pi-architecture/README.md          # The loop + 4 tools ⭐
open 04-openclaw-patterns/README.md        # Production patterns
open 05-building-agents/README.md          # Build something real
open 07-where-agents-live/README.md        # Where does it run?
```

**Best for:** Developers familiar with the command line.

---

### Path 3: "Enterprise agent focus" (3-4 hours)

```bash
open 03-pi-architecture/3.1-core-loop.md          # The loop
open 03-pi-architecture/3.4-skills-system.md       # How to extend
open 04-openclaw-patterns/4.5-workflow-patterns.md # 5 named patterns
open 06-gemini-cli-comparison/6.2-domain-native-context.md  # Your AGENTS.md
open 07-where-agents-live/7.6-enterprise-deployment.md      # Deploy it
```

Then run the projects:
```bash
cd 05-building-agents/project2-data-pipeline/
./agent.sh tests/sample-data.csv

cd ../project4-api-integration/
./agent.sh "cardiology" --mock
```

**Best for:** Building reporting/pipeline agents for corporate use.

---

### Path 4: "Show me NOW" (30 min)

```bash
# See the philosophy (5 min)
open 02-think-in-bash/2.1-philosophy.md

# Run a working agent (10 min)
cd examples/ && ./07-mini-agent-loop.sh

# Run a real project (15 min)
cd 05-building-agents/project1-file-organizer/
./agent.sh . --dry-run
```

**Best for:** Immediate hands-on exploration.

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
✅ You can explain what a daemon is and why OpenClaw runs as one
✅ You know what your AGENTS.md should contain for your infrastructure
✅ You can answer: "where does the RAM get used when my agent runs?"

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
