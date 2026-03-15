# Project 5: Build Your Own Agent

**Difficulty:** Advanced
**Time:** 2+ hours

---

## What You'll Build

Whatever you actually need for your work. This project gives you two templates to start from:

1. **`template.sh`** — Generic, minimal template. Blank slate with all the scaffolding in place.
2. **`enterprise-template.sh`** — Pre-wired for enterprise reporting. Has stubs for the full data → report → distribute pipeline.

---

## The 5-Step Process

Building a new agent takes about 30 minutes if you follow this process:

### Step 1: Identify the task

Write one sentence describing what you want to automate:

> "I want to automatically pull claims data for a date range, group by provider, and generate an HTML report."

Then break it into discrete steps:
- Pull data (query / read file)
- Transform data (group by provider, calculate sums)
- Generate report (HTML with table)
- Distribute (email / save to shared drive)

### Step 2: List the tools needed

For each step, which tool does it use?

| Step | Tool |
|---|---|
| Pull data | `read` or `bash` (curl, SQL) |
| Transform data | `bash` (Python script) |
| Generate report | `bash` (Python script) → `write` |
| Distribute | `bash` (mail, cp, curl) |

### Step 3: Write the skeleton

Copy `template.sh` or `enterprise-template.sh`. Replace the stub function names with your actual step names. Don't implement anything yet — just get the structure right.

### Step 4: Implement each tool

Fill in each function one at a time. Test each one before moving to the next.

```bash
# Test one function at a time
bash -c "source ./my-agent.sh; fetch_data 2026-01-01 2026-01-31"
```

### Step 5: Test end-to-end

Run the full pipeline on test data. Then on real data.

---

## Checklist for a Good Agent

Before you ship it, check:

- [ ] `set -euo pipefail` at the top
- [ ] `--help` flag works
- [ ] `--dry-run` flag if the agent modifies files
- [ ] Every step logs what it's doing
- [ ] Errors have clear messages (not just "exit code 1")
- [ ] Test with edge cases: empty input, missing files, network down
- [ ] Add a comment explaining the Pi pattern for each tool call

---

## Template Comparison

| Feature | `template.sh` | `enterprise-template.sh` |
|---|---|---|
| Argument parsing | Basic | Full (date-range, output-format, report-type) |
| Workspace setup | Yes | Yes |
| Logging | Basic | Structured with timestamps |
| Error handling | Basic | Per-stage with rollback |
| Stubs | 3 generic | 4 domain-specific |
| Use case | Any | Claims / provider reporting |

---

## Enterprise Use Cases

Pick one and build it:

### Option A: Claims Data Report

```bash
./claims-report-agent.sh --from 2026-01-01 --to 2026-01-31 --format html
```

Steps:
1. Read claims CSV for date range
2. Aggregate by category and status
3. Generate HTML report with charts (use ASCII bars if no chart library)
4. Save to `reports/claims-YYYY-MM.html`

### Option B: Provider Search Pipeline

```bash
./provider-search-agent.sh --specialty "cardiology" --state CA --limit 20
```

Steps:
1. Query NPI Registry API (use Project 4's `lookup_npi.sh`)
2. Enrich with acceptance/network status
3. Format for liaisons (HTML table)
4. Save to `providers/cardiology-CA-2026-01.html`

### Option C: Weekly Summary

```bash
./weekly-summary-agent.sh --week 2026-W03
```

Steps:
1. Read multiple data sources for the week
2. Compare to previous week
3. Highlight changes (new providers, unusual claims)
4. Email or save the report

---

## Getting Started

```bash
# Copy the template that fits your use case
cp template.sh my-agent.sh
chmod +x my-agent.sh

# Or use the enterprise template
cp enterprise-template.sh claims-report.sh
chmod +x claims-report.sh

# Run it to see the skeleton
./my-agent.sh --help
```

---

## When You're Stuck

**The task feels too big:** Break it into smaller steps. Build each step as a separate script first, then wire them together in the agent.

**You don't know which tool to use:** Start with bash. If the command gets complex, move it to a Python script and call that from bash.

**The output looks wrong:** Add `set -x` at the top temporarily to trace every command. Remove it when done.

**It works on your machine but not in production:** Check for hardcoded paths (use `SCRIPT_DIR` pattern), check for environment-specific commands, add `command -v <tool>` guards.
