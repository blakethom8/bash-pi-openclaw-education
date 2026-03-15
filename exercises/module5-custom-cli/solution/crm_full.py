#!/usr/bin/env python3
"""
crm_full.py - Complete CRM CLI with all commands implemented.

This is the reference solution for the Module 5 Custom CLI exercise.
All five exercise commands are implemented: delete, update, export, import, report.

Usage:
    python3 crm_full.py add --name "Jane Doe" --email "jane@co.com" --role "Dir" --company "Acme"
    python3 crm_full.py list [--json]
    python3 crm_full.py search <query> [--json]
    python3 crm_full.py delete <email>
    python3 crm_full.py update <email> [--role "New Role"] [--company "New Co"]
    python3 crm_full.py export [filename.csv]
    python3 crm_full.py import <filename.csv>
    python3 crm_full.py report [filename.html]
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime

# --- Configuration ---
CRM_FILE = os.environ.get("CRM_FILE", "crm_db.json")

# --- Helper Functions ---

def load_db():
    """Load the CRM database from disk. Returns empty list if file doesn't exist."""
    if not os.path.exists(CRM_FILE):
        return []
    try:
        with open(CRM_FILE, "r") as f:
            return json.load(f)
    except json.JSONDecodeError:
        print(f"Error: {CRM_FILE} is corrupted.", file=sys.stderr)
        sys.exit(1)


def save_db(data):
    """Save the CRM database to disk."""
    try:
        with open(CRM_FILE, "w") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Error saving database: {e}", file=sys.stderr)
        sys.exit(1)


def find_contact(db, email):
    """Return the contact with the given email, or None."""
    for contact in db:
        if contact["email"].lower() == email.lower():
            return contact
    return None


# --- Command Handlers ---

def handle_add(args):
    """Add a new contact. Fails if email already exists."""
    db = load_db()

    if find_contact(db, args.email):
        print(f"Error: Contact with email {args.email} already exists.", file=sys.stderr)
        sys.exit(1)

    new_contact = {
        "name": args.name,
        "email": args.email,
        "role": args.role,
        "company": args.company,
    }
    db.append(new_contact)
    save_db(db)
    print(f"Added: {args.name} ({args.email})")


def handle_list(args):
    """List all contacts in table or JSON format."""
    db = load_db()

    if args.json:
        print(json.dumps(db, indent=2))
        return

    if not db:
        print("No contacts found.")
        return

    print(f"{'NAME':<22} {'ROLE':<18} {'COMPANY':<18} {'EMAIL'}")
    print("-" * 78)
    for c in db:
        print(
            f"{c['name']:<22} {c['role']:<18} {c['company']:<18} {c['email']}"
        )
    print(f"\n{len(db)} contact(s) total.")


def handle_search(args):
    """Search contacts by name or company."""
    db = load_db()
    query = args.query.lower()
    results = [
        c
        for c in db
        if query in c["name"].lower()
        or query in c["company"].lower()
        or query in c["email"].lower()
        or query in c["role"].lower()
    ]

    if not results:
        print(f"No contacts found matching '{args.query}'", file=sys.stderr)
        sys.exit(1)

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        for c in results:
            print(f"{c['name']} ({c['role']} at {c['company']}) — {c['email']}")


def handle_delete(args):
    """
    EXERCISE 1: Delete a contact by email.

    Pattern:
    - Load DB
    - Find the contact (fail if not found)
    - Filter it out
    - Save
    """
    db = load_db()

    contact = find_contact(db, args.email)
    if not contact:
        print(f"Error: No contact found with email: {args.email}", file=sys.stderr)
        sys.exit(1)

    name = contact["name"]
    # Filter out the matching contact
    db = [c for c in db if c["email"].lower() != args.email.lower()]
    save_db(db)
    print(f"Deleted: {name} ({args.email})")


