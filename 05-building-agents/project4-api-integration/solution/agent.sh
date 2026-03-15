#!/bin/bash
# solution/agent.sh - NPI Lookup Agent (Reference Solution)
#
# Complete, annotated reference solution.
#
# Key patterns demonstrated:
#   1. curl as the BASH tool: it's just another command — same pattern as mv/mkdir
#   2. jq as a data processor: transforms nested JSON into clean flat JSON
#   3. Reusable wrapper (lookup_npi.sh): composable, testable, single responsibility
#   4. --mock flag: swap real API for test data — same code path, different input
#   5. Graceful error handling: check exit codes, validate JSON, fail with clear messages
#
# Usage:
#   ./solution/agent.sh [--name "..."] [--specialty "..."] [--state XX] [--mock]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/../scripts"
WORKSPACE="$SCRIPT_DIR/../workspace"
MOCK_RESPONSE="$SCRIPT_DIR/../tests/mock-response.json"

DEFAULT_LIMIT=10

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "  --name <'Last First'>    Full name (splits on last word)"
    echo "  --first <first>          First name"
    echo "  --last <last>            Last name"
    echo "  --specialty <s>          Taxonomy (e.g. 'cardiology')"
    echo "  --state <ST>             Two-letter state code"
    echo "  --limit <n>              Max results (default: 10)"
    echo "  --output <file>          providers.json output path"
    echo "  --format txt|html        Report format (default: txt)"
    echo "  --mock                   Use mock data (no API call)"
    echo "  --help                   Show this help"
}

FIRST_NAME=""
LAST_NAME=""
SPECIALTY=""
STATE=""
LIMIT="$DEFAULT_LIMIT"
OUTPUT_FILE=""
OUTPUT_FORMAT="txt"
USE_MOCK=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            LAST_NAME=$(echo "$2" | awk '{print $NF}')
            FIRST_NAME=$(echo "$2" | awk '{print $1}')
            shift 2
            ;;
        --first)     FIRST_NAME="$2"; shift 2 ;;
        --last)      LAST_NAME="$2"; shift 2 ;;
        --specialty) SPECIALTY="$2"; shift 2 ;;
        --state)     STATE="$2"; shift 2 ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --output)    OUTPUT_FILE="$2"; shift 2 ;;
        --format)    OUTPUT_FORMAT="$2"; shift 2 ;;
        --mock)      USE_MOCK=true; shift ;;
        --help|-h)   print_usage; exit 0 ;;
        -*)          echo "Error: Unknown option: $1" >&2; print_usage >&2; exit 1 ;;
        *)           echo "Error: Unexpected argument: $1" >&2; exit 1 ;;
    esac
done

if [[ "$USE_MOCK" == "false" ]]; then
    if [[ -z "$FIRST_NAME" && -z "$LAST_NAME" && -z "$SPECIALTY" ]]; then
        echo "Error: Provide at least one search parameter." >&2
        print_usage >&2; exit 1
    fi
fi

mkdir -p "$WORKSPACE"
RAW_RESPONSE_FILE="$WORKSPACE/raw_response.json"
PROVIDERS_FILE="${OUTPUT_FILE:-$WORKSPACE/providers.json}"
REPORT_FILE="$WORKSPACE/report.$OUTPUT_FORMAT"

