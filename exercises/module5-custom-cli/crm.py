#!/usr/bin/env python3
import argparse
import json
import sys
import os

# --- Configuration ---
CRM_FILE = "crm_db.json"

# --- Helper Functions ---
def load_db():
    if not os.path.exists(CRM_FILE):
        return []
    try:
        with open(CRM_FILE, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        print(f"Error: {CRM_FILE} is corrupted.", file=sys.stderr)
        sys.exit(1)

def save_db(data):
    try:
        with open(CRM_FILE, 'w') as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Error saving database: {e}", file=sys.stderr)
        sys.exit(1)

# --- Command Handlers ---
def handle_add(args):
    db = load_db()
    
    # Check for duplicates (simple email check)
    for contact in db:
        if contact['email'] == args.email:
            print(f"Error: Contact with email {args.email} already exists.", file=sys.stderr)
            sys.exit(1)
    
    new_contact = {
        "name": args.name,
        "email": args.email,
        "role": args.role,
        "company": args.company
    }
    
    db.append(new_contact)
    save_db(db)
    
    # OUTPUT: Clean text for humans/logs
    print(f"Success: Added {args.name} ({args.email})")

def handle_list(args):
    db = load_db()
    
    if args.json:
        # OUTPUT: Machine-readable JSON
        print(json.dumps(db, indent=2))
    else:
        # OUTPUT: Human-readable table
        if not db:
            print("No contacts found.")
            return

        # Simple manual formatting
        print(f"{'NAME':<20} {'ROLE':<15} {'COMPANY':<15} {'EMAIL'}")
        print("-" * 70)
        for c in db:
            print(f"{c['name']:<20} {c['role']:<15} {c['company']:<15} {c['email']}")

def handle_search(args):
    db = load_db()
    results = [c for c in db if args.query.lower() in c['name'].lower() or args.query.lower() in c['company'].lower()]
    
    if not results:
        print(f"No contacts found matching '{args.query}'", file=sys.stderr)
        sys.exit(1) # Non-zero exit code means "search failed" to scripts!
        
    if args.json:
        print(json.dumps(results, indent=2))
    else:
        for c in results:
            print(f"{c['name']} ({c['role']} at {c['company']})")

# --- Main CLI Logic ---
def main():
    parser = argparse.ArgumentParser(description="Simple CRM CLI")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Command: add
    add_parser = subparsers.add_parser("add", help="Add a new contact")
    add_parser.add_argument("--name", required=True, help="Contact name")
    add_parser.add_argument("--email", required=True, help="Contact email")
    add_parser.add_argument("--role", default="Employee", help="Job title")
    add_parser.add_argument("--company", default="Unknown", help="Company name")
    
    # Command: list
    list_parser = subparsers.add_parser("list", help="List all contacts")
    list_parser.add_argument("--json", action="store_true", help="Output in JSON format")
    
    # Command: search
    search_parser = subparsers.add_parser("search", help="Find a contact by name/company")
    search_parser.add_argument("query", help="Search term")
    search_parser.add_argument("--json", action="store_true", help="Output in JSON format")

    # Parse arguments
    args = parser.parse_args()
    
    if args.command == "add":
        handle_add(args)
    elif args.command == "list":
        handle_list(args)
    elif args.command == "search":
        handle_search(args)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
