# Exercise: Trace a Pi Session

**Hands-on practice — work through tool calls step by step**

---

## How to Use This Exercise

For each scenario:
1. Read the task and the data
2. Write down which tool calls Pi would make (turn by turn)
3. Check your answer in the collapsible section

Don't skip to the answer. The point is to build intuition for how an agent reasons.

---

## Scenario 1: Create a Markdown Report from JSON Data

### The task

> "Create a markdown report from this claims data."

### The data

File: `data/claims.json`

```json
{
  "report_period": "2026-Q1",
  "generated_at": "2026-03-15T09:00:00Z",
  "claims": [
    {"claim_id": "CLM-001", "policy_type": "auto",   "status": "approved", "amount_cents": 125000, "adjuster": "Rivera"},
    {"claim_id": "CLM-002", "policy_type": "home",   "status": "denied",   "amount_cents": 45000,  "adjuster": "Chen"},
    {"claim_id": "CLM-003", "policy_type": "auto",   "status": "pending",  "amount_cents": 87500,  "adjuster": "Rivera"},
    {"claim_id": "CLM-004", "policy_type": "health", "status": "approved", "amount_cents": 320000, "adjuster": "Okafor"},
    {"claim_id": "CLM-005", "policy_type": "home",   "status": "approved", "amount_cents": 95000,  "adjuster": "Chen"},
    {"claim_id": "CLM-006", "policy_type": "auto",   "status": "approved", "amount_cents": 62000,  "adjuster": "Okafor"},
    {"claim_id": "CLM-007", "policy_type": "health", "status": "reviewing","amount_cents": 410000, "adjuster": "Rivera"},
    {"claim_id": "CLM-008", "policy_type": "home",   "status": "denied",   "amount_cents": 33000,  "adjuster": "Chen"}
  ]
}
```

### Your task

Write out each turn Pi would take. For each turn, specify:
- **What the LLM is thinking** (1 sentence)
- **Which tool it calls** and with what arguments
- **What result it gets back**

Go turn by turn until the agent is done.

---

_Write your answer here before looking_

---

<details>
<summary>Answer — Scenario 1</summary>

**Turn 1: Explore the environment**

LLM: "I need to see the data before writing a report."

```json
{ "tool": "read", "path": "data/claims.json" }
```

Result: the full JSON above.

---

**Turn 2: Compute the numbers**

LLM: "I understand the structure. Let me compute the metrics I need for the report — totals by status, by policy type, by adjuster."

```json
{
  "tool": "bash",
  "command": "python3 << 'EOF'\nimport json\nfrom collections import defaultdict\n\nwith open('data/claims.json') as f:\n    data = json.load(f)\n\nclaims = data['claims']\ntotal = len(claims)\ntotal_value = sum(c['amount_cents'] for c in claims) / 100\n\nby_status = defaultdict(list)\nby_type = defaultdict(list)\nby_adjuster = defaultdict(list)\n\nfor c in claims:\n    by_status[c['status']].append(c['amount_cents'])\n    by_type[c['policy_type']].append(c['amount_cents'])\n    by_adjuster[c['adjuster']].append(c['amount_cents'])\n\nprint(f'Total claims: {total}')\nprint(f'Total value: ${total_value:,.2f}')\nprint()\nprint('By status:')\nfor s, amounts in sorted(by_status.items()):\n    print(f'  {s}: {len(amounts)} claims, ${sum(amounts)/100:,.2f}')\nprint()\nprint('By type:')\nfor t, amounts in sorted(by_type.items()):\n    print(f'  {t}: {len(amounts)} claims, ${sum(amounts)/100:,.2f}')\nprint()\nprint('By adjuster:')\nfor a, amounts in sorted(by_adjuster.items()):\n    print(f'  {a}: {len(amounts)} claims, ${sum(amounts)/100:,.2f}')\nEOF"
}
```

Result:
```
Total claims: 8
Total value: $12,775.00

By status:
  approved: 4 claims, $6,020.00
  denied: 2 claims, $780.00
  pending: 1 claims, $875.00
  reviewing: 1 claims, $4,100.00

By type:
  auto: 3 claims, $2,745.00
  health: 2 claims, $7,300.00
  home: 3 claims, $1,730.00

By adjuster:
  Chen: 3 claims, $1,730.00
  Okafor: 2 claims, $3,820.00
  Rivera: 3 claims, $7,225.00
```

---

**Turn 3: Write the report**

LLM: "I have all the numbers. I'll write the markdown report."

