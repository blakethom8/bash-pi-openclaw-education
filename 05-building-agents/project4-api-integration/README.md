# Project 4: API Integration Agent

**Difficulty:** Intermediate
**Time:** 1 hour

---

## What You'll Build

A bash agent that queries the **NPI Registry API** — a real, public API from the Centers for Medicare & Medicaid Services (CMS) — to look up healthcare providers by name or specialty. Results are saved to JSON and formatted into a summary report.

```
Input:                     Agent:                     Output:
"Dr. John Smith"  ───────► agent.sh                   providers.json
"cardiology"              ↓ lookup_npi.sh              report.txt
                          ↓ format_providers.py
```

This directly mirrors real enterprise workflows: NPI lookup is a core step in provider search and credentialing pipelines.

---

## Learning Objectives

- How to use `curl` inside bash agents for HTTP API calls
- How to process JSON responses with `jq`
- How to handle API errors (rate limits, empty results, malformed responses)
- How to build **reusable bash wrappers** around API calls (composable tools)
- How to chain: `lookup → process → report`

---

## The Pi Pattern in This Agent

```
READ:   accept provider name as input argument
BASH:   curl → NPI Registry API
BASH:   jq → extract and normalize fields
WRITE:  save to providers.json
BASH:   python3 format_providers.py → generate report
WRITE:  save to report.txt / report.html
```

---

## The NPI Registry API

**Base URL:** `https://npiregistry.cms.hhs.gov/api/`
**Documentation:** https://npiregistry.cms.hhs.gov/api-page
**Authentication:** None required (public API)
**Rate limit:** Generous, but don't hammer it

### Example request

```bash
curl "https://npiregistry.cms.hhs.gov/api/?version=2.1&first_name=John&last_name=Smith&taxonomy_description=cardiology&limit=10"
```

### Key response fields

```json
{
  "result_count": 3,
  "results": [
    {
      "number": "1234567890",
      "basic": {
        "first_name": "JOHN",
        "last_name": "SMITH",
        "credential": "MD"
      },
      "addresses": [
        {
          "address_1": "123 Main St",
          "city": "BOSTON",
          "state": "MA",
          "postal_code": "02101",
          "telephone_number": "617-555-0100",
          "address_purpose": "LOCATION"
        }
      ],
      "taxonomies": [
        {
          "code": "207RC0000X",
          "desc": "Cardiovascular Disease",
          "primary": true
        }
      ]
    }
  ]
}
```

---

## File Structure

```
project4-api-integration/
├── README.md
├── agent.sh                    ← Main orchestrator
├── scripts/
│   ├── lookup_npi.sh           ← Reusable NPI lookup wrapper
│   └── format_providers.py     ← Format results for display/report
├── tests/
│   └── mock-response.json      ← Sample API response for offline testing
└── solution/
    └── agent.sh                ← Reference solution
```

---

## Setup

```bash
chmod +x agent.sh
chmod +x scripts/lookup_npi.sh
chmod +x solution/agent.sh
```

**Prerequisites:** `curl` and `jq` must be installed.

Check:
```bash
curl --version
jq --version
```

Install jq if missing:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

---

## Running the Agent

```bash
# Search by provider name
./agent.sh --name "John Smith" --state MA

# Search by specialty
./agent.sh --specialty "cardiology" --state CA --limit 5

# Search with full name split
./agent.sh --first "Sarah" --last "Chen" --specialty "cardiology"

# Use mock data for testing (no network call)
./agent.sh --mock

# Save results to a specific file
./agent.sh --name "John Smith" --output ./my-providers.json
```

---

## Exercise Instructions

### Step 1: Test the lookup script directly

```bash
# Single lookup using the reusable wrapper
./scripts/lookup_npi.sh "Smith" "John" "cardiology" "MA"
```

This should output raw JSON from the API.

### Step 2: Use jq to extract fields

Practice processing the JSON:
```bash
./scripts/lookup_npi.sh "Smith" "" "cardiology" "CA" | \
  jq '.results[] | {name: .basic.last_name, npi: .number}'
```

### Step 3: Build agent.sh

The agent should:
1. Parse arguments (`--name`, `--specialty`, `--state`, etc.)
2. Call `lookup_npi.sh` with the right parameters
3. Save the raw response to `workspace/raw_response.json`
4. Call `format_providers.py` to generate a report
5. Display a summary

### Step 4: Handle errors

What happens if:
- The API returns zero results?
- `curl` fails (no network)?
- `jq` fails (malformed response)?

### Step 5: Test with mock data

```bash
./agent.sh --mock
```

The agent should load `tests/mock-response.json` instead of calling the API.

---

## Expected Output

```
NPI Lookup Agent
Query: last_name=Smith, specialty=cardiology, state=MA
────────────────────────────────────────────
[1/3] Calling NPI Registry API...
  URL: https://npiregistry.cms.hhs.gov/api/?...
  Results: 4 providers found

[2/3] Saving results...
  Raw response: workspace/raw_response.json
  Formatted:    workspace/providers.json

[3/3] Generating report...
  Report: workspace/report.txt

────────────────────────────────────────────
NPI LOOKUP RESULTS
Query: Smith | cardiology | MA
────────────────────────────────────────────
  Dr. John A. Smith MD          NPI: 1234567890
  Cardiovascular Disease
  123 Main St, Boston, MA 02101
  617-555-0100
  ─────────────────────────────────
  ...
```

---

## Extension Challenges

**Challenge 1:** Accept a CSV file of names and run a batch NPI lookup, one per row.

**Challenge 2:** Compare results across two states: `./agent.sh --specialty cardiology --compare MA CA`

**Challenge 3:** Add `--output-format html` that generates a clickable HTML table.

**Challenge 4:** Cache API results by query string — if you've looked up the same query in the last 24 hours, use the cached result instead of calling the API.

**Challenge 5:** Build a `verify_npi.sh` that takes a single NPI number and returns whether it's active.

---

## Connection to Real Work

| Agent Step | Real-World Equivalent |
|---|---|
| `lookup_npi.sh` | Provider credentialing check |
| `format_providers.py` | Format for liaison distribution |
| Batch mode | Process a list of referral providers |
| Cache layer | Avoid redundant API calls |
| `--mock` flag | CI/CD testing without network access |
