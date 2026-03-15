#!/bin/bash
# solution/agent.sh - Data Pipeline Agent (Reference Solution)
#
# This is the complete, annotated reference solution.
# Each section is labeled with which Pi pattern tool it represents.
#
# Key patterns demonstrated:
#   1. Bash-as-orchestrator: the bash script only coordinates, Python does the work
#   2. File-based checkpointing: intermediate files = resumable pipeline
#   3. Error handling at each stage: fail fast with clear messages
#   4. Separation of concerns: analyze.py knows nothing about the report, and vice versa
#
# Usage:
#   ./solution/agent.sh <input.csv> [--output <dir>] [--resume] [--format md|html]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The solution lives one level deeper, so scripts are in ../scripts/
SCRIPTS_DIR="$SCRIPT_DIR/../scripts"
OUTPUT_DIR="$SCRIPT_DIR/../workspace"
CHECKPOINT_ANALYZE=".checkpoint_analyze"
CHECKPOINT_REPORT=".checkpoint_report"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# The key insight: bash orchestrates, Python processes.
#
# bash is good at:
#   - Argument parsing
#   - File system operations (mkdir, test -f, etc.)
#   - Calling other programs and capturing exit codes
#   - Piping output between programs
#
# Python is good at:
#   - CSV/JSON parsing
#   - Math (sum, avg, min, max)
#   - String formatting
#   - Data validation
#
# Don't fight these strengths. Let each language do what it's good at.
# ---------------------------------------------------------------------------

print_usage() {
    echo "Usage: $(basename "$0") <input.csv> [options]"
    echo ""
    echo "Options:"
    echo "  --output <dir>   Output directory (default: ../workspace/)"
    echo "  --resume         Skip stages with existing checkpoints"
    echo "  --format <fmt>   Report format: md or html (default: md)"
    echo "  --help           Show this help"
}

# ---------------------------------------------------------------------------
# ARGUMENT PARSING
# ---------------------------------------------------------------------------
INPUT_CSV=""
RESUME=false
REPORT_FORMAT="md"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --resume) RESUME=true; shift ;;
        --format)
            REPORT_FORMAT="$2"
            if [[ "$REPORT_FORMAT" != "md" && "$REPORT_FORMAT" != "html" ]]; then
                echo "Error: --format must be 'md' or 'html'" >&2
                exit 1
            fi
            shift 2
            ;;
        --help|-h) print_usage; exit 0 ;;
        -*) echo "Error: Unknown option: $1" >&2; print_usage >&2; exit 1 ;;
        *)
            [[ -z "$INPUT_CSV" ]] && INPUT_CSV="$1" || { echo "Error: Unexpected argument: $1" >&2; exit 1; }
            shift
            ;;
    esac
done

if [[ -z "$INPUT_CSV" ]]; then
    echo "Error: No input CSV file specified." >&2
    print_usage >&2
    exit 1
fi

# Fail fast: validate before creating any files
if [[ ! -f "$INPUT_CSV" ]]; then
    echo -e "${RED}Error:${NC} Input file not found: $INPUT_CSV" >&2
    exit 1
fi

# Resolve to absolute paths — avoids ambiguity in log messages
INPUT_CSV=$(cd "$(dirname "$INPUT_CSV")" && pwd)/$(basename "$INPUT_CSV")
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)

STATS_FILE="$OUTPUT_DIR/stats.json"
REPORT_FILE="$OUTPUT_DIR/report.${REPORT_FORMAT}"
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
[[ "$RESUME" == "true" ]] && echo -e "  Mode:   ${YELLOW}RESUME${NC} (using checkpoints where available)"
echo "────────────────────────────────────────────"

# ---------------------------------------------------------------------------
# STAGE 1: ANALYZE
#
# READ tool:  the CSV file is our read input
# BASH tool:  we invoke analyze.py as a subprocess
# WRITE tool: analyze.py writes stats.json; we write a checkpoint
#
# The checkpoint pattern:
#   - After successful completion, write a timestamp file
#   - On --resume, check if the checkpoint exists before running
#   - This makes the pipeline idempotent and restartable
# ---------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[Stage 1/2]${NC} Analyzing data..."

