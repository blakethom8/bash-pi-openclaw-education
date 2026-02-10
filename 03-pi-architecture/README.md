# Module 3: Pi Architecture

**Understanding how Pi works under the hood**

---

## 🎯 Module Goals

By the end of this module, you'll understand:
- Pi's **while loop + 4 tools** pattern
- How the agent decides what to do next
- How skills extend functionality
- Why Pi is **minimal yet infinitely extensible**
- How Pi compares to other coding agents

**Time:** 1-2 hours

---

## 💡 The Core Concept

> "Pi is a while loop that calls an LLM with four tools. The LLM gives back tool calls or not and that's it."  
> — Armin Ronacher

---

## 📋 Architecture Overview

```
┌─────────────────────────────────────────┐
│           Your Request                  │
│     "Build me a data processor"         │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│           Pi While Loop                 │
│                                         │
│  while not done:                        │
│    1. Send context to LLM               │
│    2. LLM returns tool calls            │
│    3. Execute tools (read/write/bash)   │
│    4. Add results to context            │
│    5. Repeat                            │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         4 Tools Available               │
│                                         │
│  • read(file_path)                      │
│  • write(file_path, content)            │
│  • edit(file_path, changes)             │
│  • bash(command)                        │
└─────────────────────────────────────────┘
```

That's the entire system.

---

## 📋 Lessons

### 3.1 The While Loop + 4 Tools Pattern
**File:** `3.1-core-loop.md`

**The loop:**
```python
# Simplified Pi pseudocode
while True:
    # Send to LLM: system prompt + conversation history + tool results
    response = llm.chat(context)
    
    if response.has_tool_calls():
        for tool_call in response.tool_calls:
            result = execute_tool(tool_call)
            context.append(result)
    else:
        # LLM is done
        break
```

**That's it.** No complex orchestration. Just: ask LLM → execute tools → repeat.

---

### 3.2 The Four Tools (and why that's enough)
**File:** `3.2-four-tools.md`

#### 1. **read(file_path)**
```bash
# Behind the scenes
cat /path/to/file
```

**What it gives agent:**
- File contents
- Directory listings
- Any text data

---

#### 2. **write(file_path, content)**
```bash
# Behind the scenes
echo "$content" > /path/to/file
```

**What it gives agent:**
- Create new files
- Overwrite existing
- Save results

---

#### 3. **edit(file_path, changes)**
```bash
# Behind the scenes (simplified)
# Apply diff or search-replace
sed -i 's/old/new/g' /path/to/file
```

**What it gives agent:**
- Modify existing files
- Apply patches
- Update code

---

#### 4. **bash(command)**
```bash
# Behind the scenes
bash -c "$command"
```

**What it gives agent:**
- Run ANY program
- Process data
- Call APIs
- Literally everything else

**This is the key:** bash tool = infinite extensibility.

---

### 3.3 How Agents Decide What to Do
**File:** `3.3-agent-decision-making.md`

**Your request:**
> "Create a script that counts errors in logs"

**Pi's internal loop:**

**Turn 1:**
- LLM: "I need to see the directory structure"
- Tool call: `bash("ls -la")`
- Result: [file listing]

**Turn 2:**
- LLM: "I see logs in ./logs/. Let me check one"
- Tool call: `read("logs/app.log")`
- Result: [log contents]

**Turn 3:**
- LLM: "I'll create a script to count errors"
- Tool call: `write("count-errors.sh", <script content>)`
- Result: [file created]

**Turn 4:**
- LLM: "Make it executable"
- Tool call: `bash("chmod +x count-errors.sh")`
- Result: [permission changed]

**Turn 5:**
- LLM: "Done. You can now run `./count-errors.sh`"
- No more tool calls → loop ends

---

### 3.4 Skills: Extensible, Self-Modifying Code
**File:** `3.4-skills-system.md`

**Problem:** Agent needs to do something specialized (e.g., send email).

**Bad solution:** Add "send_email" as a 5th tool (now you need a 6th, 7th, 8th...)

**Pi's solution:** Agent creates a bash script.

```bash
# Agent writes this via write() tool
cat > send-email.sh << 'EOF'
#!/bin/bash
# send-email.sh - Send email via Gmail API
to="$1"
subject="$2"
body="$3"

curl -X POST "https://gmail.googleapis.com/send" \
  -H "Authorization: Bearer $GMAIL_TOKEN" \
  -d "{\"to\":\"$to\",\"subject\":\"$subject\",\"body\":\"$body\"}"
EOF

chmod +x send-email.sh

# Now agent can use it
./send-email.sh "blake@example.com" "Report" "See attached"
```

