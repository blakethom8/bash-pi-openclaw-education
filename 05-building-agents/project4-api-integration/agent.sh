#!/bin/bash
# agent.sh - NPI Lookup Agent
#
# Queries the CMS NPI Registry API to find healthcare providers.
# Demonstrates: curl in agents, jq processing, composable bash wrappers.
#
# Usage:
#   ./agent.sh [--name "Last First"] [--first <first>] [--last <last>]
#              [--specialty <specialty>] [--state <ST>] [--limit <n>]
#              [--output <file>] [--mock] [--format txt|html]
#
# Examples:
#   ./agent.sh --last "Smith" --specialty "cardiology" --state MA
#   ./agent.sh --name "John Chen" --state CA
#   ./agent.sh --mock

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
WORKSPACE="$SCRIPT_DIR/workspace"
MOCK_RESPONSE="$SCRIPT_DIR/tests/mock-response.json"

NPI_API_BASE="https://npiregistry.cms.hhs.gov/api/"
DEFAULT_LIMIT=10
OUTPUT_FORMAT="txt"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# ARGUMENT PARSING
# ---------------------------------------------------------------------------
print_usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Search options:"
    echo "  --name <'Last First'>    Full name search (splits on space)"
    echo "  --first <first_name>     First name"
    echo "  --last <last_name>       Last name"
    echo "  --specialty <specialty>  Taxonomy description (e.g. 'cardiology')"
    echo "  --state <ST>             Two-letter state code (e.g. MA, CA)"
    echo "  --limit <n>              Max results (default: 10)"
    echo ""
    echo "Output options:"
    echo "  --output <file>          Save providers.json to this path"
    echo "  --format txt|html        Report format (default: txt)"
    echo "  --mock                   Use mock response (no API call)"
    echo "  --help                   Show this help"
}

FIRST_NAME=""
LAST_NAME=""
SPECIALTY=""
STATE=""
LIMIT="$DEFAULT_LIMIT"
OUTPUT_FILE=""
USE_MOCK=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            # Split "Last First" or "First Last" — we'll treat as last name for NPI API
            LAST_NAME=$(echo "$2" | awk '{print $NF}')
            FIRST_NAME=$(echo "$2" | awk '{print $1}')
            shift 2
            ;;
        --first)    FIRST_NAME="$2"; shift 2 ;;
        --last)     LAST_NAME="$2"; shift 2 ;;
        --specialty) SPECIALTY="$2"; shift 2 ;;
        --state)    STATE="$2"; shift 2 ;;
        --limit)    LIMIT="$2"; shift 2 ;;
        --output)   OUTPUT_FILE="$2"; shift 2 ;;
        --format)
            OUTPUT_FORMAT="$2"
            if [[ "$OUTPUT_FORMAT" != "txt" && "$OUTPUT_FORMAT" != "html" ]]; then
                echo "Error: --format must be 'txt' or 'html'" >&2; exit 1
            fi
            shift 2
            ;;
        --mock)     USE_MOCK=true; shift ;;
        --help|-h)  print_usage; exit 0 ;;
        -*)         echo "Error: Unknown option: $1" >&2; print_usage >&2; exit 1 ;;
        *)          echo "Error: Unexpected argument: $1" >&2; print_usage >&2; exit 1 ;;
    esac
done

# Require at least one search parameter (unless using mock)
if [[ "$USE_MOCK" == "false" ]]; then
    if [[ -z "$FIRST_NAME" && -z "$LAST_NAME" && -z "$SPECIALTY" ]]; then
        echo "Error: Provide at least one of --name, --last, --first, or --specialty" >&2
        print_usage >&2
        exit 1
    fi
fi

mkdir -p "$WORKSPACE"
RAW_RESPONSE_FILE="$WORKSPACE/raw_response.json"
PROVIDERS_FILE="${OUTPUT_FILE:-$WORKSPACE/providers.json}"
REPORT_FILE="$WORKSPACE/report.$OUTPUT_FORMAT"

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  NPI Lookup Agent${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Build a human-readable query description
QUERY_DESC=""
[[ -n "$LAST_NAME" ]]   && QUERY_DESC="${QUERY_DESC}last=${LAST_NAME} "
[[ -n "$FIRST_NAME" ]]  && QUERY_DESC="${QUERY_DESC}first=${FIRST_NAME} "
[[ -n "$SPECIALTY" ]]   && QUERY_DESC="${QUERY_DESC}specialty=${SPECIALTY} "
[[ -n "$STATE" ]]        && QUERY_DESC="${QUERY_DESC}state=${STATE} "
[[ "$USE_MOCK" == "true" ]] && QUERY_DESC="[MOCK DATA]"
echo "  Query: ${QUERY_DESC:-all}"
echo "────────────────────────────────────────────"

# ---------------------------------------------------------------------------
# STEP 1: API CALL (BASH tool)
# ---------------------------------------------------------------------------
echo ""
echo "[1/3] Calling NPI Registry API..."

if [[ "$USE_MOCK" == "true" ]]; then
    if [[ ! -f "$MOCK_RESPONSE" ]]; then
        echo -e "  ${RED}Error:${NC} Mock response file not found: $MOCK_RESPONSE" >&2
        exit 1
    fi
    cp "$MOCK_RESPONSE" "$RAW_RESPONSE_FILE"
    echo -e "  ${YELLOW}[MOCK]${NC} Using: $MOCK_RESPONSE"
else
    # Check prerequisites
    if ! command -v curl &>/dev/null; then
        echo -e "  ${RED}Error:${NC} curl is required but not installed." >&2
        exit 1
    fi
    if ! command -v jq &>/dev/null; then
        echo -e "  ${RED}Error:${NC} jq is required but not installed." >&2
        echo "  Install with: brew install jq  (macOS)  or  apt-get install jq  (Linux)" >&2
        exit 1
    fi

    # BASH tool: call the lookup wrapper script
    # lookup_npi.sh outputs the raw JSON to stdout
    echo "  Using: scripts/lookup_npi.sh"

    if bash "$SCRIPTS_DIR/lookup_npi.sh" \
        "$LAST_NAME" "$FIRST_NAME" "$SPECIALTY" "$STATE" "$LIMIT" \
        > "$RAW_RESPONSE_FILE" 2>/tmp/curl_err; then
        echo -e "  ${GREEN}[OK]${NC}   Response saved to $RAW_RESPONSE_FILE"
    else
        echo -e "  ${RED}[FAIL]${NC} API call failed:" >&2
        cat /tmp/curl_err >&2
        exit 1
    fi
fi

# Validate response is valid JSON
if ! jq empty "$RAW_RESPONSE_FILE" 2>/tmp/jq_err; then
    echo -e "  ${RED}[FAIL]${NC} API returned invalid JSON:" >&2
    cat /tmp/jq_err >&2
    exit 1
fi

# Extract result count
result_count=$(jq '.result_count // 0' "$RAW_RESPONSE_FILE" 2>/dev/null || echo "0")
echo "  Results: $result_count provider(s) found"

if [[ "$result_count" -eq 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}No providers found.${NC}"
    echo "  Try broadening your search (fewer filters, different spelling)."
    exit 0
fi

# ---------------------------------------------------------------------------
# STEP 2: PROCESS AND SAVE (BASH + WRITE tools)
# ---------------------------------------------------------------------------
echo ""
echo "[2/3] Processing results..."

# Use jq to extract normalized fields from the NPI response
# This transforms the complex nested NPI structure into a clean flat JSON
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

# ---------------------------------------------------------------------------
# DISPLAY REPORT
# ---------------------------------------------------------------------------
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
