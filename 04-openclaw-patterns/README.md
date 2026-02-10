# Module 4: OpenClaw Patterns

**Understanding OpenClaw's conversation flow and architecture**

---

## 🎯 Module Goals

By the end of this module, you'll understand:
- OpenClaw's architecture (Gateway, Sessions, Tools)
- How multi-turn conversations flow
- Tool execution patterns in OpenClaw
- Skills system (similar to Pi)
- Common workflow patterns
- How the podcast summarization workflow actually worked

**Time:** 1-2 hours

---

## 💡 The Key Insight

**OpenClaw = Pi's ideas + Production features**

- Same 4-tool philosophy (read, write, edit, exec)
- Adds: messaging integration, sessions, memory, skills
- Built for real use (not just coding)

---

## 📋 Architecture Overview

```
┌─────────────────────────────────────────┐
│          User (You)                     │
│   Telegram / Webchat / WhatsApp        │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         OpenClaw Gateway                │
│  • Routes messages                      │
│  • Manages sessions                     │
│  • Handles authentication               │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│          Agent Session                  │
│  • While loop (like Pi)                 │
│  • 4 tools + skills                     │
│  • Memory (files + semantic search)     │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│          Your Computer                  │
│  • File system (workspace)              │
│  • Bash commands                        │
│  • Skills (scripts)                     │
└─────────────────────────────────────────┘
```

---

## 📋 Lessons

### 4.1 OpenClaw vs. Pi
**File:** `4.1-openclaw-vs-pi.md`

**Pi:**
- Minimal coding agent harness
- 4 tools only
- Terminal-based
- You run it

**OpenClaw:**
- Pi's core + production features
- 4 tools + skills system
- Multi-surface (Telegram, web, etc.)
- Runs as a service

**Same foundation:** Bash is all you need.

---

### 4.2 Multi-Turn Conversation Flow
**File:** `4.2-multi-turn-flow.md`

**Example:** "Summarize this podcast"

**Turn 1:**
```
You: "Summarize this podcast: [URL]"
  ↓
Agent: [thinks] "I need yt-dlp skill"
  ↓
Tool: read skill docs
  ↓
Agent: [executes] yt-dlp command
```

**Turn 2:**
```
Agent: [thinks] "Got captions, need to clean"
  ↓
Tool: write Python script
  ↓
Tool: exec script
```

**Turn 3:**
```
Agent: [thinks] "Create summary with LLM"
  ↓
Tool: write summary.md
  ↓
Agent: "Done! See summary.md"
```

**Key:** Each turn builds on previous results.

---

### 4.3 Tool Execution in OpenClaw
**File:** `4.3-tool-execution.md`

**OpenClaw's tools:**

1. **read** — `cat file` or list directory
2. **write** — `echo content > file`
3. **edit** — Search/replace or patch
4. **exec** — `bash -c "command"`

**Plus:**
- **memory_search** — Semantic search in memory files
- **browser** — Web automation (optional)
- **message** — Send messages (optional)
- **Skills** — Custom bash scripts

---

### 4.4 Skills System
**File:** `4.4-skills-system.md`

**OpenClaw skills = Pi skills**

Skills are in `/usr/local/lib/node_modules/openclaw/skills/`:
- `github/` — GitHub CLI integration
- `weather/` — Weather data
- `openai-whisper-api/` — Transcription
- Your custom skills...

**Structure:**
```
skill-name/
├── SKILL.md          # Documentation
├── scripts/          # Bash/Python scripts
└── examples/         # Usage examples
```

**Agent can:**
- Read SKILL.md to learn how to use
- Execute scripts in scripts/
- Compose skills together

---

### 4.5 Workflow Patterns
**File:** `4.5-workflow-patterns.md`

**Pattern 1: Read → Process → Write**
```
read(data.json)
  → exec(python process.py)
  → write(output.csv)
```

**Pattern 2: Search → Extract → Format**
```
exec(web-search.sh)
  → exec(extract-data.py)
  → write(formatted-report.md)
```

**Pattern 3: Multi-step pipeline**
```
exec(step1.sh)
  → exec(step2.py)
  → exec(step3.sh)
  → message("Done!")
```

---

### 4.6 Case Study: Podcast Summarization
**File:** `4.6-podcast-case-study.md`

**Your actual workflow breakdown:**

```bash
# What you requested
"Summarize this Syntax podcast about Pi"

# What OpenClaw did (8 turns)
Turn 1: Search for episode (web_fetch)
Turn 2: Find YouTube version (web_fetch)
Turn 3: Extract captions (exec: yt-dlp)
Turn 4: Clean transcript (exec: Python)
Turn 5: Read transcript (read)
Turn 6: Generate summary (LLM)
Turn 7: Create markdown (write)
Turn 8: Create HTML report (write)

# Result
~/openclaw/workspace/podcasts/syntax-976-technical-summary.html
```

**Each tool call = bash command under the hood.**

---

## 🛠️ Hands-On Exercise

**Trace your own workflow:**

1. Open your OpenClaw logs
2. Find a recent multi-turn conversation
3. Map each turn to:
   - What tool was called
   - What bash command ran
   - How it contributed to final result

**Location:** `../exercises/module4/trace-your-workflow.md`

---

## 📊 OpenClaw Directory Structure

```
~/.openclaw/                    # Or ~/openclaw/
├── openclaw.json              # Configuration
└── workspace/                 # Your workspace
    ├── AGENTS.md             # Agent instructions
    ├── SOUL.md               # Persona
    ├── USER.md               # About you
    ├── MEMORY.md             # Long-term memory
    ├── memory/               # Daily notes
    │   └── 2026-02-09.md
    ├── reports/              # Generated reports
    ├── podcasts/             # Your workflow
    └── [your files]
```

**Key insight:** It's all just files. Agents work with files.

---

## 🎓 Knowledge Check

1. **How does OpenClaw differ from Pi?**  
   <details><summary>Answer</summary>Pi = core loop. OpenClaw = Pi + production features (messaging, sessions, memory)</details>

2. **What are OpenClaw's 4 core tools?**  
   <details><summary>Answer</summary>read, write, edit, exec (same as Pi)</details>

3. **Where do skills live?**  
   <details><summary>Answer</summary>`/usr/local/lib/node_modules/openclaw/skills/`</details>

4. **How does memory work?**  
   <details><summary>Answer</summary>Files in workspace (MEMORY.md, memory/*.md) + semantic search</details>

---

## 🚀 Next Steps

**Ready to build?**  
→ Go to `../05-building-agents/` — Create your own workflows

**Want to see code?**  
→ Check `../examples/` for working scripts

---

**Pro tip:** Read your own `workspace/memory/` files to see how OpenClaw documents its work. It's self-documenting through files.