def handle_update(args):
    """
    EXERCISE 2: Update a contact's role and/or company.

    Pattern:
    - Load DB
    - Find the contact by email (fail if not found)
    - Update only the fields that were explicitly provided
    - Save
    """
    db = load_db()

    contact = find_contact(db, args.email)
    if not contact:
        print(f"Error: No contact found with email: {args.email}", file=sys.stderr)
        sys.exit(1)

    # Only update fields that were explicitly provided (not None)
    updated_fields = []
    if args.role is not None:
        contact["role"] = args.role
        updated_fields.append(f"role='{args.role}'")
    if args.company is not None:
        contact["company"] = args.company
        updated_fields.append(f"company='{args.company}'")
    if args.name is not None:
        contact["name"] = args.name
        updated_fields.append(f"name='{args.name}'")

    if not updated_fields:
        print("Warning: No fields to update. Provide --role, --company, or --name.", file=sys.stderr)
        sys.exit(1)

    save_db(db)
    print(f"Updated: {contact['name']} ({args.email}) — {', '.join(updated_fields)}")


def handle_export(args):
    """
    EXERCISE 3: Export all contacts to a CSV file.

    Pattern:
    - Load DB
    - Open output file with csv.DictWriter
    - Write header + all rows
    - Report count
    """
    db = load_db()

    output_file = args.filename

    fieldnames = ["name", "email", "role", "company"]

    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for contact in db:
            # Only write known fields (ignore any extra fields)
            writer.writerow({k: contact.get(k, "") for k in fieldnames})

    print(f"Exported {len(db)} contact(s) to {output_file}")


def handle_import(args):
    """
    EXERCISE 4: Import contacts from a CSV file.

    Pattern:
    - Load existing DB
    - Build a set of existing emails for fast lookup
    - Read the CSV
    - For each row: add if new, skip if duplicate
    - Save and report counts
    """
    if not os.path.isfile(args.filename):
        print(f"Error: File not found: {args.filename}", file=sys.stderr)
        sys.exit(1)

    db = load_db()
    existing_emails = {c["email"].lower() for c in db}

    added_count = 0
    skipped_count = 0
    error_count = 0

    try:
        with open(args.filename, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)

            if reader.fieldnames is None:
                print("Error: CSV file is empty or has no header.", file=sys.stderr)
                sys.exit(1)

            for line_num, row in enumerate(reader, start=2):
                # Validate required fields
                name = row.get("name", "").strip()
                email = row.get("email", "").strip()

                if not name or not email:
                    print(
                        f"Warning: Row {line_num} missing name or email — skipping.",
                        file=sys.stderr,
                    )
                    error_count += 1
                    continue

                if email.lower() in existing_emails:
                    skipped_count += 1
                    continue

                new_contact = {
                    "name": name,
                    "email": email,
                    "role": row.get("role", "").strip() or "Unknown",
                    "company": row.get("company", "").strip() or "Unknown",
                }
                db.append(new_contact)
                existing_emails.add(email.lower())
                added_count += 1

    except Exception as e:
        print(f"Error reading CSV: {e}", file=sys.stderr)
        sys.exit(1)

    save_db(db)
    print(
        f"Imported {added_count} new contact(s). "
        f"Skipped {skipped_count} (already exist)."
        + (f" {error_count} row(s) had errors." if error_count else "")
    )


