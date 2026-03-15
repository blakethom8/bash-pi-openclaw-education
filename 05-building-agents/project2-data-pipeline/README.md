# Project 2: Data Pipeline Agent

**Difficulty:** Intermediate
**Time:** 1 hour

---

## What You'll Build

A bash orchestrator that takes a raw claims CSV file and runs it through a two-stage Python pipeline:

1. **Analyze** — reads the CSV, calculates stats per category, writes `stats.json`
2. **Report** — reads `stats.json`, renders a markdown report with a summary table

```
Input:                    Pipeline:                  Output:
claims.csv  ──────────►  analyze.py  ──► stats.json
                          render_report.py           ──► report.md
```

The bash agent is the orchestrator — it calls each stage, writes checkpoints, and handles failures at each step.

---

## Learning Objectives

- How a bash agent **orchestrates** Python scripts (divide and conquer)
- How **file-based checkpointing** works: if the pipeline fails mid-way, restart from the last checkpoint
- How to handle **errors at each stage** with meaningful messages
- How bash pipelines compose: `fetch | process | report`
- Why separating bash orchestration from Python processing keeps each piece testable

---

## The Pi Pattern in This Agent

```
LOOP (one iteration per pipeline stage):

Stage 1:
  READ:  validate that input CSV exists and is readable
  BASH:  python3 scripts/analyze.py claims.csv > stats.json
  WRITE: write checkpoint file (.checkpoint_analyze)
  CHECK: did we get valid stats.json?

Stage 2:
  READ:  stats.json (checkpoint from stage 1)
  BASH:  python3 scripts/render_report.py stats.json > report.md
  WRITE: write checkpoint file (.checkpoint_report)
  CHECK: did we get report.md?
```

---

## File Structure

```
project2-data-pipeline/
├── README.md
├── agent.sh                  ← Bash orchestrator (you build this)
├── scripts/
│   ├── analyze.py            ← Stage 1: CSV → stats.json
│   └── render_report.py      ← Stage 2: stats.json → report.md
├── tests/
│   └── sample-data.csv       ← Realistic claims test data
└── solution/
    └── agent.sh              ← Reference solution
```

---

## Setup

```bash
chmod +x agent.sh
chmod +x solution/agent.sh
```

Python 3 required. No external packages — uses only the standard library.

---

## Running the Pipeline

```bash
# Run the full pipeline on sample data
./agent.sh tests/sample-data.csv

# Run and save output to a specific directory
./agent.sh tests/sample-data.csv --output ./my-report/

# Skip the analyze step if stats.json already exists (use checkpoint)
./agent.sh tests/sample-data.csv --resume
```

After running, you'll find:
- `workspace/stats.json` — intermediate analytics data
- `workspace/report.md` — the final markdown report

---

## Exercise Instructions

### Step 1: Understand the Python scripts

Run each script individually to understand what it expects and produces:

```bash
python3 scripts/analyze.py tests/sample-data.csv
python3 scripts/render_report.py workspace/stats.json
```

### Step 2: Build agent.sh

The agent needs to:
1. Accept a CSV file path as the first argument
2. Create a `workspace/` directory for intermediate files
3. Run `analyze.py`, capture errors, write a checkpoint
4. Run `render_report.py`, capture errors
5. Print a summary showing what was generated

### Step 3: Add checkpoint/resume logic

If `workspace/stats.json` already exists and `--resume` is passed, skip stage 1.

### Step 4: Add error handling

What should happen if:
- The CSV file doesn't exist?
- `analyze.py` exits with a non-zero code?
- `stats.json` is produced but is empty?

### Step 5: Test it

```bash
# Should succeed
./agent.sh tests/sample-data.csv

# Should fail with a clear error message
./agent.sh /nonexistent/file.csv

# Should use checkpoint
./agent.sh tests/sample-data.csv --resume
```

---

## Sample Data Format

The `tests/sample-data.csv` file contains realistic claims data:

```
claim_id,provider_name,amount,status,date,category
CLM001,Dr. Smith MD,1250.00,approved,2026-01-15,office_visit
CLM002,City Medical Center,4500.00,pending,2026-01-16,inpatient
...
```

Categories: `office_visit`, `specialist`, `inpatient`, `lab`, `imaging`, `pharmacy`

---

## Expected Output

```
Data Pipeline Agent
Input: tests/sample-data.csv
Output directory: workspace/
────────────────────────────────────────────
[Stage 1/2] Analyzing data...
  Running: python3 scripts/analyze.py
  Records processed: 28
  Categories found: 6
  Output: workspace/stats.json ✓
  Checkpoint saved.

[Stage 2/2] Rendering report...
  Running: python3 scripts/render_report.py
  Output: workspace/report.md ✓

────────────────────────────────────────────
Pipeline complete!
  Input rows:  28
  Categories:  6
  Report:      workspace/report.md
```

---

## Extension Challenges

**Challenge 1:** Add a `--format html` flag that generates an HTML report instead of (or in addition to) markdown.

**Challenge 2:** Add a third stage that sends the report to stdout so it can be piped: `./agent.sh data.csv | mail -s "Claims Report" team@example.com`

**Challenge 3:** Add date-range filtering: `./agent.sh data.csv --from 2026-01-01 --to 2026-01-31`

**Challenge 4:** Make the pipeline re-runnable: if run twice with the same input, it should detect the file hasn't changed (using a hash) and skip processing.

**Challenge 5:** Add a `--watch` mode: monitor the input CSV for changes and re-run the pipeline automatically.

---

## Connection to Real Work

This pipeline maps to a real claims processing workflow:

| Pipeline Stage | Real-World Equivalent |
|---|---|
| analyze.py | Query claims DB, aggregate by category |
| stats.json checkpoint | Intermediate results cache |
| render_report.py | Generate report for distribution |
| bash orchestrator | Cron job or triggered workflow |
| --resume flag | Idempotent re-runs after failure |