```json
{
  "tool": "write",
  "path": "reports/2026-03-15-q1-claims-report.md",
  "content": "# Q1 2026 Claims Report\n\n**Period:** 2026-Q1  \n**Generated:** 2026-03-15\n\n---\n\n## Executive Summary\n\n- **8 total claims** worth **$12,775.00** in Q1 2026\n- **4 claims approved** ($6,020.00) — 50% approval rate\n- Health claims represent the largest value ($7,300.00 across 2 claims)\n- Rivera leads adjuster workload (3 claims, $7,225.00 in value)\n\n---\n\n## Claims by Status\n\n| Status | Count | Total Value |\n|--------|-------|-------------|\n| Approved | 4 | $6,020.00 |\n| Reviewing | 1 | $4,100.00 |\n| Pending | 1 | $875.00 |\n| Denied | 2 | $780.00 |\n| **Total** | **8** | **$12,775.00** |\n\n---\n\n## Claims by Policy Type\n\n| Type | Count | Total Value | Avg Value |\n|------|-------|-------------|----------|\n| Health | 2 | $7,300.00 | $3,650.00 |\n| Auto | 3 | $2,745.00 | $915.00 |\n| Home | 3 | $1,730.00 | $576.67 |\n\n---\n\n## Adjuster Performance\n\n| Adjuster | Claims | Total Value |\n|----------|--------|-------------|\n| Rivera | 3 | $7,225.00 |\n| Okafor | 2 | $3,820.00 |\n| Chen | 3 | $1,730.00 |\n"
}
```

Result: `File written: reports/2026-03-15-q1-claims-report.md (847 bytes)`

---

**Turn 4: Verify**

LLM: "Let me confirm the report looks right."

```json
{ "tool": "read", "path": "reports/2026-03-15-q1-claims-report.md" }
```

Result: report contents — looks correct.

---

**Turn 5: Done (no tool call)**

LLM responds:
> "Done. I've created `reports/2026-03-15-q1-claims-report.md` with:
> - Executive summary (4 key points)
> - Claims breakdown by status, policy type, and adjuster
> - All amounts converted from cents to dollars
>
> Notable: the one 'reviewing' claim (CLM-007, $4,100) is the largest single claim in the batch."

---

**Key decisions in this trace:**
- Read the data first — don't guess the schema
- Compute in Python (bash tool) rather than doing math in the LLM's head
- Write to the standard `reports/` directory with date prefix
- Verify by reading the output
- Add a non-obvious insight in the final message (the reviewing claim)

</details>

---

## Scenario 2: Find Python Files with TODO Comments and Create a Summary

### The task

> "Find all Python files in this repo that have TODO comments, and create a summary of what needs to be done."

### The project structure (assumed)

```
src/
├── api/
│   ├── routes.py
│   └── auth.py
├── models/
│   ├── claims.py
│   └── policies.py
└── utils/
    ├── formatters.py
    └── validators.py
tests/
├── test_routes.py
└── test_models.py
scripts/
└── process-claims.py
```

### Your task

Trace the turns. How does Pi find the files, what does it extract, and how does it write the summary?

---

<details>
<summary>Answer — Scenario 2</summary>

**Turn 1: Search for TODOs**

LLM: "I need to find all TODO comments in Python files across the repo."

```json
{
  "tool": "bash",
  "command": "grep -rn 'TODO\\|FIXME\\|HACK\\|XXX' --include='*.py' . | sort"
}
```

Result:
```
./scripts/process-claims.py:14:    # TODO: add retry logic for failed DB connections
./src/api/auth.py:87:    # TODO: implement token refresh
./src/api/auth.py:103:    # FIXME: this validation allows empty passwords
./src/models/claims.py:45:    # TODO: add index on policy_id for performance
./src/models/claims.py:62:    # HACK: workaround for null adjuster_id, fix before v2.0
./src/utils/validators.py:31:    # TODO: validate phone number format
```

---

**Turn 2: Get context for each TODO**

LLM: "I have the list. For a useful summary, I need a few lines of context around each one to understand what it's about."

```json
{
  "tool": "bash",
  "command": "grep -rn -B2 -A2 'TODO\\|FIXME\\|HACK\\|XXX' --include='*.py' ."
}
```

Result: each TODO with 2 lines before and after, showing the function/class it's in.

---

**Turn 3: Write the summary**

LLM: "I have enough context. I'll write the summary organized by priority."