def handle_report(args):
    """
    EXERCISE 5: Generate an HTML report of all contacts.

    Pattern:
    - Load DB
    - Build HTML string (table rows, stats)
    - Write to file
    - Report output path
    """
    db = load_db()

    output_file = args.filename
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    # Build table rows
    if db:
        rows_html = "\n".join(
            f"<tr>"
            f"<td>{c.get('name', '')}</td>"
            f"<td>{c.get('email', '')}</td>"
            f"<td>{c.get('role', '')}</td>"
            f"<td>{c.get('company', '')}</td>"
            f"</tr>"
            for c in db
        )
    else:
        rows_html = '<tr><td colspan="4" style="text-align:center;color:#888;">No contacts found.</td></tr>'

    # Count unique companies
    companies = len({c.get("company", "") for c in db if c.get("company")})

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CRM Contacts Report</title>
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
      max-width: 900px;
      margin: 40px auto;
      padding: 0 20px;
      color: #333;
      background: #f5f5f5;
    }}
    .container {{
      background: #fff;
      border-radius: 10px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.10);
      overflow: hidden;
    }}
    .header {{
      background: #1a237e;
      color: white;
      padding: 28px 32px;
    }}
    .header h1 {{ margin: 0 0 6px 0; font-size: 22px; }}
    .header .meta {{ opacity: 0.80; font-size: 13px; }}
    .stats {{
      display: flex;
      gap: 20px;
      padding: 20px 32px;
      background: #e8eaf6;
    }}
    .stat {{ text-align: center; flex: 1; }}
    .stat .value {{ font-size: 26px; font-weight: 700; color: #1a237e; }}
    .stat .label {{ font-size: 11px; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }}
    .content {{ padding: 24px 32px; }}
    table {{ width: 100%; border-collapse: collapse; }}
    th {{
      background: #1a237e;
      color: white;
      padding: 10px 12px;
      text-align: left;
      font-size: 13px;
    }}
    td {{ padding: 10px 12px; border-bottom: 1px solid #eee; font-size: 14px; }}
    tr:hover {{ background: #f5f5f5; }}
    .footer {{
      padding: 14px 32px;
      background: #f5f5f5;
      border-top: 1px solid #e0e0e0;
      font-size: 12px;
      color: #888;
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>CRM Contacts Report</h1>
      <div class="meta">Generated: {now}</div>
    </div>

    <div class="stats">
      <div class="stat">
        <div class="value">{len(db)}</div>
        <div class="label">Total Contacts</div>
      </div>
      <div class="stat">
        <div class="value">{companies}</div>
        <div class="label">Companies</div>
      </div>
    </div>

    <div class="content">
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Company</th>
          </tr>
        </thead>
        <tbody>
          {rows_html}
        </tbody>
      </table>
    </div>

    <div class="footer">CRM CLI — {len(db)} contact(s)</div>
  </div>
</body>
</html>"""

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"Report saved to {output_file} ({len(db)} contact(s))")


# --- Main CLI Logic ---

def main():
    parser = argparse.ArgumentParser(
        description="CRM CLI — manage contacts from the command line",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Commands:
  add      Add a new contact
  list     List all contacts
  search   Search by name, email, role, or company
  delete   Remove a contact by email
  update   Update a contact's role/company/name
  export   Export contacts to CSV
  import   Import contacts from CSV
  report   Generate an HTML report
""",
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # --- add ---
    add_parser = subparsers.add_parser("add", help="Add a new contact")
    add_parser.add_argument("--name", required=True, help="Contact name")
    add_parser.add_argument("--email", required=True, help="Contact email")
    add_parser.add_argument("--role", default="Employee", help="Job title")
    add_parser.add_argument("--company", default="Unknown", help="Company name")

    # --- list ---
    list_parser = subparsers.add_parser("list", help="List all contacts")
    list_parser.add_argument("--json", action="store_true", help="Output as JSON")

    # --- search ---
    search_parser = subparsers.add_parser("search", help="Search contacts")
    search_parser.add_argument("query", help="Search term")
    search_parser.add_argument("--json", action="store_true", help="Output as JSON")

    # --- delete (Exercise 1) ---
    delete_parser = subparsers.add_parser("delete", help="Remove a contact by email")
    delete_parser.add_argument("email", help="Email address of contact to delete")

    # --- update (Exercise 2) ---
    update_parser = subparsers.add_parser("update", help="Update a contact")
    update_parser.add_argument("email", help="Email address of contact to update")
    update_parser.add_argument("--name", default=None, help="New name")
    update_parser.add_argument("--role", default=None, help="New role/title")
    update_parser.add_argument("--company", default=None, help="New company")

    # --- export (Exercise 3) ---
    export_parser = subparsers.add_parser("export", help="Export contacts to CSV")
    export_parser.add_argument(
        "filename", nargs="?", default="contacts.csv", help="Output CSV file (default: contacts.csv)"
    )

    # --- import (Exercise 4) ---
    import_parser = subparsers.add_parser("import", help="Import contacts from CSV")
    import_parser.add_argument("filename", help="Input CSV file")

    # --- report (Exercise 5) ---
    report_parser = subparsers.add_parser("report", help="Generate HTML report")
    report_parser.add_argument(
        "filename", nargs="?", default="crm_report.html", help="Output HTML file (default: crm_report.html)"
    )

    args = parser.parse_args()

    dispatch = {
        "add":    handle_add,
        "list":   handle_list,
        "search": handle_search,
        "delete": handle_delete,
        "update": handle_update,
        "export": handle_export,
        "import": handle_import,
        "report": handle_report,
    }

    if args.command in dispatch:
        dispatch[args.command](args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
