# Exercise: Module 5 Custom CLI

**Difficulty:** Intermediate
**Time:** 45–90 minutes

---

## What's Already Built

The `crm.py` file is a working CRM CLI with three commands:

```bash
# Add a contact
python3 crm.py add --name "Jane Doe" --email "jane@example.com" --role "Director" --company "Acme"

# List all contacts
python3 crm.py list
python3 crm.py list --json

# Search contacts
python3 crm.py search "Acme"
python3 crm.py search "Jane" --json
```

Data is stored in `crm_db.json` in the current directory.

---

## What You'll Add

Five exercises, each adding one new command. Work through them in order — each builds on the previous.

---

## Exercise 1: The `delete` Command

**Goal:** Remove a contact from the database by email address.

**Usage:**
```bash
python3 crm.py delete jane@example.com
```

**Expected behavior:**
- If the email exists: remove the contact, print `Deleted: Jane Doe (jane@example.com)`
- If the email doesn't exist: print an error to stderr and exit with code 1

**Hints:**
- Load the database, filter out the matching contact, save
- Use a list comprehension: `db = [c for c in db if c['email'] != args.email]`
- Track whether anything was actually deleted before saving

---

## Exercise 2: The `update` Command

**Goal:** Update a contact's role and/or company by email address.

**Usage:**
```bash
# Update role only
python3 crm.py update jane@example.com --role "VP Engineering"

# Update company only
python3 crm.py update jane@example.com --company "NewCo"

# Update both
python3 crm.py update jane@example.com --role "VP Engineering" --company "NewCo"
```

**Expected behavior:**
- Find the contact by email
- Update only the fields that were provided (don't overwrite with empty strings)
- Print: `Updated: Jane Doe (jane@example.com)`
- Error if email not found

**Hints:**
- `--role` and `--company` should have `default=None` so you can detect if they were provided
- Loop through `db` to find the matching contact (modify in place)

---

## Exercise 3: The `export` Command

**Goal:** Export all contacts to a CSV file.

**Usage:**
```bash
python3 crm.py export contacts.csv
python3 crm.py export  # uses contacts.csv by default
```

**Expected behavior:**
- Write a CSV with headers: `name,email,role,company`
- Print: `Exported 5 contact(s) to contacts.csv`
- Handle empty database gracefully

**Hints:**
- Use `import csv` from the standard library
- `csv.DictWriter` with `fieldnames=['name', 'email', 'role', 'company']`

---

## Exercise 4: The `import` Command

**Goal:** Import contacts from a CSV file (merging with existing data).

**Usage:**
```bash
python3 crm.py import contacts.csv
```

**Expected behavior:**
- Read the CSV file
- For each row: add if email doesn't exist, skip if it does (no overwrites)
- Print: `Imported 3 new contact(s). Skipped 2 (already exist).`
- Error if file not found or CSV is malformed

**Hints:**
- Use `csv.DictReader`
- Build a set of existing emails for fast lookup: `existing = {c['email'] for c in db}`
- Validate that required fields (`name`, `email`) are present in each row

---

## Exercise 5: The `report` Command

**Goal:** Generate an HTML file showing all contacts in a formatted table.

**Usage:**
```bash
python3 crm.py report
python3 crm.py report contacts-report.html
```

**Expected behavior:**
- Generate a self-contained HTML file
- Include: title, generated date, contact count, sortable table with all contacts
- Print: `Report saved to contacts-report.html`

**Hints:**
- Use an f-string to build the HTML — no external libraries needed
- Table rows: loop over `db` and build `<tr><td>...</td></tr>` strings
- Add a bit of inline CSS to make it look professional

---

## Testing Your Work

After each exercise, test your implementation:

```bash
# Add some test data first
python3 crm.py add --name "Alice Smith" --email "alice@example.com" --role "Manager" --company "Acme"
python3 crm.py add --name "Bob Jones" --email "bob@example.com" --role "Engineer" --company "TechCo"
python3 crm.py add --name "Carol White" --email "carol@example.com" --role "Director" --company "Acme"

# Test delete
python3 crm.py delete bob@example.com
python3 crm.py list

# Test update
python3 crm.py update alice@example.com --role "Senior Manager"
python3 crm.py search "alice"

# Test export
python3 crm.py export test-export.csv
cat test-export.csv

# Test import (after deleting one)
python3 crm.py delete carol@example.com
python3 crm.py import test-export.csv

# Test report
python3 crm.py report
open crm_report.html
```

---

## Compare with the Solution

Once you've built your version, compare it:

```bash
diff crm.py solution/crm_full.py
```

Or run the solution directly:
```bash
python3 solution/crm_full.py list
```

---

## Connection to Pi Patterns

Each CLI command is a **tool** in the Pi sense:

| CRM Command | Pi Tool Type | What It Does |
|---|---|---|
| `list` | read | Returns data without modifying anything |
| `search` | read | Filtered read |
| `add` | write | Appends to the database |
| `delete` | edit | Removes from the database |
| `update` | edit | Modifies an existing record |
| `export` | write | Writes data to a new file |
| `import` | write | Reads a file and appends to DB |
| `report` | write | Creates a new output artifact |

When you expose this CRM to an AI agent, each command becomes something the agent can call:

```
Agent: "Add Dr. Sarah Chen as a provider contact"
→ python3 crm.py add --name "Dr. Sarah Chen" --email "s.chen@hospital.org" --role "Cardiologist" --company "City Hospital"

Agent: "Who do we have at City Hospital?"
→ python3 crm.py search "City Hospital" --json
```

---

## OpenClaw Connection

If you were building this as an OpenClaw skill, each command would map to a skill action:

```python
# OpenClaw skill definition (conceptual)
class CRMSkill:
    def add_contact(self, name, email, role, company): ...
    def search_contacts(self, query): ...
    def export_contacts(self, filepath): ...
    def generate_report(self): ...
```

The CLI is your "poor man's OpenClaw" — it gives the same interface to both humans (via terminal) and agents (via bash tool calls), without needing to build a full web API.

The bash pattern is:
```bash
# Agent calling CRM as a tool
result=$(python3 crm.py search "$provider_name" --json)
email=$(echo "$result" | jq -r '.[0].email')
```
