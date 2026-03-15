# Exercise: Trace Your Workflow

**Module 4 hands-on exercise — map a multi-turn OpenClaw session turn by turn**

---

## What You're Doing

Complex agent tasks don't happen in one step. They happen across multiple turns, each building on the last. This exercise trains you to read a task description and predict exactly what the agent will do — which tools it calls, what bash commands run, what files get created, and how each turn contributes to the final result.

Understanding this deeply means you can:
- Debug why a workflow failed (which turn went wrong?)
- Improve a workflow (is there a turn that's redundant?)
- Design new workflows before writing a single skill

---

## How to Use Your Logs

If you have an active OpenClaw installation, find your session logs:

```bash
# Logs are typically here:
ls ~/.openclaw/logs/

# Or check your workspace for agent notes:
ls ~/.openclaw/workspace/memory/
```

Pick a recent multi-turn session. For each turn, identify:
1. What tool was called (`read`, `write`, `edit`, `exec`, `message`)
2. What the argument was (file path or bash command)
3. What the result was (what the agent saw)
4. What changed — what file was created or what information was added to context

If you don't have logs, use the guided scenarios below.

---

## Guided Scenario 1: Generate a Provider Summary Report

**Setup:** Your OpenClaw workspace has:
- `workspace/data/providers-2026-03.json` — a list of 120 providers with NPI numbers and claim counts
- `workspace/AGENTS.md` — includes DB connection info and note: "Monthly provider reports go in workspace/reports/"
- `workspace/skills/npi-lookup/SKILL.md` and `scripts/batch_lookup.py`
- `workspace/templates/provider-report.md` — a template with placeholders

**The request:**
> "Generate a provider summary report for March using providers-2026-03.json"

---

### Your task: Fill in this turn-by-turn table

| Turn | Tool | Argument / Command | What it returns | Why |
|------|------|-------------------|-----------------|-----|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |

---

<details>
<summary>Answer: Turn-by-turn breakdown</summary>

| Turn | Tool | Argument / Command | What it returns | Why |
|------|------|-------------------|-----------------|-----|
| 1 | `read` | `workspace/AGENTS.md` | DB config, output conventions, report preferences | Load context before doing any work |
| 2 | `read` | `workspace/data/providers-2026-03.json` | 120 provider records with NPI + claim counts | Understand input schema before writing processing scripts |
| 3 | `read` | `workspace/skills/npi-lookup/SKILL.md` | Script usage, input format, API rate limits | Learn how to enrich with NPI data |
| 4 | `exec` | `python3 skills/npi-lookup/scripts/batch_lookup.py workspace/data/providers-2026-03.json > workspace/tmp/providers-enriched.json` | 120 provider records with names, addresses, taxonomy | Enrich claim data with NPI registry info |
| 5 | `exec` | `python3 workspace/tmp/render_provider_report.py workspace/tmp/providers-enriched.json workspace/templates/provider-report.md > workspace/tmp/provider-report.md` | Rendered markdown report | Fill the template with real data |
| 6 | `exec` | `pandoc workspace/tmp/provider-report.md -o workspace/reports/2026-03-providers.html --standalone` | HTML file written | Convert to shareable HTML |
| 7 | `message` | "Provider summary for March ready. 120 providers, 8 new. workspace/reports/2026-03-providers.html" | Notification sent | Close the loop with the user |

**Intermediate files created:**
- `workspace/tmp/providers-enriched.json`
- `workspace/tmp/provider-report.md`
- `workspace/reports/2026-03-providers.html`

**Note:** You might also expect a Turn 3.5 where the agent reads a few lines of the enriched JSON to verify it looks right before rendering. That's good practice and a real agent often does it.

</details>

---

## Guided Scenario 2: Debug a Failed Report

**Setup:** The agent ran last night to generate the February denial analysis. The job ran for 6 turns and then produced an error. You have these files in your workspace:

```
workspace/tmp/
├── feb-denials-raw.csv     (exists, 3,847 rows)
├── feb-denials.log         (exists, contains error message)
└── feb-denial-stats.json   (missing — this should exist)

workspace/reports/
└── (empty — no report was generated)
```

The log file contains:
```
Processing 3,847 denial records...
Traceback (most recent call last):
  File "analyze_denials.py", line 47, in calculate_stats
    denial_rate = denied / total_claims
ZeroDivisionError: division by zero
```

**The request you send now:**
> "The February denial report failed. Can you fix and rerun?"

---

### Your task: Map what the agent should do to recover

Think about:
- Which turn can it skip? (The raw CSV already exists)
- What does it need to read to understand what went wrong?
- How does it fix the script?
- How does it verify the fix worked before re-running everything?

Write out the turns before checking the answer.

---

<details>
<summary>Answer: Recovery turn-by-turn</summary>

**Turn 1:** `read(workspace/tmp/feb-denials.log)`
→ Sees the ZeroDivisionError on line 47 of analyze_denials.py
→ Understands: something is dividing by `total_claims` which is 0

**Turn 2:** `read(workspace/skills/claims-query/scripts/analyze_denials.py)`
→ Reads the script, finds line 47: `denial_rate = denied / total_claims`
→ Diagnoses: the variable `total_claims` is zero, probably because the CSV column name is wrong

**Turn 3:** `exec(head -1 workspace/tmp/feb-denials-raw.csv)`
→ Returns: `claim_id,service_date,provider_npi,denial_code,amount,status`
→ Sees that the column is `status`, not `total_claims`
→ Now understands the real bug: the script was looking for a column that doesn't exist

**Turn 4:** `edit(workspace/skills/claims-query/scripts/analyze_denials.py, ...)`
→ Fixes the bug: change the column reference to use `status` column correctly
→ Also adds a guard: `if total_claims == 0: raise ValueError("No total_claims found — check CSV schema")`

**Turn 5:** `exec(python3 workspace/skills/claims-query/scripts/analyze_denials.py workspace/tmp/feb-denials-raw.csv workspace/tmp/feb-denial-stats.json)`
→ Reruns from the checkpoint (no need to re-query the database — raw CSV already exists)
→ Returns: `Processing 3,847 records... Output written to feb-denial-stats.json. Exit code: 0`

**Turn 6:** `read(workspace/tmp/feb-denial-stats.json)`
→ Verifies numbers look correct

**Turn 7:** `exec(python3 skills/claims-query/scripts/render_report.py workspace/tmp/feb-denial-stats.json workspace/templates/denial-report.md > workspace/tmp/feb-denial-report.md)`

**Turn 8:** `exec(pandoc workspace/tmp/feb-denial-report.md -o workspace/reports/2026-02-denials.html --standalone)`

**Turn 9:** `message("Denial report fixed and regenerated. Bug was in column reference (status vs total_claims). workspace/reports/2026-02-denials.html")`

**Key insight:** Because the raw CSV existed as a checkpoint, the agent could skip the database query and restart from Turn 5 of the original workflow. This is why intermediate files matter.

</details>

---

## Open-Ended Scenario: Your Actual Use Case

Pick one of these (or use your own):

**Option A:** "Summarize last week's provider search results and send me a Slack-formatted message I can paste"

**Option B:** "Pull the Q4 claims denial breakdown by taxonomy code and make a bar chart"

**Option C:** A real task you've run or want to run in OpenClaw

---

For your chosen task, map out:

```
Task: _______________________________________________

Files/context available in workspace:
  -
  -

Skills available:
  -
  -

Turn-by-turn breakdown:
  Turn 1: tool=_____ command/path=_____ result=_____
  Turn 2: tool=_____ command/path=_____ result=_____
  Turn 3: ...

Intermediate files created:
  -

Final output file(s):
  -

Message notification text:
  "_______________________________________________"

Potential failure points:
  Turn ___ could fail if: _______________________________________________
  Recovery: _______________________________________________
```

---

## Reflection Questions

After completing the scenarios, answer these:

1. Which pattern does each scenario fit? (Read→Process→Write, Template+Data→Document, Query→Enrich→Report, etc.)

2. In Scenario 2, why was it safe to skip the database query on recovery? What would have made it unsafe?

3. In your open-ended scenario, which turns are the most likely to fail? What would you put in AGENTS.md to help the agent handle those failures?

4. If you needed to run your open-ended scenario every week, what would you add to AGENTS.md to make it repeatable without re-explaining the steps?

---

## Connecting to the Module

The patterns you traced here are documented in:
- **4.3** — how `exec`, `read`, `write` compose
- **4.4** — how skills load their SKILL.md before running scripts
- **4.5** — the named workflow patterns (you should be able to name which pattern each scenario uses)
- **4.6** — full case studies for comparison

If your open-ended scenario feels unclear, go back to 4.5 and find the closest matching pattern. Start with that shape and adapt it.