**Key insight:** Skills are just bash scripts the agent creates and uses.

**Pi's skill directory:**
- Agent reads markdown docs
- Agent creates bash/Python scripts
- Agent can modify its own skills
- Agent can discover new skills (ls *.sh)

---

### 3.5 Memory Without a Memory System
**File:** `3.5-memory-as-files.md`

**Conventional agents:** Complex vector databases, embeddings, RAG systems.

**Pi:** Files on disk.

```bash
# "Remember this for later"
echo "User prefers Python over JavaScript" >> memory/preferences.txt

# "What were we working on?"
cat memory/current-task.txt

# "What did we do last week?"
cat memory/2026-02-02.md
```

**Why this works:**
- Agent can read files (read tool)
- Agent can search files (bash: grep, rg)
- File system = persistent memory
- No complex infrastructure needed

**From the podcast:**
> "Code is truth. Code is the ground truth. It's also evolving and I don't need another place that I need to maintain."  
> — Mario Zechner

---

### 3.6 Pi vs. Claude Code vs. Cursor
**File:** `3.6-framework-comparison.md`

| Feature | Pi | Claude Code | Cursor |
|---------|----|-----------|----|
| **Core tools** | 4 (read/write/edit/bash) | ~20 specialized | ~30 specialized |
| **Extensibility** | Infinite (bash) | Limited to built-in tools | Limited to integrations |
| **Self-modifying** | Yes (agent creates scripts) | No | No |
| **Workflow** | Adapts to yours | Opinionated | Opinionated |
| **Complexity** | Minimal | Medium | High |
| **System prompt** | ~1000 tokens | ~5000 tokens | ~10000 tokens |

**Why Pi is different:**
- **Cursor/Claude Code:** "Here are 50 tools, use them"
- **Pi:** "Here are 4 tools, create what you need"

**Trade-offs:**
- Pi: More flexible, steeper learning curve
- Others: More polished, less customizable

---

## 🛠️ Hands-On: Trace a Pi Session

**Exercise:** Follow an agent conversation step-by-step.

**Scenario:** "Create a markdown report from JSON data"

**Location:** `../exercises/module3/trace-pi-session.md`

See how:
1. Agent reads the JSON file
2. Agent creates a Python script to process it
3. Agent runs the script
4. Agent formats output as markdown
5. Agent saves the report

---

## 📊 Key Architecture Decisions

### Decision 1: Minimal core

**Why 4 tools?**
- Easier to implement
- Easier to debug
- Easier to understand
- Everything else is composition

---

### Decision 2: Bash as the escape hatch

**Why not more specialized tools?**
- Bash can call anything
- Agent can create tools as needed
- No need to maintain 50+ tool implementations

---

### Decision 3: File system = memory

**Why not vector DB?**
- Simpler to implement
- Transparent (you can read the files)
- Agent can use grep/search
- No infrastructure to maintain

---

### Decision 4: Self-modifying allowed

**Why let agent change itself?**
- Adapts to your workflow
- Can fix its own bugs
- Can add features on demand
- More like a human developer

---

## 🎓 Knowledge Check

1. **What happens if an LLM returns no tool calls?**  
   <details><summary>Answer</summary>The while loop ends. Agent is done.</details>

2. **How does Pi add new functionality without adding tools?**  
   <details><summary>Answer</summary>Agent creates bash scripts via write + bash tools.</details>

3. **Why is bash the "4th tool" and not Python or Node?**  
   <details><summary>Answer</summary>Bash can call Python, Node, or anything else. It's the universal interface.</details>

4. **How does Pi handle memory?**  
   <details><summary>Answer</summary>Files on disk. Agent reads/writes markdown files, JSON, etc.</details>

---

## 💡 Key Insight

> **Pi isn't minimal because it's simple.**  
> **Pi is minimal because bash is powerful.**

The complexity is in bash/system, not in Pi itself.

---

## 🚀 Next Steps

You now understand **how Pi works**.

**Next module:**  
→ `../04-openclaw-patterns/` — See Pi's ideas applied in OpenClaw

**Or build something:**  
→ `../05-building-agents/` — Create your own mini-Pi

---

**Pro tip:** Read Pi's source code. It's surprisingly short (~500 lines for core loop). That's the point.
