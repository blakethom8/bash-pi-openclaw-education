#!/usr/bin/env python3
"""
analyze.py - Stage 1 of the data pipeline.

Reads a claims CSV file and computes statistics per category.
Outputs a stats.json file with aggregate data.

Usage:
    python3 analyze.py <input.csv> [--output <stats.json>]
    python3 analyze.py tests/sample-data.csv
    python3 analyze.py tests/sample-data.csv --output workspace/stats.json
"""

import argparse
import csv
import json
import sys
import os
from collections import defaultdict


def parse_args():
    parser = argparse.ArgumentParser(
        description="Analyze claims CSV and produce stats.json"
    )
    parser.add_argument("input_csv", help="Path to input CSV file")
    parser.add_argument(
        "--output",
        default="workspace/stats.json",
        help="Path for output stats.json (default: workspace/stats.json)",
    )
    return parser.parse_args()


def load_csv(filepath):
    """Read the CSV and return a list of row dicts. Validates required columns."""
    required_columns = {"claim_id", "provider_name", "amount", "status", "date", "category"}

    rows = []
    with open(filepath, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        # Validate columns
        if reader.fieldnames is None:
            print("Error: CSV file is empty or has no header row.", file=sys.stderr)
            sys.exit(1)

        actual_columns = set(reader.fieldnames)
        missing = required_columns - actual_columns
        if missing:
            print(
                f"Error: CSV is missing required columns: {', '.join(sorted(missing))}",
                file=sys.stderr,
            )
            sys.exit(1)

        for line_num, row in enumerate(reader, start=2):
            # Parse amount — skip rows with invalid amounts but warn
            try:
                row["amount"] = float(row["amount"])
            except (ValueError, KeyError):
                print(
                    f"Warning: Row {line_num} has invalid amount '{row.get('amount', '')}', skipping.",
                    file=sys.stderr,
                )
                continue

            rows.append(row)

    return rows


def compute_stats(rows):
    """
    Given a list of claim row dicts, compute:
    - total records
    - total amount
    - per-category: count, sum, avg, min, max
    - per-status: count, sum
    """
    if not rows:
        return {
            "total_records": 0,
            "total_amount": 0.0,
            "by_category": {},
            "by_status": {},
        }

    # Aggregate by category
    by_category = defaultdict(lambda: {"count": 0, "amounts": []})
    by_status = defaultdict(lambda: {"count": 0, "total": 0.0})

    for row in rows:
        category = row.get("category", "unknown").strip()
        status = row.get("status", "unknown").strip()
        amount = row["amount"]

        by_category[category]["count"] += 1
        by_category[category]["amounts"].append(amount)

        by_status[status]["count"] += 1
        by_status[status]["total"] += amount

    # Compute min/max/avg per category
    category_stats = {}
    for cat, data in sorted(by_category.items()):
        amounts = data["amounts"]
        category_stats[cat] = {
            "count": data["count"],
            "total": round(sum(amounts), 2),
            "average": round(sum(amounts) / len(amounts), 2),
            "min": round(min(amounts), 2),
            "max": round(max(amounts), 2),
        }

    # Clean up status stats
    status_stats = {}
    for status, data in sorted(by_status.items()):
        status_stats[status] = {
            "count": data["count"],
            "total": round(data["total"], 2),
        }

    all_amounts = [row["amount"] for row in rows]
    total_amount = round(sum(all_amounts), 2)

    return {
        "total_records": len(rows),
        "total_amount": total_amount,
        "overall_average": round(total_amount / len(rows), 2),
        "by_category": category_stats,
        "by_status": status_stats,
    }


def main():
    args = parse_args()

    # Validate input file
    if not os.path.isfile(args.input_csv):
        print(f"Error: Input file not found: {args.input_csv}", file=sys.stderr)
        sys.exit(1)

    print(f"  Loading: {args.input_csv}", file=sys.stderr)

    rows = load_csv(args.input_csv)

    if not rows:
        print("Error: No valid rows found in CSV.", file=sys.stderr)
        sys.exit(1)

    print(f"  Loaded {len(rows)} records.", file=sys.stderr)

    stats = compute_stats(rows)

    # Ensure output directory exists
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # Write stats.json
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(stats, f, indent=2)

    print(f"  Written: {args.output}", file=sys.stderr)

    # Also print a quick summary to stdout for inspection
    print(f"  Total records: {stats['total_records']}", file=sys.stderr)
    print(f"  Total amount:  ${stats['total_amount']:,.2f}", file=sys.stderr)
    print(f"  Categories:    {', '.join(stats['by_category'].keys())}", file=sys.stderr)


if __name__ == "__main__":
    main()
