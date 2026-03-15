#!/bin/bash
# solution/agent.sh - Report Generator Agent (Reference Solution)
#
# Complete, annotated solution demonstrating the read/bash/write pattern
# for HTML report generation.
#
# Key patterns:
#   1. READ: validate and inspect JSON input before processing
#   2. BASH: call Python generator with resolved absolute paths
#   3. WRITE: the generator creates the HTML file; bash logs the result
#   4. Separation: bash handles argument parsing + paths, Python handles content
#
# Usage:
#   ./solution/agent.sh <input.json> [--output <file>] [--title "..."] [--open]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The solution is one level deeper, so scripts and templates are in parent
SCRIPTS_DIR="$SCRIPT_DIR/../scripts"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/../workspace"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_usage() {
    echo "Usage: $(basename "$0") <input.json> [options]"
    echo ""
    echo "Options:"
    echo "  --output <file>   Output HTML file path"
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
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --title)  REPORT_TITLE="$2"; shift 2 ;;
        --open)   OPEN_AFTER=true; shift ;;
        --help|-h) print_usage; exit 0 ;;
        -*) echo "Error: Unknown option: $1" >&2; print_usage >&2; exit 1 ;;
        *)
            [[ -z "$INPUT_JSON" ]] && INPUT_JSON="$1" || {
                echo "Error: Unexpected argument: $1" >&2; exit 1
            }
            shift
            ;;
    esac
done

if [[ -z "$INPUT_JSON" ]]; then
    echo "Error: No input JSON file specified." >&2; print_usage >&2; exit 1
fi

if [[ ! -f "$INPUT_JSON" ]]; then
    echo -e "${RED}Error:${NC} Input file not found: $INPUT_JSON" >&2; exit 1
fi

# Resolve all paths to absolute before passing to Python.
# This is important because Python's working directory may differ.
INPUT_JSON=$(cd "$(dirname "$INPUT_JSON")" && pwd)/$(basename "$INPUT_JSON")

if [[ -z "$OUTPUT_FILE" ]]; then
    mkdir -p "$DEFAULT_OUTPUT_DIR"
    OUTPUT_FILE="$DEFAULT_OUTPUT_DIR/report.html"
fi
OUTPUT_FILE=$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Report Generator Agent${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Input:  $INPUT_JSON"
echo "  Output: $OUTPUT_FILE"
echo "────────────────────────────────────────────"
echo ""

# ---------------------------------------------------------------------------
# READ: validate JSON and extract summary for display
# This step is PURE — we read but don't modify anything.
# Doing this before invoking Python catches bad input early with a clear error.
# ---------------------------------------------------------------------------
echo "[1/2] Loading data..."

if ! python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$INPUT_JSON" 2>/tmp/json_err; then
    echo -e "  ${RED}[FAIL]${NC} Input is not valid JSON:" >&2
    cat /tmp/json_err >&2
    exit 1
fi

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
echo ""

# ---------------------------------------------------------------------------
# BASH: run the generator
# We pass absolute paths for all file arguments to avoid working-directory
# ambiguity. The Python script handles the actual HTML rendering logic.
# ---------------------------------------------------------------------------
echo "[2/2] Generating HTML report..."

PYTHON_ARGS=(
    "$SCRIPTS_DIR/generate_report.py"
    "$INPUT_JSON"
    "--output" "$OUTPUT_FILE"
    "--template" "$TEMPLATES_DIR/report_template.html"
)
[[ -n "$REPORT_TITLE" ]] && PYTHON_ARGS+=("--title" "$REPORT_TITLE")

if python3 "${PYTHON_ARGS[@]}" 2>/tmp/generate_err; then
    file_size_kb=$(echo "scale=1; $(wc -c < "$OUTPUT_FILE") / 1024" | bc 2>/dev/null || echo "?")
    echo -e "  ${GREEN}[OK]${NC}   Generated: $OUTPUT_FILE (${file_size_kb} KB)"
else
    echo -e "  ${RED}[FAIL]${NC} Generator failed:" >&2
    cat /tmp/generate_err >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# WRITE: print the final output path for downstream use.
# In a real pipeline this is where you'd:
#   - Email the report: mail -s "Report" team@example.com < "$OUTPUT_FILE"
#   - Copy to a shared drive: cp "$OUTPUT_FILE" /mnt/reports/
#   - Post to a Slack channel: curl -F file=@"$OUTPUT_FILE" ...
# ---------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────────────"
echo -e "  ${GREEN}Done!${NC} Open your report:"
echo "  open $OUTPUT_FILE"
echo ""

if [[ "$OPEN_AFTER" == "true" ]]; then
    if command -v open &>/dev/null; then
        open "$OUTPUT_FILE"
    elif command -v xdg-open &>/dev/null; then
        xdg-open "$OUTPUT_FILE"
    fi
fi

# ---------------------------------------------------------------------------
# Key lessons:
#
# 1. Validate JSON BEFORE invoking Python — fail fast with a clear message
# 2. Resolve to absolute paths — eliminates working directory bugs
# 3. Pass template as argument — makes the template swappable without code change
# 4. The WRITE step (saving the file) happens inside Python, not bash
#    bash only reports what was written and where
# 5. The final echo is composable: other scripts can call this and parse the path
# ---------------------------------------------------------------------------