```json
{
  "tool": "write",
  "path": "TODO-summary.md",
  "content": "# TODO Summary\n\nGenerated: 2026-03-15  \n**6 items across 4 files**\n\n---\n\n## High Priority (FIXME / HACK)\n\n### `src/api/auth.py:103`\n**FIXME:** Validation allows empty passwords  \nSecurity issue — must fix before next release.\n\n### `src/models/claims.py:62`\n**HACK:** Workaround for null `adjuster_id`  \nNeeds proper fix before v2.0.\n\n---\n\n## Standard TODOs\n\n### `src/api/auth.py:87`\nImplement token refresh logic.\n\n### `src/models/claims.py:45`\nAdd database index on `policy_id` for query performance.\n\n### `scripts/process-claims.py:14`\nAdd retry logic for failed DB connections.\n\n### `src/utils/validators.py:31`\nAdd phone number format validation.\n\n---\n\n## By File\n\n| File | Count | Items |\n|------|-------|-------|\n| src/api/auth.py | 2 | FIXME (empty passwords), TODO (token refresh) |\n| src/models/claims.py | 2 | HACK (adjuster_id), TODO (index) |\n| scripts/process-claims.py | 1 | TODO (DB retry) |\n| src/utils/validators.py | 1 | TODO (phone validation) |\n"
}
```

---

**Turn 4: Done (no tool call)**

> "Done. I've created `TODO-summary.md` with 6 items across 4 files.
>
> Two items need immediate attention:
> - `auth.py:103` — security issue, allows empty passwords
> - `models/claims.py:62` — acknowledged hack that must be fixed before v2.0"

---

**Key decisions:**
- Use `grep -rn` to get file and line numbers
- Use `-B2 -A2` context flags on the second pass to understand each TODO
- Separate FIXME/HACK (high priority) from TODO (normal)
- The agent highlights the two most important items unprompted

**Alternative approach:** A single grep with context might be enough without a second turn if the context is clear. The agent adapts based on what the first result tells it.

</details>

---

## Scenario 3: Download a CSV, Process It, and Email a Summary

### The task

> "Download the daily claims export from https://data.internal/exports/claims-2026-03-15.csv, find any claims over $10,000, and email a summary to risk@company.com."

### Assumed environment

- `curl` is available
- `SENDGRID_API_KEY` is set in the environment
- Python 3 is available with pandas installed
- No special tools — just bash, read, write, edit

### Your task

This scenario spans download → process → email. The whole pipeline runs through bash. Trace the turns.

---

<details>
<summary>Answer — Scenario 3</summary>

**Turn 1: Download the file**

LLM: "First, get the file."

```json
{
  "tool": "bash",
  "command": "curl -s -o data/claims-2026-03-15.csv 'https://data.internal/exports/claims-2026-03-15.csv' && echo 'Downloaded' && wc -l data/claims-2026-03-15.csv"
}
```

Result:
```
Downloaded
1847 data/claims-2026-03-15.csv
```

---

**Turn 2: Inspect the CSV structure**

LLM: "1,846 data rows. Let me see the column structure."

```json
{
  "tool": "bash",
  "command": "head -3 data/claims-2026-03-15.csv"
}
```

Result:
```
claim_id,policy_id,amount,status,adjuster,opened_date
CLM-10291,POL-88341,125.00,approved,Rivera,2026-03-14
CLM-10292,POL-55821,10500.00,reviewing,Chen,2026-03-15
```

---

**Turn 3: Find large claims and compute summary**

LLM: "Amount is in dollars (float). Find claims > $10,000 and compute the summary stats."

```json
{
  "tool": "bash",
  "command": "python3 << 'EOF'\nimport csv\nfrom io import StringIO\n\nwith open('data/claims-2026-03-15.csv') as f:\n    reader = csv.DictReader(f)\n    claims = list(reader)\n\nlarge = [c for c in claims if float(c['amount']) > 10000]\nlarge.sort(key=lambda c: -float(c['amount']))\n\nprint(f'Total claims: {len(claims)}')\nprint(f'Claims over $10,000: {len(large)}')\nprint(f'Total value (large): ${sum(float(c[\"amount\"]) for c in large):,.2f}')\nprint()\nprint('Top 5:')\nfor c in large[:5]:\n    print(f\"  {c['claim_id']}: ${float(c['amount']):,.2f} ({c['status']}, {c['adjuster']})\")\nEOF"
}
```

