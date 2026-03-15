#!/bin/bash
# agent.sh - Report Generator Agent
#
# Takes a JSON data file and generates a standalone HTML report.
# Demonstrates: template rendering, self-contained HTML output, Pi read/bash/write pattern.
#
# Usage:
#   ./agent.sh <input.json> [--output <report.html>] [--title "Report Title"] [--open]
#
# Examples:
#   ./agent.sh tests/sample-input.json
#   ./agent.sh tests/sample-input.json --output ./my-report.html
#   ./agent.sh tests/sample-input.json --open

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/workspace"
DEFAULT_OUTPUT_FILE="report.html"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# ARGUMENT PARSING
# ---------------------------------------------------------------------------
print_usage() {
    echo "Usage: $(basename "$0") <input.json> [options]"
    echo ""
    echo "Options:"
    echo "  --output <file>   Output HTML file path (default: workspace/report.html)"
    echo "  --title <text>    Override the report title"
    echo "  --open            Open the report in a browser after generating"
    echo "  --help            Show this help message"
}

INPUT_JSON=""
OUTPUT_FILE=""
REPORT_TITLE=""
OPEN_AFTER=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --title)
            REPORT_TITLE="$2"
            shift 2
            ;;
        --open)
            OPEN_AFTER=true
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            print_usage >&2
            exit 1
            ;;
        *)
            if [[ -z "$INPUT_JSON" ]]; then
                INPUT_JSON="$1"
            else
                echo "Error: Unexpected argument: $1" >&2
                print_usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# VALIDATE INPUTS
# ---------------------------------------------------------------------------
if [[ -z "$INPUT_JSON" ]]; then
    echo "Error: No input JSON file specified." >&2
    print_usage >&2
    exit 1
fi

if [[ ! -f "$INPUT_JSON" ]]; then
    echo -e "${RED}Error:${NC} Input file not found: $INPUT_JSON" >&2
    exit 1
fi

# Resolve absolute paths
INPUT_JSON=$(cd "$(dirname "$INPUT_JSON")" && pwd)/$(basename "$INPUT_JSON")

if [[ -z "$OUTPUT_FILE" ]]; then
    mkdir -p "$DEFAULT_OUTPUT_DIR"
    OUTPUT_FILE="$DEFAULT_OUTPUT_DIR/$DEFAULT_OUTPUT_FILE"
fi

OUTPUT_FILE=$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Report Generator Agent${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Input:  $INPUT_JSON"
echo "  Output: $OUTPUT_FILE"
echo "────────────────────────────────────────────"

# ---------------------------------------------------------------------------
# STEP 1: READ — load and inspect the JSON data
# ---------------------------------------------------------------------------
echo ""
echo "[1/2] Loading data..."

# Validate JSON is parseable
if ! python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$INPUT_JSON" 2>/tmp/json_err; then
    echo -e "  ${RED}[FAIL]${NC} Input file is not valid JSON:" >&2
    cat /tmp/json_err >&2
    exit 1
fi

# Read summary info for display
provider_count=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(len(d.get('providers', [])))
" "$INPUT_JSON" 2>/dev/null || echo "?")

search_query=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get('search_query', 'N/A'))
" "$INPUT_JSON" 2>/dev/null || echo "N/A")

echo "  Provider count: $provider_count"
echo "  Search query:   $search_query"

# ---------------------------------------------------------------------------
# STEP 2: BASH + WRITE — run the generator
# ---------------------------------------------------------------------------
echo ""
echo "[2/2] Generating HTML report..."

# Build the command arguments
PYTHON_ARGS=("$SCRIPTS_DIR/generate_report.py" "$INPUT_JSON" "--output" "$OUTPUT_FILE")
PYTHON_ARGS+=("--template" "$TEMPLATES_DIR/report_template.html")

if [[ -n "$REPORT_TITLE" ]]; then
    PYTHON_ARGS+=("--title" "$REPORT_TITLE")
fi

# BASH tool: invoke the Python generator
if python3 "${PYTHON_ARGS[@]}" 2>/tmp/generate_err; then
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        echo -e "  ${RED}[FAIL]${NC} generate_report.py did not create output file" >&2
        exit 1
    fi

    # Get file size for display
    file_size=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
    file_size_kb=$(echo "scale=1; $file_size / 1024" | bc 2>/dev/null || echo "?")

    echo -e "  ${GREEN}[OK]${NC}   Generated: $OUTPUT_FILE (${file_size_kb} KB)"
else
    echo -e "  ${RED}[FAIL]${NC} generate_report.py failed:" >&2
    cat /tmp/generate_err >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# FINAL SUMMARY
# ---------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────────────"
echo -e "  ${GREEN}Done!${NC} Open your report:"
echo "  open $OUTPUT_FILE"
echo ""

# Optionally open in browser
if [[ "$OPEN_AFTER" == "true" ]]; then
    if command -v open &>/dev/null; then
        echo "  Opening in browser..."
        open "$OUTPUT_FILE"
    elif command -v xdg-open &>/dev/null; then
        echo "  Opening in browser..."
        xdg-open "$OUTPUT_FILE"
    else
        echo "  (Could not open browser automatically on this system)"
    fi
fi
