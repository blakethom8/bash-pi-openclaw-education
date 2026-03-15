# Bash, Pi, and OpenClaw Education

**A hands-on guide to understanding "Bash is all you need" for agentic systems**

---

## 🎯 What You'll Learn

By the end of this guide, you'll understand:
- **Why bash is the universal interface** for agents
- **How to "think in bash"** for building extensible workflows
- **Pi's architecture** — the while loop + 4 tools pattern (pi-mono)
- **OpenClaw's patterns** for multi-turn conversations and enterprise workflows
- **How to build your own agents** using bash and Python
- **How Gemini CLI compares** — what's the same, what's different, what to steal
- **Where agents actually live** — processes, daemons, VMs, containers, sandboxing

---

## 📚 Curriculum Structure

### **Module 1: Bash Fundamentals** (`01-bash-fundamentals/`)
Start here if you're new to bash or rusty on the basics.
- [ ] 1.1 What is Bash? (and why agents love it)
- [ ] 1.2 Core Commands (the ones agents actually use)
- [ ] 1.3 Pipes, Redirects, and Composition
- [ ] 1.4 Exit Codes and Error Handling
- [ ] 1.5 Variables, Loops, and Conditionals
- [ ] 1.6 Scripts vs. One-Liners

**Time:** 1-2 hours

---

### **Module 2: Think in Bash** (`02-think-in-bash/`)
The mental model shift: bash as a universal interface.
- [ ] 2.1 The "Bash is All You Need" Philosophy
- [ ] 2.2 Breaking Problems Into Bash-Solvable Steps
- [ ] 2.3 Composability: Building Blocks → Complex Workflows
- [ ] 2.4 When to Use Bash (vs. specialized tools)
- [ ] 2.5 Making Your Workflows Bash-Accessible
- [ ] 2.6 Real-World Examples (data processing, API calls, file operations)

**Time:** 2-3 hours

---