Result:
```
Total claims: 1846
Claims over $10,000: 23
Total value (large): $487,230.00

Top 5:
  CLM-10444: $52,000.00 (reviewing, Okafor)
  CLM-10381: $38,500.00 (reviewing, Rivera)
  CLM-10292: $10,500.00 (reviewing, Chen)
  ...
```

---

**Turn 4: Send the email**

LLM: "I have the summary. Send it via SendGrid API."

```json
{
  "tool": "bash",
  "command": "curl -s -X POST 'https://api.sendgrid.com/v3/mail/send' \\\n  -H 'Authorization: Bearer $SENDGRID_API_KEY' \\\n  -H 'Content-Type: application/json' \\\n  -d '{\n    \"personalizations\": [{\"to\": [{\"email\": \"risk@company.com\"}]}],\n    \"from\": {\"email\": \"agent@company.com\"},\n    \"subject\": \"Daily Claims Alert: 23 claims over $10,000 (2026-03-15)\",\n    \"content\": [{\n      \"type\": \"text/plain\",\n      \"value\": \"Daily Claims Export Summary\\n2026-03-15\\n\\n1,846 total claims processed\\n23 claims exceeded $10,000 threshold\\nTotal value of flagged claims: $487,230.00\\n\\nTop flagged claim:\\nCLM-10444: $52,000.00 (reviewing, adjuster: Okafor)\\n\\nFull export: data/claims-2026-03-15.csv\"\n    }]\n  }' && echo 'Email sent'"
}
```

Result:
```
Email sent
```

---

**Turn 5: Log the run**

LLM: "Good practice to record that this ran."

```json
{
  "tool": "bash",
  "command": "echo '2026-03-15 09:15:00 | claims-alert | 1846 claims | 23 flagged | $487,230 | sent to risk@company.com' >> memory/pipeline-log.md"
}
```

---

**Turn 6: Done (no tool call)**

> "Done. Processed 1,846 claims from today's export and sent an alert to risk@company.com.
>
> - 23 claims exceeded the $10,000 threshold
> - Total flagged value: $487,230.00
> - Largest flagged: CLM-10444 at $52,000 (currently in 'reviewing' status)
>
> The run has been logged to memory/pipeline-log.md."

---

**What this scenario demonstrates:**

1. **The whole pipeline runs through bash.** No "download_file" tool. No "send_email" tool. Just `curl` twice.

2. **Python for data processing, curl for HTTP.** Both via bash. The agent picks the right tool within bash.

3. **Error handling (not shown but expected):** If the curl download fails (exit code != 0), the agent sees the error output and would either retry or report the failure. If the email API returns a 4xx, it would check the error and fix the request.

4. **The agent adds value beyond the request:** It logs the run to `memory/pipeline-log.md` without being asked. This is good agent behavior — if you're running this daily, you want a log.

5. **No framework needed.** This entire pipeline works on any machine with curl and Python. Pi doesn't need a database connector, email plugin, or scheduler. Bash already has all of that.

</details>

---

## Reflection Questions

Think through these before moving on:

1. In Scenario 1, why did the agent run Python to compute metrics rather than doing the math in the LLM response?

   <details><summary>Answer</summary>
   LLMs make arithmetic errors. Python does not. For any calculation involving numbers — especially with many rows of data — always use code. The LLM's job is to write correct code, not to do arithmetic.
   </details>

2. In Scenario 2, why did the agent make two grep calls instead of one?

   <details><summary>Answer</summary>
   The first call got file paths and line numbers. The second got surrounding context to understand each TODO. You could do it in one call with `-B2 -A2` from the start — but the agent didn't know how much context it needed until it saw the results. This is normal: explore, then decide if you need more detail.
   </details>

3. In Scenario 3, what would the agent do if the download URL returned a 404?

   <details><summary>Answer</summary>
   The bash command would return a non-zero exit code (curl with -s would output nothing or an error body; the `&& echo 'Downloaded'` would not execute). The agent would see exit code non-zero, read the output, and either: (a) try a different URL format, (b) check if the file exists at an alternate location, or (c) report to the user that the export isn't available yet.
   </details>

4. In all three scenarios, the agent read the data/output before reporting success. Why is this important?

   <details><summary>Answer</summary>
   Verification. Writing a file succeeds even if the content is wrong. Running a command exits 0 even if the output is garbage. The agent checks its own work — reads the file it wrote, verifies the email was sent, confirms the numbers add up. This catches bugs that exit codes alone don't catch.
   </details>

---

**Next module:** [04 — OpenClaw Patterns →](../../04-openclaw-patterns/README.md)
