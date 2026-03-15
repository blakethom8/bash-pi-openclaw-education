# Project 1: File Organizer Agent

**Difficulty:** Beginner
**Time:** 30 minutes

---

## What You'll Build

A bash agent that scans a directory, categorizes files by extension, moves them into organized subdirectories, and logs every action. It follows the Pi read/decide/bash/write pattern exactly.

```
messy-folder/
├── report.pdf
├── photo.jpg
├── data.csv
├── cleanup.sh
└── notes.txt

After running agent.sh:

messy-folder/
├── docs/
│   ├── report.pdf
│   └── notes.txt
├── images/
│   └── photo.jpg
├── data/
│   └── data.csv
├── scripts/
│   └── cleanup.sh
└── organizer.log
```

---

## Learning Objectives

After completing this project you will understand:

- How an agent uses **read** (list files) to observe its environment
- How it uses **bash** (move files) to take action
- How it uses **write** (append to log) to record what it did
- How a `--dry-run` flag lets you preview actions before committing
- How to accumulate a summary from individual actions

---

## The Pi Pattern in This Agent

```
LOOP:
  READ:  ls <directory>          → what files exist?
  DECIDE: classify by extension  → where should each file go?
  BASH:  mkdir + mv              → create dirs and move files
  WRITE: echo >> organizer.log   → record what happened
  SUMMARIZE: print final counts
```

---

## Setup

Make the scripts executable:

```bash
chmod +x agent.sh
chmod +x tests/test-organizer.sh
chmod +x solution/agent.sh
```

---

## Exercise Instructions

### Step 1: Read the agent skeleton

Open `agent.sh`. It has placeholder comments showing where to implement each section. Read through the entire file before writing any code.

### Step 2: Implement file classification

Find the `classify_file` function stub. Implement logic that maps file extensions to category names:

| Extensions | Category |
|---|---|
| pdf, doc, docx, txt, md | docs |
| jpg, jpeg, png, gif, svg, webp | images |
| sh, py, js, rb, go, rs | scripts |
| csv, json, xml, xlsx, sql | data |
| anything else | misc |

### Step 3: Implement the main loop

Find the main processing loop. For each file in the target directory:
1. Call `classify_file` to get the category
2. If `--dry-run`, print what would happen
3. Otherwise, create the target subdirectory and move the file
4. Log the action

### Step 4: Add the summary

After processing all files, print a count of files moved per category.

### Step 5: Test it

```bash
# Run the test suite
./tests/test-organizer.sh

# Or manually create a messy dir and try it
mkdir /tmp/test-messy
touch /tmp/test-messy/report.pdf /tmp/test-messy/photo.jpg /tmp/test-messy/data.csv
./agent.sh /tmp/test-messy

# Preview without moving (dry run)
./agent.sh --dry-run /tmp/test-messy
```

---

## Expected Output

```
File Organizer Agent
Target directory: /tmp/test-messy
Mode: LIVE (files will be moved)
----------------------------------------
[MOVE] report.pdf  →  docs/
[MOVE] photo.jpg   →  images/
[MOVE] data.csv    →  data/
----------------------------------------
Summary:
  docs:    1 file(s)
  images:  1 file(s)
  data:    1 file(s)
  Total:   3 file(s) organized
Log written to: /tmp/test-messy/organizer.log
```

---

## Hints

- Use `find "$TARGET_DIR" -maxdepth 1 -type f` to list only files (not subdirs)
- Use `basename "$filepath"` to get just the filename
- Use `"${filename##*.}"` to extract the extension
- Use `tr '[:upper:]' '[:lower:]'` to normalize extensions to lowercase
- Use `mkdir -p "$TARGET_DIR/$category"` to create category dirs safely
- Use `>>` to append to the log file

---

## Extension Challenges

After you get it working, try these:

**Challenge 1:** Skip files that are already in a category subdirectory (don't re-organize already-organized files).

**Challenge 2:** Add a `--undo` flag that reads `organizer.log` and moves everything back.

**Challenge 3:** Add a `--config` flag that accepts a JSON file mapping custom extensions to categories.

**Challenge 4:** Handle filename collisions — if `report.pdf` already exists in `docs/`, rename the new one `report_2.pdf`.

**Challenge 5:** Add a `--watch` mode that uses a `while true; do sleep 5; done` loop to continuously organize new files dropped into the directory.

---

## Compare with the Solution

Once you've built your version:

```bash
diff agent.sh solution/agent.sh
```

The solution is heavily commented to explain every Pi pattern decision.

---

## Connection to Real Work

This pattern maps directly to enterprise workflows:

| File Organizer | Claims Pipeline |
|---|---|
| List files in directory | Query claims from database |
| Classify by extension | Categorize by claim type |
| Move to subdirectory | Route to processing queue |
| Log each action | Audit trail |
| Summary report | Dashboard counts |

The agent structure is identical — only the domain changes.
