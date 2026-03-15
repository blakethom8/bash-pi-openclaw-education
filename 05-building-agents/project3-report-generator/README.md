# Project 3: Report Generator Agent

**Difficulty:** Intermediate
**Time:** 1 hour

---

## What You'll Build

A bash agent that takes a JSON data file (provider search results, claims summary, any structured data) and generates a self-contained, professional-looking HTML report that you can open in a browser, email as an attachment, or save to a shared drive.

```
Input:                     Agent:                     Output:
providers.json  ────────►  agent.sh                   report.html
                           ↓ runs generate_report.py  (standalone HTML,
                                                        no server needed)
```

This mirrors real enterprise workflows: you pull data → format it → distribute the report.

---

## Learning Objectives

- How to generate **self-contained HTML** (no external CSS files, no server required)
- How to use a **template with placeholders** (`{{TITLE}}`, `{{TABLE}}`, etc.)
- How an agent separates **data → rendering → distribution** into distinct steps
- How this pattern connects to the podcast summarizer: data in, formatted artifact out

---

## The Pi Pattern in This Agent

```
READ:   load JSON data file
DECIDE: validate structure, pick report type
BASH:   run generate_report.py → produces HTML
WRITE:  save HTML report to output directory
        (optionally open in browser)
```

---

## File Structure

```
project3-report-generator/
├── README.md
├── agent.sh                       ← Bash orchestrator
├── scripts/
│   └── generate_report.py         ← Python: JSON → HTML
├── templates/
│   └── report_template.html       ← HTML template with placeholders
├── tests/
│   └── sample-input.json          ← Sample provider search results
└── solution/
    └── agent.sh                   ← Reference solution
```

---

## Setup

```bash
chmod +x agent.sh
chmod +x solution/agent.sh
```

Python 3 required. No external packages.

---

## Running the Agent

```bash
# Generate an HTML report from provider data
./agent.sh tests/sample-input.json

# Specify output file
./agent.sh tests/sample-input.json --output ./my-report.html

# Open in browser after generating (macOS)
./agent.sh tests/sample-input.json --open
```

After running, open `workspace/report.html` in any browser.

---

## Sample Input Format

The `tests/sample-input.json` file contains provider search results:

```json
{
  "search_query": "cardiologist San Francisco",
  "generated_at": "2026-01-15",
  "providers": [
    {
      "name": "Dr. Sarah Chen MD",
      "specialty": "Cardiology",
      "address": "450 Sutter St, San Francisco, CA 94108",
      "phone": "(415) 555-0142",
      "npi": "1234567890",
      "accepting_patients": true,
      "network_status": "in-network"
    },
    ...
  ]
}
```

---

## Exercise Instructions

### Step 1: Understand the template

Open `templates/report_template.html`. Note the `{{PLACEHOLDER}}` values. These are the strings that `generate_report.py` will replace with real data.

### Step 2: Understand the generator

Run `generate_report.py` directly:

```bash
python3 scripts/generate_report.py tests/sample-input.json
cat workspace/report.html
```

### Step 3: Build agent.sh

The agent needs to:
1. Accept a JSON file path as argument
2. Validate the file exists
3. Run `generate_report.py`
4. Report success with the output path

### Step 4: Add the `--open` flag

On macOS, `open report.html` opens it in the default browser. Add this as an optional `--open` flag.

### Step 5: Test it

```bash
./agent.sh tests/sample-input.json
open workspace/report.html
```

---

## Expected Output

```
Report Generator Agent
Input:  tests/sample-input.json
Output: workspace/report.html
────────────────────────────────────────────
[1/2] Loading data...
  Provider count: 12
  Search query:   cardiologist San Francisco

[2/2] Generating HTML report...
  Template:  templates/report_template.html
  Generated: workspace/report.html (14.2 KB)

────────────────────────────────────────────
Done! Open your report:
  open workspace/report.html
```

---

## Extension Challenges

**Challenge 1:** Add a `--title` flag that overrides the report title.

**Challenge 2:** Accept claims data (in addition to provider data) and auto-detect which template to use based on the JSON schema.

**Challenge 3:** Add a `--email` flag: after generating, pipe the HTML to a `mail` command.

**Challenge 4:** Generate a PDF instead of HTML by calling a headless browser tool (if available on the system).

**Challenge 5:** Add a `--compare` mode that takes two JSON files and shows a diff table: providers added, removed, or changed between runs.

---

## Connection to Real Work

This pattern is the foundation for automated reporting:

| Agent Step | Real Use Case |
|---|---|
| Load provider JSON | Pull results from NPI lookup or provider directory |
| Run generate_report.py | Format for liaisons or compliance team |
| Save report.html | Email as attachment or post to SharePoint |
| `--open` flag | Quick preview before sending |

You could adapt this to generate weekly claims summaries, provider network reports, or audit documents — using the same agent structure.