### **Module 3: Pi Architecture** (`03-pi-architecture/`)
How pi-mono works under the hood. Source: [github.com/badlogic/pi-mono](https://github.com/badlogic/pi-mono)
- [ ] 3.1 The While Loop + 4 Tools Pattern
- [ ] 3.2 Read, Write, Edit, Bash — real behavior, truncation, precision
- [ ] 3.3 How the Agent Decides What to Do Next
- [ ] 3.4 Skills: Extensible, Self-Modifying Code
- [ ] 3.5 Memory Without a Memory System (files as state)
- [ ] 3.6 Pi vs. Claude Code vs. Cursor

**Time:** 2-3 hours

---

### **Module 4: OpenClaw Patterns** (`04-openclaw-patterns/`)
Understanding OpenClaw's conversation flow and architecture.
- [ ] 4.1 OpenClaw vs. Pi (what's added)
- [ ] 4.2 Multi-Turn Conversation Flow
- [ ] 4.3 Tool Execution Patterns
- [ ] 4.4 Skills System (enterprise skill examples)
- [ ] 4.5 Workflow Patterns (5 named patterns)
- [ ] 4.6 Case Study: Podcast Summarization + Monthly Claims Report

**Time:** 2-3 hours

---

### **Module 5: Building Your Own Agents** (`05-building-agents/`)
Hands-on projects with real, runnable code.
- [ ] Project 1: File Organizer Agent (bash, `--dry-run`, logging)
- [ ] Project 2: Data Pipeline Agent (CSV → stats → report, checkpointing)
- [ ] Project 3: Report Generator Agent (JSON → standalone HTML report)
- [ ] Project 4: NPI API Integration Agent (real public API, composable scripts)
- [ ] Project 5: Custom Agent Templates (generic + enterprise-wired)
- [ ] Exercise: CRM CLI (Python argparse, 8 commands, full solution included)

**Time:** 3-4 hours

---

### **Module 6: Gemini CLI Comparison** (`06-gemini-cli-comparison/`)
What Google's Gemini CLI does the same, what it adds, and what to steal.
- [ ] 6.1 Core Architecture — the same loop, one extra line (the approval gate)
- [ ] 6.2 Domain-Native Context — why GCP baked in is their secret sauce
- [ ] 6.3 Production Features — Plan Mode, subagents, checkpointing, MCP, hooks
- [ ] 6.4 What to Steal — DIY equivalents for Pi/OpenClaw users

**Key insight:** Your AGENTS.md with Hetzner/Supabase details IS your "GCP extension."

**Time:** 1-2 hours

---

### **Module 7: Where Agents Live** (`07-where-agents-live/`)
Infrastructure, processes, daemons, VMs, containers, and sandboxing.
- [ ] 7.1 The Agent as a Process (RAM, CPU, filesystem, env vars)
- [ ] 7.2 Daemons and Services (what a daemon is, systemd, OpenClaw as daemon)
- [ ] 7.3 VMs, Containers, and Serverless (when to use each)
- [ ] 7.4 Filesystem Access (permissions, workspace conventions, what can go wrong)
- [ ] 7.5 Sandboxing (5 levers: filesystem, user, network, resources, time limits)
- [ ] 7.6 Enterprise Deployment (Hetzner + Supabase + Azure mapped out)
- [ ] 7.7 Reference Architecture (what lives where, decision guide)

**Key insight:** The LLM runs on Anthropic's servers. Everything else runs on yours.

**Time:** 2-3 hours

---

## 🛠️ How to Use This Repository

### **Prerequisites**
- macOS or Linux terminal
- Basic familiarity with command line (can navigate folders, run commands)
- Python 3 (for Module 5 projects)
- OpenClaw installed (optional but recommended for Module 4)

### **Learning Paths**

**If you're new to bash:**
1. Start with Module 1 → Module 2 → Module 3
2. Run the mini agent loop: `examples/07-mini-agent-loop.sh`
3. Build something in Module 5

**If you know bash basics:**
1. Skip to Module 2 (Think in Bash) → Module 3 (Pi Architecture)
2. Explore OpenClaw patterns (Module 4)
3. Build agents in Module 5

**If you want to understand the infrastructure:**
1. Read Module 3 (Pi Architecture) for the loop
2. Jump to Module 7 (Where Agents Live)
3. Then Module 6 (Gemini CLI) for comparison

**If you want to build enterprise agents now:**
1. Read Module 3 quickly (especially 3.1 and 3.4)
2. Read Module 6.2 (domain-native context)
3. Work through Module 5 projects (real runnable code)

### **Runnable Code**
- `examples/07-mini-agent-loop.sh` — interactive mini Pi demo
- `05-building-agents/project*/agent.sh` — 4 working bash agents
- `exercises/module5-custom-cli/crm.py` — working CRM CLI
- `exercises/module5-custom-cli/solution/crm_full.py` — complete solution

---

## 📖 Quick Reference

| Concept | File | Description |
|---------|------|-------------|
| Bash basics | `01-bash-fundamentals/1.2-core-commands.md` | Essential commands agents use |
| Pi's loop | `03-pi-architecture/3.1-core-loop.md` | The while loop explained |
| Pi's 4 tools | `03-pi-architecture/3.2-four-tools.md` | Read, write, edit, bash — real behavior |
| Skills system | `03-pi-architecture/3.4-skills-system.md` | How to extend without adding tools |
| Multi-turn flow | `04-openclaw-patterns/4.2-multi-turn-flow.md` | How conversations build context |
| Workflow patterns | `04-openclaw-patterns/4.5-workflow-patterns.md` | 5 named enterprise patterns |
| Domain context | `06-gemini-cli-comparison/6.2-domain-native-context.md` | AGENTS.md as your GCP extension |
| Where agents run | `07-where-agents-live/7.7-putting-it-together.md` | Full reference architecture |
| Agent template | `05-building-agents/project5-custom-agent/enterprise-template.sh` | Enterprise starter |

---

## 🎓 Learning Goals by Module

### Module 1: Bash Fundamentals
- Run bash commands confidently, chain with pipes, write scripts, debug exit codes

### Module 2: Think in Bash
- Break problems into bash-solvable steps, design agent-friendly workflows

### Module 3: Pi Architecture
- Explain the while loop + 4 tools, understand skills/memory, compare frameworks

### Module 4: OpenClaw Patterns
- Trace multi-turn conversations, design enterprise workflows, write effective skills

### Module 5: Building Agents
- Build working bash agents, create data pipelines, integrate real APIs (NPI Registry)

### Module 6: Gemini CLI Comparison
- Understand what's the same vs. new, apply domain-native context to your own stack

### Module 7: Where Agents Live
- Explain what a daemon is, choose between VM/container/serverless, sandbox agents safely

---

## 💡 Key Insights

> **"Bash is all you need"**
> If an LLM can use bash competently, it can access **anything** on your system.

> **"The agent is a process"**
> Its capabilities = what that process is allowed to do, on the machine it runs on.

> **"Your AGENTS.md is your GCP extension"**
> Domain-native context (Hetzner, Supabase schemas, naming conventions) is your competitive advantage.

> **"Files are memory"**
> Agents don't need complex memory systems. The file system IS the memory.

> **"4 tools vs 17 tools vs bash"**
> Named tools = precision + structure. Bash = power. You need both.

---

## 📚 Recommended Reading

**Core references:**
- [pi-mono source](https://github.com/badlogic/pi-mono) — the canonical Pi implementation
- [Gemini CLI deep dive](https://codelabs.developers.google.com/gemini-cli-deep-dive) — Google's take on the same pattern

**Alongside learning:**
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)

---

## 🚀 Getting Started

```bash
cd ~/Repo/bash-pi-openclaw-education

# Run the interactive mini-agent demo (5 min)
cd examples/ && ./07-mini-agent-loop.sh

# Or start with the philosophy
open 02-think-in-bash/2.1-philosophy.md

# Or jump straight to building
open 05-building-agents/README.md
```

---

## 📝 Progress Tracker

- [ ] Module 1: Bash Fundamentals
- [ ] Module 2: Think in Bash
- [ ] Module 3: Pi Architecture
- [ ] Module 4: OpenClaw Patterns
- [ ] Module 5: Building Agents
- [ ] Module 6: Gemini CLI Comparison
- [ ] Module 7: Where Agents Live
- [ ] Final Project: Your Own Enterprise Agent

---

**Created:** 2026-02-09 | **Updated:** 2026-03-15
**For:** Blake Thomson

**Let's build agents that actually work.**
