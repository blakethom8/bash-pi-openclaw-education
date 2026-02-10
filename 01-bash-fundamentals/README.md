# Module 1: Bash Fundamentals

**Learn the bash commands and concepts that agents actually use**

---

## 🎯 Module Goals

By the end of this module, you'll:
- Understand what bash is and why agents love it
- Know the ~20 core commands agents use most
- Be able to chain commands with pipes
- Write simple bash scripts
- Debug errors confidently

**Time:** 1-2 hours

---

## 📋 Lessons

### 1.1 What is Bash? (and why agents love it)
**File:** `1.1-what-is-bash.md`

- What bash actually is (shell + scripting language)
- Why it's the universal interface for Unix systems
- How agents use bash (spoiler: it's their "hands")
- Bash vs. other shells (zsh, fish, etc.)

**Key insight:** Bash is how agents interact with your computer's file system, run programs, and compose tools.

---

### 1.2 Core Commands (the ones agents actually use)
**File:** `1.2-core-commands.md`

The ~20 commands that cover 90% of agent work:

**File operations:**
- `ls` — list files
- `cd` — change directory
- `cat` — read file contents
- `echo` — write text
- `cp` / `mv` / `rm` — copy, move, delete

**Text processing:**
- `grep` — search text
- `sed` — find/replace
- `awk` — column processing
- `sort` / `uniq` / `wc` — sorting, counting

**Data formats:**
- `jq` — JSON processing
- `yq` — YAML processing
- `head` / `tail` — first/last lines

**Other:**
- `curl` — HTTP requests
- `python` / `node` — scripting
- `mkdir` / `touch` — create dirs/files

---

### 1.3 Pipes, Redirects, and Composition
**File:** `1.3-pipes-and-composition.md`

**The most important bash concept for agents:**

```bash
# Pipe: output of one command → input of next
cat file.txt | grep "error" | wc -l

# Redirect: save output to file
echo "Hello" > file.txt   # overwrite
echo "World" >> file.txt  # append

# Composition: build complex workflows
cat data.json | jq '.users[]' | grep "Blake" | sort
```

**Why this matters:** Agents compose small tools into complex workflows. This is how.

---

### 1.4 Exit Codes and Error Handling
**File:** `1.4-exit-codes.md`

**How agents know if something worked:**

```bash
# Every command returns an exit code
ls /nonexistent
echo $?  # prints: 1 (error)

ls /existing
echo $?  # prints: 0 (success)

# Conditional execution
command1 && command2  # run command2 only if command1 succeeds
command1 || command2  # run command2 only if command1 fails
```

**Why this matters:** Agents need to know if their actions succeeded or failed. Exit codes are how.

---

### 1.5 Variables, Loops, and Conditionals
**File:** `1.5-scripting-basics.md`

**Basic scripting for agents:**

```bash
# Variables
name="Blake"
echo "Hello, $name"

# Loops
for file in *.txt; do
  echo "Processing: $file"
done

# Conditionals
if [ -f "file.txt" ]; then
  echo "File exists"
fi
```

---

### 1.6 Scripts vs. One-Liners
**File:** `1.6-scripts-vs-oneliners.md`

**When to use each:**

**One-liner:** Quick task, no reuse needed
```bash
cat users.json | jq '.[] | select(.active == true) | .email'
```

**Script:** Reusable, complex logic, error handling
```bash
#!/bin/bash
# process-users.sh
set -euo pipefail  # exit on error

for file in data/*.json; do
  jq '.users[]' "$file" | grep "active" || echo "No active users in $file"
done
```

**Why this matters:** Agents create both. Scripts become reusable tools.

---

## 🛠️ Hands-On Exercises

**Location:** `../exercises/module1/`

1. **Exercise 1.1:** Navigate files, list directories
2. **Exercise 1.2:** Chain commands with pipes
3. **Exercise 1.3:** Write your first bash script
4. **Exercise 1.4:** Debug a broken script (exit codes)
5. **Exercise 1.5:** Build a mini file processor

**Solutions included** — but try first!

---

## 📝 Interactive Notebook

**Location:** `../notebooks/module1-bash-basics.ipynb`

Run bash commands interactively in Jupyter:
- Try commands safely
- See output immediately
- Experiment with variations

---

## 🎓 Knowledge Check

After this module, you should be able to answer:

1. What's the difference between `>` and `>>`?
2. How do you check if a command succeeded?
3. What does `cat file.txt | grep "error"` do?
4. How would you count lines in a file?
5. When would you write a script vs. a one-liner?

**Answers:** See `knowledge-check-answers.md`

---

## 🚀 Next Steps

**Ready for Module 2?**
→ Go to `../02-think-in-bash/`

**Want more practice?**
→ Try exercises in `../exercises/module1/`

**Prefer interactive?**
→ Open `../notebooks/module1-bash-basics.ipynb`

---

**Pro tip:** Don't memorize commands. Learn the patterns. Agents don't memorize either — they look things up as needed.
