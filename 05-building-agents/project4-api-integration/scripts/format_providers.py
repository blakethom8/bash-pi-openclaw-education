#!/usr/bin/env python3
"""
format_providers.py - Format normalized provider JSON into a readable report.

Reads the providers.json file produced by the NPI lookup agent (after jq processing)
and outputs a text or HTML report.

Usage:
    python3 format_providers.py <providers.json> [options]

Options:
    --output <file>    Output file path (default: workspace/report.txt)
    --format txt|html  Report format (default: txt)
    --query <text>     Query description for the report header
"""

import argparse
import json
import os
import sys
from datetime import datetime


def parse_args():
    parser = argparse.ArgumentParser(description="Format NPI lookup results into a report")
    parser.add_argument("providers_json", help="Path to normalized providers.json")
    parser.add_argument(
        "--output", default="workspace/report.txt", help="Output file path"
    )
    parser.add_argument(
        "--format", choices=["txt", "html"], default="txt", help="Output format"
    )
    parser.add_argument("--query", default="", help="Query description for report header")
    return parser.parse_args()


def load_providers(filepath):
    """Load providers from JSON file."""
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def format_address(address):
    """Format an address dict into a single string."""
    if not address:
        return "Address not available"
    parts = []
    if address.get("street"):
        parts.append(address["street"].title())
    city = address.get("city", "").title()
    state = address.get("state", "")
    zip_code = address.get("zip", "")
    if city and state:
        parts.append(f"{city}, {state} {zip_code}".strip())
    return ", ".join(parts) if parts else "Address not available"


def format_name(provider):
    """Format provider's full name with credential."""
    first = provider.get("first_name", "").title()
    last = provider.get("last_name", "").title()
    cred = provider.get("credential", "")
    name = f"Dr. {first} {last}".strip()
    if cred:
        name = f"{name} {cred}"
    return name


def render_text(providers, query):
    """Render a plain-text report."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines = []

    sep = "─" * 52

    lines.append("NPI REGISTRY LOOKUP RESULTS")
    lines.append(f"Generated: {now}")
    if query:
        lines.append(f"Query:     {query}")
    lines.append(f"Total:     {len(providers)} provider(s)")
    lines.append(sep)

    for i, provider in enumerate(providers, start=1):
        name = format_name(provider)
        npi = provider.get("npi", "N/A")
        specialty = provider.get("specialty", "N/A")
        address = format_address(provider.get("address"))
        phone = ""
        if provider.get("address") and provider["address"].get("phone"):
            phone = provider["address"]["phone"]
        status = provider.get("status", "")

        lines.append(f"  {i}. {name}")
        lines.append(f"     NPI:       {npi}")
        lines.append(f"     Specialty: {specialty}")
        lines.append(f"     Address:   {address}")
        if phone:
            lines.append(f"     Phone:     {phone}")
        if status:
            lines.append(f"     Status:    {status}")

        if i < len(providers):
            lines.append("")

    lines.append(sep)
    lines.append(f"  {len(providers)} result(s) | NPI Registry | {now}")

    return "\n".join(lines)


def render_html(providers, query):
    """Render an HTML report."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    rows_html = []
    for provider in providers:
        name = format_name(provider)
        npi = provider.get("npi", "N/A")
        specialty = provider.get("specialty", "N/A")
        address = format_address(provider.get("address"))
        phone = ""
        if provider.get("address") and provider["address"].get("phone"):
            phone = provider["address"]["phone"]
        status = provider.get("status", "")

        status_badge = ""
        if status.upper() == "A":
            status_badge = '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:10px;font-size:12px;">Active</span>'
        elif status:
            status_badge = f'<span style="background:#fff3e0;color:#e65100;padding:2px 8px;border-radius:10px;font-size:12px;">{status}</span>'

        rows_html.append(
            f"<tr>"
            f"<td><strong>{name}</strong>{' ' + status_badge if status_badge else ''}</td>"
            f"<td><code>{npi}</code></td>"
            f"<td>{specialty}</td>"
            f"<td>{address}</td>"
            f"<td>{phone}</td>"
            f"</tr>"
        )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NPI Lookup Results</title>
  <style>
    body {{ font-family: Arial, sans-serif; max-width: 1100px; margin: 40px auto; padding: 0 20px; color: #333; }}
    h1 {{ color: #1a237e; font-size: 22px; }}
    .meta {{ color: #666; font-size: 14px; margin-bottom: 20px; }}
    table {{ width: 100%; border-collapse: collapse; }}
    th {{ background: #1a237e; color: white; padding: 10px 12px; text-align: left; }}
    td {{ padding: 10px 12px; border-bottom: 1px solid #e0e0e0; font-size: 14px; }}
    tr:hover {{ background: #f5f5f5; }}
    code {{ background: #f0f0f0; padding: 2px 6px; border-radius: 4px; font-size: 13px; }}
  </style>
</head>
<body>
  <h1>NPI Registry Lookup Results</h1>
  <div class="meta">
    Generated: {now}{f' &nbsp;|&nbsp; Query: {query}' if query else ''}
    &nbsp;|&nbsp; {len(providers)} provider(s) found
  </div>
  <table>
    <thead>
      <tr>
        <th>Provider</th>
        <th>NPI</th>
        <th>Specialty</th>
        <th>Address</th>
        <th>Phone</th>
      </tr>
    </thead>
    <tbody>
      {"".join(rows_html)}
    </tbody>
  </table>
</body>
</html>"""


def main():
    args = parse_args()

    if not os.path.isfile(args.providers_json):
        print(f"Error: File not found: {args.providers_json}", file=sys.stderr)
        sys.exit(1)

    providers = load_providers(args.providers_json)

    if not providers:
        print("Warning: No providers in input JSON.", file=sys.stderr)

    if args.format == "txt":
        content = render_text(providers, args.query)
    else:
        content = render_html(providers, args.query)

    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  Written: {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
