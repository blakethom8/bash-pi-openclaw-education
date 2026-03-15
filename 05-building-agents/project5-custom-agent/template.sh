#!/bin/bash
# template.sh - Generic Agent Template
#
# Starting point for building any bash agent.
# Follow the Pi pattern: read → decide → bash → write
#
# INSTRUCTIONS:
#   1. Copy this file: cp template.sh my-agent.sh
#   2. Replace MY_AGENT with your agent name throughout
#   3. Implement the stub functions below
#   4. Add/remove arguments as needed
#   5. Delete these instruction comments
#
# Usage:
#   ./my-agent.sh [--dry-run] [--input <file>] [--output <dir>] [--help]

set -euo pipefail

# ===========================================================================
# CONFIGURATION — change these values
# ===========================================================================

AGENT_NAME="My Agent"
AGENT_VERSION="1.0"

# Where to put intermediate files and output
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/workspace"

# Log file path
LOG_FILE="$WORKSPACE/agent.log"

# ===========================================================================
# COLORS (optional — remove if you prefer plain output)
# ===========================================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ===========================================================================
# LOGGING
# The WRITE tool in your agent — every significant action gets logged.
# ===========================================================================
log() {
    local level="${1:-INFO}"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info()  { log "INFO"  "$1"; echo "  $1"; }
log_ok()    { log "OK"    "$1"; echo -e "  ${GREEN}[OK]${NC} $1"; }
log_warn()  { log "WARN"  "$1"; echo -e "  ${YELLOW}[WARN]${NC} $1"; }
log_error() { log "ERROR" "$1"; echo -e "  ${RED}[ERROR]${NC} $1" >&2; }
log_step()  { log "STEP"  "$1"; echo ""; echo -e "${BLUE}>>> $1${NC}"; }

# ===========================================================================
# USAGE
# ===========================================================================
print_usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Description:"
    echo "  TODO: Describe what this agent does."
    echo ""
    echo "Options:"
    echo "  --input <file>    Input file path"
    echo "  --output <dir>    Output directory (default: ./workspace/)"
    echo "  --dry-run         Show what would happen without doing it"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./$(basename "$0") --input data.csv"
    echo "  ./$(basename "$0") --input data.csv --dry-run"
}

# ===========================================================================
# ARGUMENT PARSING
# ===========================================================================
INPUT_FILE=""
OUTPUT_DIR="$WORKSPACE"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)
            INPUT_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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
            echo "Error: Unexpected argument: $1" >&2
            print_usage >&2
            exit 1
            ;;
    esac
done

# ===========================================================================
# VALIDATION
# ===========================================================================
# TODO: Add validation for required arguments.
# Example:
#   if [[ -z "$INPUT_FILE" ]]; then
#       echo "Error: --input is required" >&2; exit 1
#   fi
#   if [[ ! -f "$INPUT_FILE" ]]; then
#       echo "Error: File not found: $INPUT_FILE" >&2; exit 1
#   fi

# ===========================================================================
# WORKSPACE SETUP
# ===========================================================================
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
LOG_FILE="$OUTPUT_DIR/agent.log"

# Initialize log
{
    echo "# $AGENT_NAME v$AGENT_VERSION"
    echo "# Started: $(date)"
    echo "# Working dir: $SCRIPT_DIR"
    [[ -n "$INPUT_FILE" ]] && echo "# Input: $INPUT_FILE"
    echo "# Output: $OUTPUT_DIR"
    [[ "$DRY_RUN" == "true" ]] && echo "# Mode: DRY RUN"
    echo ""
} > "$LOG_FILE"

# ===========================================================================
# HEADER
# ===========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  $AGENT_NAME${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
[[ -n "$INPUT_FILE" ]] && echo "  Input:  $INPUT_FILE"
echo "  Output: $OUTPUT_DIR"
[[ "$DRY_RUN" == "true" ]] && echo -e "  Mode:   ${YELLOW}DRY RUN${NC}"
echo "────────────────────────────────────────────"

# ===========================================================================
# TOOL IMPLEMENTATIONS
# Each function is one "tool call" in the Pi pattern.
# Keep them small, focused, and testable.
# ===========================================================================

# ---------------------------------------------------------------------------
# TOOL: read_input
# Pi pattern: READ tool
# Purpose: Load and validate the input data.
# Returns: Populates global variables or writes to workspace files.
# ---------------------------------------------------------------------------
read_input() {
    log_step "Step 1: Reading input"

    # TODO: Implement this.
    # Examples:
    #
    # Read a file:
    #   if [[ ! -f "$INPUT_FILE" ]]; then
    #       log_error "Input file not found: $INPUT_FILE"
    #       exit 1
    #   fi
    #   log_ok "Loaded: $INPUT_FILE"
    #
    # Query an API:
    #   curl -s "$API_URL" > "$WORKSPACE/raw_data.json"
    #   log_ok "Fetched data from API"
    #
    # Read from stdin:
    #   cat > "$WORKSPACE/input.txt"

    log_warn "read_input not implemented yet"
}

# ---------------------------------------------------------------------------
# TOOL: process_data
# Pi pattern: BASH tool (calling a Python script or processing data)
# Purpose: Transform the input data into the format needed for output.
# ---------------------------------------------------------------------------
process_data() {
    log_step "Step 2: Processing data"

    # TODO: Implement this.
    # Examples:
    #
    # Call a Python script:
    #   python3 scripts/analyze.py "$INPUT_FILE" --output "$WORKSPACE/stats.json"
    #
    # Use jq to transform JSON:
    #   jq '[.items[] | {name: .name, total: .amount}]' \
    #       "$WORKSPACE/raw_data.json" > "$WORKSPACE/processed.json"
    #
    # Run awk/sed on a CSV:
    #   awk -F',' '$4 == "approved"' "$INPUT_FILE" > "$WORKSPACE/approved.csv"

    log_warn "process_data not implemented yet"
}

# ---------------------------------------------------------------------------
# TOOL: generate_output
# Pi pattern: WRITE tool
# Purpose: Generate the final output artifact (file, report, HTML, etc.)
# ---------------------------------------------------------------------------
generate_output() {
    log_step "Step 3: Generating output"

    # TODO: Implement this.
    # Examples:
    #
    # Generate a report:
    #   python3 scripts/render_report.py "$WORKSPACE/stats.json" \
    #       --output "$OUTPUT_DIR/report.html"
    #
    # Copy output to destination:
    #   cp "$WORKSPACE/report.html" "$OUTPUT_DIR/"
    #
    # Send an email (if mail is configured):
    #   mail -s "Report ready" team@example.com < "$OUTPUT_DIR/report.html"

    log_warn "generate_output not implemented yet"
}

# ===========================================================================
# MAIN EXECUTION
# The agent loop: call each tool in order.
# Add or remove steps as needed.
# ===========================================================================
main() {
    # Step 1: READ — load the input
    read_input

    # Step 2: BASH — process/transform
    if [[ "$DRY_RUN" == "false" ]]; then
        process_data
    else
        log_info "[DRY RUN] Would process data — skipping"
    fi

    # Step 3: WRITE — produce output
    if [[ "$DRY_RUN" == "false" ]]; then
        generate_output
    else
        log_info "[DRY RUN] Would generate output — skipping"
    fi

    # Summary
    echo ""
    echo "────────────────────────────────────────────"
    echo -e "  ${GREEN}Done!${NC}"
    echo "  Log: $LOG_FILE"
    echo ""

    log "INFO" "Agent completed successfully"
}

# Run main
main