if [[ "$RESUME" == "true" && -f "$CHECKPOINT_ANALYZE_PATH" && -f "$STATS_FILE" ]]; then
    echo "  Checkpoint found, skipping analysis."
else
    echo "  Running: python3 scripts/analyze.py"

    # BASH tool: invoke the Python script.
    # We redirect stderr to a temp file so we can show it only on failure.
    # stdout is not used (analyze.py writes directly to the output file).
    if python3 "$SCRIPTS_DIR/analyze.py" "$INPUT_CSV" --output "$STATS_FILE" 2>/tmp/analyze_err; then
        if [[ ! -s "$STATS_FILE" ]]; then
            echo -e "  ${RED}[FAIL]${NC} analyze.py created empty stats.json" >&2
            exit 1
        fi

        record_count=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('total_records', '?'))" 2>/dev/null || echo "?")
        cat_count=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(len(d.get('by_category', {})))" 2>/dev/null || echo "?")

        echo -e "  ${GREEN}[OK]${NC}   Stats file: $STATS_FILE"
        echo "  Records processed: $record_count"
        echo "  Categories found:  $cat_count"

        # WRITE tool: checkpoint file records when this stage completed
        date -u +%Y-%m-%dT%H:%M:%SZ > "$CHECKPOINT_ANALYZE_PATH"
        echo "  Checkpoint saved."
    else
        echo -e "  ${RED}[FAIL]${NC} analyze.py exited with an error:" >&2
        cat /tmp/analyze_err >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# STAGE 2: RENDER REPORT
#
# READ tool:  stats.json (written in stage 1)
# BASH tool:  invoke render_report.py
# WRITE tool: render_report.py writes report.md; we write a checkpoint
#
# This stage depends on stage 1's output file.
# If stats.json doesn't exist, render_report.py will fail — that's correct.
# ---------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[Stage 2/2]${NC} Rendering report..."

if [[ "$RESUME" == "true" && -f "$CHECKPOINT_REPORT_PATH" && -f "$REPORT_FILE" ]]; then
    echo "  Checkpoint found, skipping report render."
else
    echo "  Running: python3 scripts/render_report.py"

    if python3 "$SCRIPTS_DIR/render_report.py" "$STATS_FILE" \
        --output "$REPORT_FILE" \
        --format "$REPORT_FORMAT" \
        2>/tmp/render_err; then

        echo -e "  ${GREEN}[OK]${NC}   Report: $REPORT_FILE"
        date -u +%Y-%m-%dT%H:%M:%SZ > "$CHECKPOINT_REPORT_PATH"
    else
        echo -e "  ${RED}[FAIL]${NC} render_report.py exited with an error:" >&2
        cat /tmp/render_err >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# FINAL SUMMARY
#
# WRITE tool (stdout): print the summary of what was produced
# In a real pipeline, you might also write this to a manifest file or
# send it to a notification system.
# ---------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────────────"
echo -e "  ${GREEN}Pipeline complete!${NC}"
echo "────────────────────────────────────────────"

if [[ -f "$STATS_FILE" ]]; then
    total=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('total_records', '?'))" 2>/dev/null || echo "?")
    amount=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('total_amount', '?'))" 2>/dev/null || echo "?")
    cats=$(python3 -c "import json; d=json.load(open('$STATS_FILE')); print(len(d.get('by_category', {})))" 2>/dev/null || echo "?")
    echo "  Input rows:    $total"
    echo "  Categories:    $cats"
    echo "  Total billed:  \$$amount"
fi

echo "  Stats file:    $STATS_FILE"
echo "  Report:        $REPORT_FILE"
echo ""

# ---------------------------------------------------------------------------
# Key lessons from this pipeline:
#
# 1. bash orchestrates, Python processes — each does what it's best at
# 2. File-based checkpoints (timestamp files) make the pipeline resumable
# 3. Fail fast: validate inputs before creating any output files
# 4. Capture stderr to /tmp for display on failure — clean output on success
# 5. Absolute paths in variables prevent confusion about working directory
# ---------------------------------------------------------------------------
