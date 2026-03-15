#!/bin/bash
# lookup_npi.sh - Reusable NPI Registry API wrapper
#
# Queries the CMS NPI Registry API and outputs raw JSON to stdout.
# Designed to be composable: pipe output to jq, save to file, etc.
#
# Usage:
#   ./lookup_npi.sh <last_name> <first_name> <specialty> <state> [limit]
#
# Arguments (pass empty string "" to skip a filter):
#   last_name    Provider last name (partial match supported)
#   first_name   Provider first name (partial match supported)
#   specialty    Taxonomy description (e.g. "cardiology", "surgery")
#   state        Two-letter state code (e.g. MA, CA, TX)
#   limit        Max results to return (default: 10, max: 200)
#
# Examples:
#   ./lookup_npi.sh "Smith" "John" "cardiology" "MA"
#   ./lookup_npi.sh "Chen" "" "" "CA" 5
#   ./lookup_npi.sh "" "" "orthopedics" "TX" 20
#
#   # Composable with jq:
#   ./lookup_npi.sh "Smith" "" "cardiology" "MA" | jq '.result_count'
#   ./lookup_npi.sh "Chen" "" "" "CA" | jq '[.results[].basic.last_name]'

set -euo pipefail

NPI_API_BASE="https://npiregistry.cms.hhs.gov/api/"

# ---------------------------------------------------------------------------
# ARGUMENTS
# ---------------------------------------------------------------------------
LAST_NAME="${1:-}"
FIRST_NAME="${2:-}"
SPECIALTY="${3:-}"
STATE="${4:-}"
LIMIT="${5:-10}"

# Validate limit is a number
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
    echo "Error: limit must be a number, got: $LIMIT" >&2
    exit 1
fi

# Cap at 200 (API maximum)
if [[ "$LIMIT" -gt 200 ]]; then
    LIMIT=200
fi

# Require at least one search parameter
if [[ -z "$LAST_NAME" && -z "$FIRST_NAME" && -z "$SPECIALTY" && -z "$STATE" ]]; then
    echo "Error: At least one search parameter must be provided." >&2
    echo "Usage: $(basename "$0") <last_name> <first_name> <specialty> <state> [limit]" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# BUILD QUERY STRING
# ---------------------------------------------------------------------------
# Start with required parameters
QUERY_PARAMS="version=2.1"
QUERY_PARAMS="${QUERY_PARAMS}&enumeration_type=NPI-1"  # Individual providers only
QUERY_PARAMS="${QUERY_PARAMS}&limit=${LIMIT}"

# Add optional filters only if non-empty
[[ -n "$LAST_NAME" ]]  && QUERY_PARAMS="${QUERY_PARAMS}&last_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$LAST_NAME'))")"
[[ -n "$FIRST_NAME" ]] && QUERY_PARAMS="${QUERY_PARAMS}&first_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$FIRST_NAME'))")"
[[ -n "$SPECIALTY" ]]  && QUERY_PARAMS="${QUERY_PARAMS}&taxonomy_description=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SPECIALTY'))")"
[[ -n "$STATE" ]]       && QUERY_PARAMS="${QUERY_PARAMS}&state=${STATE}"

FULL_URL="${NPI_API_BASE}?${QUERY_PARAMS}"

# Print the URL to stderr so callers can see it (but it doesn't pollute stdout JSON)
echo "  URL: $FULL_URL" >&2

# ---------------------------------------------------------------------------
# API CALL
# ---------------------------------------------------------------------------
# -s: silent (no progress bar)
# -f: fail on HTTP errors (returns exit code 22 on 4xx/5xx)
# -L: follow redirects
# --max-time 30: timeout after 30 seconds
# --retry 2: retry up to 2 times on transient failures
response=$(curl \
    --silent \
    --fail \
    --location \
    --max-time 30 \
    --retry 2 \
    --retry-delay 1 \
    "$FULL_URL" 2>/tmp/curl_stderr)

curl_exit=$?

if [[ $curl_exit -ne 0 ]]; then
    echo "Error: curl failed (exit code $curl_exit)" >&2
    echo "Check your network connection and try again." >&2
    cat /tmp/curl_stderr >&2
    exit 1
fi

# Validate we got JSON back
if ! echo "$response" | python3 -c "import json, sys; json.load(sys.stdin)" 2>/dev/null; then
    echo "Error: API returned non-JSON response:" >&2
    echo "$response" | head -5 >&2
    exit 1
fi

# Output the raw JSON response to stdout (composable)
echo "$response"