# Build query description
QUERY_DESC=""
[[ -n "$LAST_NAME" ]]  && QUERY_DESC="${QUERY_DESC}last=${LAST_NAME} "
[[ -n "$FIRST_NAME" ]] && QUERY_DESC="${QUERY_DESC}first=${FIRST_NAME} "
[[ -n "$SPECIALTY" ]]  && QUERY_DESC="${QUERY_DESC}specialty=${SPECIALTY} "
[[ -n "$STATE" ]]       && QUERY_DESC="${QUERY_DESC}state=${STATE} "
[[ "$USE_MOCK" == "true" ]] && QUERY_DESC="[MOCK DATA]"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  NPI Lookup Agent${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Query: ${QUERY_DESC:-all}"
echo "────────────────────────────────────────────"

# ---------------------------------------------------------------------------
# STEP 1: API CALL (BASH tool)
#
# The key pattern: the actual HTTP call is wrapped in lookup_npi.sh.
# This agent just calls that script like any other tool.
# Output goes to a file so downstream steps can read it independently.
# ---------------------------------------------------------------------------
echo ""
echo "[1/3] Calling NPI Registry API..."

if [[ "$USE_MOCK" == "true" ]]; then
    # --mock: swap the API for a local file. Same code path, different source.
    # This is how you test agents without network access.
    cp "$MOCK_RESPONSE" "$RAW_RESPONSE_FILE"
    echo -e "  ${YELLOW}[MOCK]${NC} Using: $MOCK_RESPONSE"
else
    # Check prerequisites before trying to call them
    for cmd in curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "  ${RED}Error:${NC} $cmd is required but not installed." >&2
            exit 1
        fi
    done

    # BASH tool: call the lookup wrapper
    if bash "$SCRIPTS_DIR/lookup_npi.sh" \
        "$LAST_NAME" "$FIRST_NAME" "$SPECIALTY" "$STATE" "$LIMIT" \
        > "$RAW_RESPONSE_FILE" 2>/tmp/lookup_err; then
        true
    else
        echo -e "  ${RED}[FAIL]${NC} Lookup failed:" >&2
        cat /tmp/lookup_err >&2
        exit 1
    fi
fi

# Validate JSON (always, even for mock data)
if ! jq empty "$RAW_RESPONSE_FILE" 2>/dev/null; then
    echo -e "  ${RED}[FAIL]${NC} Response is not valid JSON" >&2; exit 1
fi

result_count=$(jq '.result_count // 0' "$RAW_RESPONSE_FILE")
echo -e "  ${GREEN}[OK]${NC}   $result_count provider(s) found"

if [[ "$result_count" -eq 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}No providers found.${NC} Try broadening your search."
    exit 0
fi

# ---------------------------------------------------------------------------
# STEP 2: NORMALIZE WITH jq (BASH + WRITE tools)
#
# The NPI API returns deeply nested JSON. jq flattens it into a clean structure
# that's easy for Python (and humans) to work with.
#
# This normalization step is the EDIT tool equivalent — transforming data
# from one format to another.
# ---------------------------------------------------------------------------
echo ""
echo "[2/3] Processing results..."

jq '[.results[] | {
    npi: .number,
    first_name: (.basic.first_name // ""),
    last_name: (.basic.last_name // ""),
    credential: (.basic.credential // ""),
    gender: (.basic.gender // ""),
    status: (.basic.status // ""),
    specialty: (
        .taxonomies
        | map(select(.primary == true))
        | first
        | .desc // ""
    ),
    address: (
        .addresses
        | map(select(.address_purpose == "LOCATION"))
        | first
        | {
            street: .address_1,
            city: .city,
            state: .state,
            zip: .postal_code,
            phone: .telephone_number
          }
    )
}]' "$RAW_RESPONSE_FILE" > "$PROVIDERS_FILE"

echo -e "  ${GREEN}[OK]${NC}   providers.json: $PROVIDERS_FILE"

# ---------------------------------------------------------------------------
# STEP 3: FORMAT REPORT (BASH → WRITE tools)
# ---------------------------------------------------------------------------
echo ""
echo "[3/3] Generating report..."

if python3 "$SCRIPTS_DIR/format_providers.py" \
    "$PROVIDERS_FILE" \
    --output "$REPORT_FILE" \
    --format "$OUTPUT_FORMAT" \
    --query "${QUERY_DESC:-}" \
    2>/tmp/format_err; then
    echo -e "  ${GREEN}[OK]${NC}   Report: $REPORT_FILE"
else
    echo -e "  ${RED}[FAIL]${NC} Report generation failed:" >&2
    cat /tmp/format_err >&2
    exit 1
fi

# Display text report inline
if [[ "$OUTPUT_FORMAT" == "txt" ]]; then
    echo ""
    echo "────────────────────────────────────────────"
    cat "$REPORT_FILE"
fi

echo ""
echo "────────────────────────────────────────────"
echo -e "  ${GREEN}Done!${NC}"
echo "  Raw response: $RAW_RESPONSE_FILE"
echo "  Providers:    $PROVIDERS_FILE"
echo "  Report:       $REPORT_FILE"
echo ""

# ---------------------------------------------------------------------------
# Key lessons:
#
# 1. curl is just a BASH tool — same pattern as mv or mkdir
# 2. jq is the EDIT tool for JSON — transform, filter, reshape
# 3. Wrapper scripts (lookup_npi.sh) make each operation composable
# 4. --mock lets you test the full pipeline without network calls
# 5. Validate JSON at each step — don't pass bad data forward
# 6. result_count=0 is a valid response, not an error — handle it gracefully
# ---------------------------------------------------------------------------
