#!/bin/bash
# agent.sh - Data Pipeline Agent
#
# Orchestrates a two-stage data pipeline:
#   Stage 1: CSV → stats.json (via analyze.py)
#   Stage 2: stats.json → report.md (via render_report.py)
#
# Demonstrates: bash orchestration, file-based checkpointing, error handling
#
# Usage:
#   ./agent.sh <input.csv> [--output <dir>] [--resume] [--format html|md]
#
# Examples:
#   ./agent.sh tests/sample-data.csv
#   ./agent.sh tests/sample-data.csv --output ./reports/
#   ./agent.sh tests/sample-data.csv --resume

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Default output directory (workspace for intermediate files)
OUTPUT_DIR="$SCRIPT_DIR/workspace"

# Checkpoint files (used for --resume support)
CHECKPOINT_ANALYZE=".checkpoint_analyze"
CHECKPOINT_REPORT=".checkpoint_report"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------------------------
print_usage() {
    echo "Usage: $(basename "$0") <input.csv> [options]"
    echo ""
    echo "Options:"
    echo "  --output <dir>   Output directory (default: ./workspace/)"
    echo "  --resume         Skip stages that already have checkpoint files"
    echo "  --format <fmt>   Report format: md or html (default: md)"
    echo "  --help           Show this help message"
}

step_ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

step_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1" >&2
}

step_info() {
    echo "  $1"
}

stage_header() {
    local stage_num="$1"
    local total="$2"
    local description="$3"
    echo ""
    echo -e "${BLUE}[Stage $stage_num/$total]${NC} $description"
}

# ---------------------------------------------------------------------------
# ARGUMENT PARSING
# ---------------------------------------------------------------------------
INPUT_CSV=""
RESUME=false
REPORT_FORMAT="md"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --resume)
            RESUME=true
            shift
            ;;
        --format)
            REPORT_FORMAT="$2"
            if [[ "$REPORT_FORMAT" != "md" && "$REPORT_FORMAT" != "html" ]]; then
                echo "Error: --format must be 'md' or 'html'" >&2
                exit 1
            fi
            shift 2
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
            if [[ -z "$INPUT_CSV" ]]; then
                INPUT_CSV="$1"
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
if [[ -z "$INPUT_CSV" ]]; then
    echo "Error: No input CSV file specified." >&2
    print_usage >&2
    exit 1
fi

if [[ ! -f "$INPUT_CSV" ]]; then
    echo -e "${RED}Error:${NC} Input file not found: $INPUT_CSV" >&2
    exit 1
fi

# Resolve to absolute paths
INPUT_CSV=$(cd "$(dirname "$INPUT_CSV")" && pwd)/$(basename "$INPUT_CSV")
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)

STATS_FILE="$OUTPUT_DIR/stats.json"
REPORT_FILE="$OUTPUT_DIR/report.md"
CHECKPOINT_ANALYZE_PATH="$OUTPUT_DIR/$CHECKPOINT_ANALYZE"
CHECKPOINT_REPORT_PATH="$OUTPUT_DIR/$CHECKPOINT_REPORT"

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Data Pipeline Agent${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Input:  $INPUT_CSV"
echo "  Output: $OUTPUT_DIR"
if [[ "$RESUME" == "true" ]]; then
    echo -e "  Mode:   ${YELLOW}RESUME${NC} (using checkpoints where available)"
fi
echo "────────────────────────────────────────────"

# ---------------------------------------------------------------------------
# STAGE 1: ANALYZE — CSV → stats.json
# Pi pattern: READ (csv) → BASH (analyze.py) → WRITE (stats.json + checkpoint)
# ---------------------------------------------------------------------------
stage_header 1 2 "Analyzing data..."

SKIP_ANALYZE=false
if [[ "$RESUME" == "true" && -f "$CHECKPOINT_ANALYZE_PATH" && -f "$STATS_FILE" ]]; then
    step_info "Checkpoint found, skipping analysis."
    SKIP_ANALYZE=true
fi

if [[ "$SKIP_ANALYZE" == "false" ]]; then
    step_info "Running: python3 scripts/analyze.py"

    # BASH tool: run the Python script
    # Capture stderr separately so we can show it on failure
    if python3 "$SCRIPTS_DIR/analyze.py" "$INPUT_CSV" --output "$STATS_FILE" 2>/tmp/analyze_err; then
        # Validate the output exists and is non-empty
        if [[ ! -f "$STATS_FILE" ]]; then
            step_fail "analyze.py did not create $STATS_FILE"
            exit 1
        fi

        if [[ ! -s "$STATS_FILE" ]]; then
            step_fail "analyze.py created an empty stats.json"
            exit 1
        fi

        # Extract summary info from the stats file for display
        record_count=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('total_records', '?'))" 2>/dev/null || echo "?")
        category_count=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(len(d.get('by_category', {})))" 2>/dev/null || echo "?")

        step_ok "Stats file created: $STATS_FILE"
        step_info "Records processed: $record_count"
        step_info "Categories found:  $category_count"

        # WRITE: save checkpoint so --resume can skip this stage next time
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CHECKPOINT_ANALYZE_PATH"
        step_info "Checkpoint saved."
    else
        step_fail "analyze.py failed."
        echo "" >&2
        echo "Error output:" >&2
        cat /tmp/analyze_err >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# STAGE 2: RENDER REPORT — stats.json → report.md (or .html)
# Pi pattern: READ (stats.json) → BASH (render_report.py) → WRITE (report.md)
# ---------------------------------------------------------------------------
stage_header 2 2 "Rendering report..."

SKIP_REPORT=false
if [[ "$RESUME" == "true" && -f "$CHECKPOINT_REPORT_PATH" && -f "$REPORT_FILE" ]]; then
    step_info "Checkpoint found, skipping report render."
    SKIP_REPORT=true
fi

if [[ "$SKIP_REPORT" == "false" ]]; then
    step_info "Running: python3 scripts/render_report.py"

    if python3 "$SCRIPTS_DIR/render_report.py" "$STATS_FILE" --output "$REPORT_FILE" --format "$REPORT_FORMAT" 2>/tmp/render_err; then
        if [[ ! -f "$REPORT_FILE" ]]; then
            step_fail "render_report.py did not create $REPORT_FILE"
            exit 1
        fi

        step_ok "Report created: $REPORT_FILE"

        # WRITE: save checkpoint
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CHECKPOINT_REPORT_PATH"
    else
        step_fail "render_report.py failed."
        echo "" >&2
        cat /tmp/render_err >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# FINAL SUMMARY
# ---------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────────────"
echo -e "  ${GREEN}Pipeline complete!${NC}"
echo "────────────────────────────────────────────"

if [[ -f "$STATS_FILE" ]]; then
    total_records=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('total_records', '?'))" 2>/dev/null || echo "?")
    total_amount=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('total_amount', '?'))" 2>/dev/null || echo "?")
    cat_count=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(len(d.get('by_category', {})))" 2>/dev/null || echo "?")

    echo "  Input rows:  $total_records"
    echo "  Categories:  $cat_count"
    echo "  Total billed: \$$total_amount"
fi

echo "  Stats:       $STATS_FILE"
echo "  Report:      $REPORT_FILE"
echo ""
