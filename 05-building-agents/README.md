# Module 5: Building Your Own Agents

**Hands-on projects to apply everything you've learned**

---

## 🎯 Module Goals

Build real, working agents using bash and the 4-tool pattern.

By the end, you'll have:
- Built a mini-agent from scratch
- Created bash-accessible workflows
- Designed a data pipeline for your actual work
- Applied "think in bash" to real problems

**Time:** 3-4 hours

---

## 📋 Projects

### Project 1: File Organizer Agent
**Difficulty:** Beginner  
**Time:** 30 minutes  
**File:** `project1-file-organizer/`

**What you'll build:**
A simple agent that organizes files by type.

**Tools used:**
- read (list files)
- bash (move files)
- write (log actions)

**Start here:** `project1-file-organizer/README.md`

---

### Project 2: Data Pipeline Agent
**Difficulty:** Intermediate  
**Time:** 1 hour  
**File:** `project2-data-pipeline/`

**What you'll build:**
An agent that processes CSV data → enriches → generates report.

**For your use case:** Claims data processing

**Tools used:**
- read (input data)
- bash (call Python scripts)
- write (output report)
- edit (modify configs)

**Start here:** `project2-data-pipeline/README.md`

---

### Project 3: Report Generator Agent
**Difficulty:** Intermediate  
**Time:** 1 hour  
**File:** `project3-report-generator/`

**What you'll build:**
Agent that pulls data → analyzes → creates HTML report.

**Like:** Your podcast summarization workflow

**Tools used:**
- bash (fetch data, run analysis)
- write (markdown report)
- bash (convert to HTML)

**Start here:** `project3-report-generator/README.md`

---

### Project 4: API Integration Agent
**Difficulty:** Intermediate  
**Time:** 1 hour  
**File:** `project4-api-integration/`

**What you'll build:**
Agent that calls APIs → processes results → saves output.

**For your use case:** Provider search, NPI lookups

**Tools used:**
- bash (curl commands)
- write (save JSON)
- bash (jq processing)

**Start here:** `project4-api-integration/README.md`

---

### Project 5: Your Own Agent
**Difficulty:** Advanced  
**Time:** 2+ hours  
**File:** `project5-custom-agent/`

**What you'll build:**
Whatever you need for your actual work!

**Suggestions:**
- Claims data analyzer
- Provider report generator
- House build status checker
- Automated email responder

**Template provided:** `project5-custom-agent/template.sh`

---

## 🛠️ Agent Template

Every agent follows this pattern:

```bash
#!/bin/bash
# agent-name.sh - Brief description

set -euo pipefail

# Configuration
WORKSPACE="./workspace"
mkdir -p "$WORKSPACE"

# Agent loop
while true; do
  echo "Agent: What should I do?"
  read -p "You: " task
  
  case "$task" in
    "quit"|"done")
      break
      ;;
    
    # Tool: read
    read*)
      file=$(echo "$task" | cut -d' ' -f2)
      cat "$file"
      ;;
    
    # Tool: write
    write*)
      file=$(echo "$task" | cut -d' ' -f2)
      echo "Enter content (Ctrl+D when done):"
      cat > "$file"
      ;;
    
    # Tool: bash (run anything)
    *)
      eval "$task"
      ;;
  esac
done
```

**Start with this, customize as needed.**

---

## 📖 Project Structure

Each project includes:

```
projectN-name/
├── README.md              # Instructions
├── agent.sh               # Main agent script
├── tests/                 # Test cases
│   └── test-data/        # Sample data
├── examples/              # Usage examples
└── solution/              # Reference solution
    └── agent.sh
```

**Learn by doing:**
1. Read the README
2. Try building it yourself
3. Run tests
4. Compare with solution

---

## 🎓 Learning Objectives

### After Project 1:
✅ Build a basic agent loop  
✅ Use read/write/bash tools  
✅ Handle user input

### After Project 2:
✅ Build data pipelines  
✅ Compose bash scripts  
✅ Process CSV/JSON data

### After Project 3:
✅ Generate reports programmatically  
✅ Use markdown → HTML conversion  
✅ Create self-contained artifacts

### After Project 4:
✅ Integrate with APIs  
✅ Process JSON responses  
✅ Build reusable wrappers

### After Project 5:
✅ Design agents for real work  
✅ Apply "think in bash" to actual problems  
✅ Build production-ready workflows

---

## 🚀 Getting Started

### **Start here if you're new:**
```bash
cd 05-building-agents/project1-file-organizer/
open README.md
```

### **Jump to your use case:**

**Data processing:**
```bash
cd project2-data-pipeline/
```

**Report generation:**
```bash
cd project3-report-generator/
```

**API integration:**
```bash
cd project4-api-integration/
```

---

## 💡 Design Principles

### 1. **Start minimal**
Don't build everything at once. Start with:
- read
- write  
- bash

Add features as needed.

---

### 2. **Make it bash-accessible**
Your agent's interface should be:
```bash
./agent.sh command [args]
```

Not: complex Python with 10 dependencies.

---

### 3. **Compose, don't monolith**
```bash
# Good
./fetch.sh | ./process.sh | ./report.sh

# Bad
./do-everything.sh
```

---

### 4. **Test with real data**
Use your actual files:
- Claims CSV files
- Provider search results
- Real-world inputs

---

### 5. **Document as you go**
```bash
# Add comments
# Write README
# Include examples
```

Future-you will thank you.

---

## 🎯 Final Project: Apply to Your Work

**Pick one workflow you do manually:**

**Option 1: Claims Data Analysis**
```bash
# Automate:
# 1. Extract claims for date range
# 2. Enrich with NPI data
# 3. Calculate statistics
# 4. Generate HTML report
```

**Option 2: Provider Search Pipeline**
```bash
# Automate:
# 1. Search Google Places API
# 2. Enrich with NPI data
# 3. Format for liaisons
# 4. Save to database
```

**Option 3: House Build Tracker**
```bash
# Automate:
# 1. Check permit status
# 2. Check contractor updates
# 3. Compare to timeline
# 4. Alert if delays
```

---

## 📝 Success Criteria

You've succeeded when:

✅ You can build a working agent in <30 minutes  
✅ Your agent uses read/write/bash tools  
✅ You've automated a real workflow  
✅ You think "how do I bash-ify this?" by default  
✅ You can explain Pi's architecture to someone else

---

## 🚀 Next Steps

**Start building:**
```bash
cd project1-file-organizer/
./agent.sh
```

**Or jump to your use case:**
```bash
cd project2-data-pipeline/  # For claims data
cd project4-api-integration/ # For provider search
```

---

**Remember:** Agents don't need to be perfect. They need to be useful and extensible.

**Start simple. Extend as needed. Think in bash.** 🎯
