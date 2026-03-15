#!/usr/bin/env python3
"""
generate_report.py - Generates a standalone HTML report from JSON data.

Reads a JSON input file containing provider search results, applies the HTML
template, and writes a self-contained report file.

Usage:
    python3 generate_report.py <input.json> [options]

Options:
    --output <file>       Output HTML file (default: workspace/report.html)
    --template <file>     HTML template file (default: templates/report_template.html)
    --title <text>        Override the report title
"""

import argparse
import json
import os
import sys
from datetime import datetime


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate an HTML report from provider search JSON"
    )
    parser.add_argument("input_json", help="Path to JSON input file")
    parser.add_argument(
        "--output",
        default="workspace/report.html",
        help="Output HTML file (default: workspace/report.html)",
    )
    parser.add_argument(
        "--template",
        default="templates/report_template.html",
        help="HTML template file",
    )
    parser.add_argument("--title", default="", help="Override report title")
    return parser.parse_args()


def load_json(filepath):
    """Load and return JSON data from a file."""
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def load_template(filepath):
    """Load the HTML template file."""
    if not os.path.isfile(filepath):
        print(f"Error: Template file not found: {filepath}", file=sys.stderr)
        sys.exit(1)
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


def badge_html(text, style="blue"):
    """Wrap text in a styled badge span."""
    return f'<span class="badge badge-{style}">{text}</span>'


def network_badge(status):
    """Return colored badge HTML for a network status string."""
    status_lower = status.lower()
    if "in-network" in status_lower or "in_network" in status_lower:
        return badge_html(status, "green")
    elif "out" in status_lower:
        return badge_html(status, "red")
    else:
        return badge_html(status, "orange")


def accepting_badge(accepting):
    """Return colored badge for accepting_patients boolean."""
    if accepting:
        return badge_html("Accepting", "green")
    else:
        return badge_html("Not Accepting", "red")


def build_provider_table(providers):
    """Build an HTML table for a list of provider dicts."""
    if not providers:
        return "<p>No providers found.</p>"

    # Determine columns based on keys present in first record
    sample = providers[0]
    has_npi = "npi" in sample
    has_phone = "phone" in sample
    has_network = "network_status" in sample
    has_accepting = "accepting_patients" in sample

    # Table header
    cols = ["Name", "Specialty", "Address"]
    if has_phone:
        cols.append("Phone")
    if has_npi:
        cols.append("NPI")
    if has_network:
        cols.append("Network")
    if has_accepting:
        cols.append("Accepting")

    header_cells = "".join(f"<th>{col}</th>" for col in cols)
    rows_html = [f"<thead><tr>{header_cells}</tr></thead>"]

    rows_html.append("<tbody>")
    for provider in providers:
        cells = [
            f"<td><strong>{provider.get('name', 'N/A')}</strong></td>",
            f"<td>{provider.get('specialty', 'N/A')}</td>",
            f"<td>{provider.get('address', 'N/A')}</td>",
        ]
        if has_phone:
            cells.append(f"<td>{provider.get('phone', 'N/A')}</td>")
        if has_npi:
            cells.append(f"<td><code>{provider.get('npi', 'N/A')}</code></td>")
        if has_network:
            cells.append(f"<td>{network_badge(provider.get('network_status', 'unknown'))}</td>")
        if has_accepting:
            cells.append(f"<td>{accepting_badge(provider.get('accepting_patients', False))}</td>")

        rows_html.append(f"<tr>{''.join(cells)}</tr>")

    rows_html.append("</tbody>")
    return f"<table>{''.join(rows_html)}</table>"


def build_stat_cards(providers, data):
    """Build stat card HTML blocks for the summary grid."""
    total = len(providers)
    accepting = sum(1 for p in providers if p.get("accepting_patients", False))
    in_network = sum(
        1
        for p in providers
        if "in-network" in p.get("network_status", "").lower()
        or "in_network" in p.get("network_status", "").lower()
    )

    # Unique specialties
    specialties = set(p.get("specialty", "").strip() for p in providers if p.get("specialty"))

    cards = [
        ("total", str(total), "Total Providers"),
        ("accepting", str(accepting), "Accepting Patients"),
        ("network", str(in_network), "In-Network"),
        ("specialties", str(len(specialties)), "Specialties"),
    ]

    html_parts = []
    for _, value, label in cards:
        html_parts.append(
            f'<div class="stat-card">'
            f'<div class="value">{value}</div>'
            f'<div class="label">{label}</div>'
            f"</div>"
        )
    return "\n        ".join(html_parts)


def build_summary_text(providers, data):
    """Build a narrative summary paragraph."""
    total = len(providers)
    search_query = data.get("search_query", "")
    accepting = sum(1 for p in providers if p.get("accepting_patients", False))
    in_network = sum(
        1
        for p in providers
        if "in-network" in p.get("network_status", "").lower()
        or "in_network" in p.get("network_status", "").lower()
    )
    specialties = sorted(
        set(p.get("specialty", "").strip() for p in providers if p.get("specialty"))
    )

    lines = []
    if search_query:
        lines.append(f"Search results for: <strong>{search_query}</strong>")
    lines.append(
        f"Found <strong>{total} providers</strong>, "
        f"of which <strong>{accepting}</strong> are accepting new patients "
        f"and <strong>{in_network}</strong> are in-network."
    )
    if specialties:
        spec_list = ", ".join(specialties[:5])
        if len(specialties) > 5:
            spec_list += f", and {len(specialties) - 5} more"
        lines.append(f"Specialties covered: {spec_list}.")

    return " ".join(lines)


def render_template(template_html, replacements):
    """Replace all {{KEY}} placeholders in the template with values."""
    result = template_html
    for key, value in replacements.items():
        result = result.replace("{{" + key + "}}", value)
    return result


def main():
    args = parse_args()

    if not os.path.isfile(args.input_json):
        print(f"Error: Input file not found: {args.input_json}", file=sys.stderr)
        sys.exit(1)

    print(f"  Loading: {args.input_json}", file=sys.stderr)
    data = load_json(args.input_json)

    providers = data.get("providers", [])
    if not providers:
        print("Warning: No providers found in input JSON.", file=sys.stderr)

    print(f"  Loaded {len(providers)} providers.", file=sys.stderr)

    # Load the HTML template
    template_path = args.template
    # If template path is relative, try resolving relative to this script's directory
    if not os.path.isabs(template_path) and not os.path.isfile(template_path):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        candidate = os.path.join(script_dir, "..", template_path)
        if os.path.isfile(candidate):
            template_path = candidate

    template_html = load_template(template_path)

    # Determine the report title
    title = args.title
    if not title:
        search_query = data.get("search_query", "")
        if search_query:
            title = f"Provider Search Results — {search_query.title()}"
        else:
            title = "Provider Report"

    # Build template values
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    provider_count = len(providers)
    meta_line = data.get("generated_at", now)

    replacements = {
        "TITLE": title,
        "DATE": now,
        "META_LINE": f"{provider_count} providers &nbsp;|&nbsp; {meta_line}",
        "STAT_CARDS": build_stat_cards(providers, data),
        "SUMMARY": build_summary_text(providers, data),
        "TABLE_TITLE": "Provider Directory",
        "TABLE": build_provider_table(providers),
    }

    html_content = render_template(template_html, replacements)

    # Ensure output directory exists
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html_content)

    print(f"  Written: {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
