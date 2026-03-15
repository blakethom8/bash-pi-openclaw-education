#!/bin/bash
# enterprise-template.sh - Enterprise Reporting Agent Template
#
# Pre-wired for the claims/provider reporting workflow:
#   query_data → process_data → render_report → distribute_report
#
# INSTRUCTIONS:
#   1. Copy: cp enterprise-template.sh my-claims-report.sh
#   2. Set the CONFIGURATION section (DB connection, paths, etc.)
#   3. Implement the four stub functions
#   4. Customize the argument flags for your specific report types
#   5. Test with --dry-run first
#
# Usage:
#   ./my-claims-report.sh --report-type claims --date-range 2026-01-01:2026-01-31
#   ./my-claims-report.sh --report-type providers --state CA --output-format html
#   ./my-claims-report.sh --dry-run --report-type claims --date-range 2026-01-01:2026-01-31

set -euo pipefail

# ===========================================================================
# CONFIGURATION
# Edit these for your environment.
# ===========================================================================

AGENT_NAME="Enterprise Report Agent"
AGENT_VERSION="1.0"

# Script location (all paths derived from this)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directories
WORKSPACE="$SCRIPT_DIR/workspace"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
OUTPUT_DIR="$SCRIPT_DIR/reports"

# Data source — set one of these for your environment:
# For CSV-based data:
DATA_DIR="$SCRIPT_DIR/data"
# For database: set DB_HOST, DB_PORT, DB_NAME, DB_USER in your shell environment
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-}"
DB_USER="${DB_USER:-}"

# Notification — set NOTIFY_EMAIL in your shell environment to enable
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"

# ===========================================================================
# COLORS
# ===========================================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===========================================================================
# STRUCTURED LOGGING
# Every action is timestamped and categorized.
# ===========================================================================
LOG_FILE="$WORKSPACE/report-agent.log"

_log() {
    local level="$1"
    local message="$2"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    printf '[%s] [%-5s] %s\n' "$ts" "$level" "$message" >> "$LOG_FILE"
}

log_info()    { _log "INFO"  "$1"; echo "  $1"; }
log_ok()      { _log "OK"    "$1"; echo -e "  ${GREEN}[OK]${NC}    $1"; }
log_warn()    { _log "WARN"  "$1"; echo -e "  ${YELLOW}[WARN]${NC}   $1"; }
log_error()   { _log "ERROR" "$1"; echo -e "  ${RED}[ERROR]${NC}  $1" >&2; }
log_step()    {
    _log "STEP"  "$1"
    echo ""
    echo -e "${BLUE}[${STEP_NUM:-?}/${TOTAL_STEPS:-?}]${NC} $1"
    STEP_NUM=$(( ${STEP_NUM:-0} + 1 ))
}
log_dry_run() { _log "DRY"   "$1"; echo -e "  ${CYAN}[DRY RUN]${NC} $1"; }

# ===========================================================================
# USAGE
# ===========================================================================
print_usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Report options:"
    echo "  --report-type <type>     Type of report: claims, providers, summary"
    echo "  --date-range <from:to>   Date range: 2026-01-01:2026-01-31"
    echo "  --from <date>            Start date (alternative to --date-range)"
    echo "  --to <date>              End date"
    echo "  --state <ST>             Filter by state (for provider reports)"
    echo "  --category <cat>         Filter by category (for claims reports)"
    echo ""
    echo "Output options:"
    echo "  --output-format <fmt>    Output format: html, md, csv (default: html)"
    echo "  --output <file>          Override output file path"
    echo "  --open                   Open the report after generating (macOS)"
    echo ""
    echo "Execution options:"
    echo "  --dry-run                Show what would happen without doing it"
    echo "  --resume                 Skip stages with existing checkpoint files"
    echo "  --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") --report-type claims --date-range 2026-01-01:2026-01-31"
    echo "  $(basename "$0") --report-type providers --state CA --output-format html"
    echo "  $(basename "$0") --dry-run --report-type claims --from 2026-01-01 --to 2026-01-31"
}

# ===========================================================================
# ARGUMENT PARSING
# ===========================================================================
REPORT_TYPE=""
DATE_FROM=""
DATE_TO=""
FILTER_STATE=""
FILTER_CATEGORY=""
OUTPUT_FORMAT="html"
OUTPUT_FILE_OVERRIDE=""
OPEN_AFTER=false
DRY_RUN=false
RESUME=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --report-type)    REPORT_TYPE="$2"; shift 2 ;;
        --date-range)
            DATE_FROM=$(echo "$2" | cut -d: -f1)
            DATE_TO=$(echo "$2" | cut -d: -f2)
            shift 2
            ;;
        --from)           DATE_FROM="$2"; shift 2 ;;
        --to)             DATE_TO="$2"; shift 2 ;;
        --state)          FILTER_STATE="$2"; shift 2 ;;
        --category)       FILTER_CATEGORY="$2"; shift 2 ;;
        --output-format)  OUTPUT_FORMAT="$2"; shift 2 ;;
        --output)         OUTPUT_FILE_OVERRIDE="$2"; shift 2 ;;
        --open)           OPEN_AFTER=true; shift ;;
        --dry-run)        DRY_RUN=true; shift ;;
        --resume)         RESUME=true; shift ;;
        --help|-h)        print_usage; exit 0 ;;
        -*)               echo "Error: Unknown option: $1" >&2; print_usage >&2; exit 1 ;;
        *)                echo "Error: Unexpected argument: $1" >&2; exit 1 ;;
    esac
done

# ===========================================================================
# VALIDATION
# ===========================================================================
if [[ -z "$REPORT_TYPE" ]]; then
    echo "Error: --report-type is required." >&2
    print_usage >&2
    exit 1
fi

valid_types=("claims" "providers" "summary")
valid=false
for t in "${valid_types[@]}"; do
    [[ "$REPORT_TYPE" == "$t" ]] && valid=true
done
if [[ "$valid" == "false" ]]; then
    echo "Error: Unknown report type '$REPORT_TYPE'. Valid types: ${valid_types[*]}" >&2
    exit 1
fi

valid_formats=("html" "md" "csv")
valid=false
for f in "${valid_formats[@]}"; do
    [[ "$OUTPUT_FORMAT" == "$f" ]] && valid=true
done
if [[ "$valid" == "false" ]]; then
    echo "Error: Unknown format '$OUTPUT_FORMAT'. Valid formats: ${valid_formats[*]}" >&2
    exit 1
fi

# ===========================================================================
# WORKSPACE + OUTPUT SETUP
# ===========================================================================
mkdir -p "$WORKSPACE" "$OUTPUT_DIR"

# Build default output filename from report type and date range
if [[ -n "$OUTPUT_FILE_OVERRIDE" ]]; then
    REPORT_OUTPUT_FILE="$OUTPUT_FILE_OVERRIDE"
else
    report_date_tag=""
    [[ -n "$DATE_FROM" ]] && report_date_tag="-${DATE_FROM}"
    [[ -n "$DATE_TO" && "$DATE_TO" != "$DATE_FROM" ]] && report_date_tag="${report_date_tag}_${DATE_TO}"
    REPORT_OUTPUT_FILE="$OUTPUT_DIR/${REPORT_TYPE}${report_date_tag}.${OUTPUT_FORMAT}"
fi

# Checkpoint files for --resume support
CHECKPOINT_QUERY="$WORKSPACE/.ckpt_query_${REPORT_TYPE}"
CHECKPOINT_PROCESS="$WORKSPACE/.ckpt_process_${REPORT_TYPE}"

LOG_FILE="$WORKSPACE/report-agent.log"

# Initialize log
{
    echo "# $AGENT_NAME v$AGENT_VERSION"
    echo "# Started: $(date)"
    echo "# Report type: $REPORT_TYPE"
    [[ -n "$DATE_FROM" ]] && echo "# Date from: $DATE_FROM"
    [[ -n "$DATE_TO" ]] && echo "# Date to: $DATE_TO"
    echo "# Output: $REPORT_OUTPUT_FILE"
    [[ "$DRY_RUN" == "true" ]] && echo "# Mode: DRY RUN"
    echo ""
} > "$LOG_FILE"

# Step counter
STEP_NUM=1
TOTAL_STEPS=4

# ===========================================================================
# HEADER
# ===========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  $AGENT_NAME${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Report type: $REPORT_TYPE"
[[ -n "$DATE_FROM" ]] && echo "  Date from:   $DATE_FROM"
[[ -n "$DATE_TO" ]]   && echo "  Date to:     $DATE_TO"
[[ -n "$FILTER_STATE" ]] && echo "  State:       $FILTER_STATE"
[[ -n "$FILTER_CATEGORY" ]] && echo "  Category:    $FILTER_CATEGORY"
echo "  Format:      $OUTPUT_FORMAT"
echo "  Output:      $REPORT_OUTPUT_FILE"
[[ "$DRY_RUN" == "true" ]] && echo -e "  Mode:        ${YELLOW}DRY RUN${NC}"
[[ "$RESUME" == "true" ]]  && echo -e "  Resume:      ${CYAN}ON${NC}"
echo "────────────────────────────────────────────"

# ===========================================================================
# TOOL IMPLEMENTATIONS
# ===========================================================================

# ---------------------------------------------------------------------------
# TOOL: query_data
# Pi pattern: READ + BASH tools
#
# Fetches raw data from your data source (CSV, database, API, etc.)
# Output: writes raw data to $WORKSPACE/raw_data.json (or .csv)
#
# TODO: Implement this for your actual data source.
# ---------------------------------------------------------------------------
query_data() {
    log_step "Querying data (${REPORT_TYPE})"

    # Skip if checkpoint exists (--resume mode)
    if [[ "$RESUME" == "true" && -f "$CHECKPOINT_QUERY" ]]; then
        log_info "Checkpoint found — skipping query step."
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Would query $REPORT_TYPE data"
        [[ -n "$DATE_FROM" ]] && log_dry_run "  Date range: $DATE_FROM to ${DATE_TO:-today}"
        [[ -n "$FILTER_STATE" ]] && log_dry_run "  State filter: $FILTER_STATE"
        return 0
    fi

    # -----------------------------------------------------------------------
    # TODO: Replace this stub with your actual data query.
    #
    # OPTION A: Read from a local CSV file
    #   cp "$DATA_DIR/${REPORT_TYPE}_${DATE_FROM}_${DATE_TO}.csv" \
    #       "$WORKSPACE/raw_data.csv"
    #
    # OPTION B: Query a database (requires psql and configured credentials)
    #   psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    #       -c "SELECT * FROM claims WHERE date BETWEEN '$DATE_FROM' AND '$DATE_TO'" \
    #       --csv > "$WORKSPACE/raw_data.csv"
    #
    # OPTION C: Call an API
    #   curl -s "$API_URL?from=$DATE_FROM&to=$DATE_TO" > "$WORKSPACE/raw_data.json"
    #
    # OPTION D: Call another script from this repo
    #   bash "$SCRIPT_DIR/../project4-api-integration/scripts/lookup_npi.sh" \
    #       "" "" "$FILTER_SPECIALTY" "$FILTER_STATE" > "$WORKSPACE/raw_data.json"
    # -----------------------------------------------------------------------

    # Placeholder: create empty output file so subsequent steps don't fail
    echo "[]" > "$WORKSPACE/raw_data.json"
    log_warn "query_data is using placeholder data — implement me!"

    # Write checkpoint
    date -u +%Y-%m-%dT%H:%M:%SZ > "$CHECKPOINT_QUERY"
    log_ok "Data saved to $WORKSPACE/raw_data.json"
}

# ---------------------------------------------------------------------------
# TOOL: process_data
# Pi pattern: BASH tool (calling Python)
#
# Transforms raw data into processed, enriched data ready for reporting.
# Input:  $WORKSPACE/raw_data.json (or .csv)
# Output: $WORKSPACE/processed_data.json
#
# TODO: Implement this for your transformation logic.
# ---------------------------------------------------------------------------
process_data() {
    log_step "Processing data"

    if [[ "$RESUME" == "true" && -f "$CHECKPOINT_PROCESS" ]]; then
        log_info "Checkpoint found — skipping process step."
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Would process/enrich $REPORT_TYPE data"
        return 0
    fi

    # -----------------------------------------------------------------------
    # TODO: Replace with your processing logic.
    #
    # OPTION A: Python script for aggregation
    #   python3 "$SCRIPT_DIR/../project2-data-pipeline/scripts/analyze.py" \
    #       "$WORKSPACE/raw_data.csv" \
    #       --output "$WORKSPACE/processed_data.json"
    #
    # OPTION B: jq transformation
    #   jq '[.[] | select(.status == "approved") | {
    #       provider: .provider_name,
    #       amount: .amount,
    #       date: .date
    #   }]' "$WORKSPACE/raw_data.json" > "$WORKSPACE/processed_data.json"
    #
    # OPTION C: awk for CSV aggregation
    #   awk -F',' 'NR>1 { sum[$6] += $3; count[$6]++ }
    #       END { for (cat in sum) print cat","sum[cat]","count[cat] }' \
    #       "$WORKSPACE/raw_data.csv" > "$WORKSPACE/aggregated.csv"
    # -----------------------------------------------------------------------

    # Placeholder: copy raw to processed
    cp "$WORKSPACE/raw_data.json" "$WORKSPACE/processed_data.json"
    log_warn "process_data is a passthrough — implement me!"

    date -u +%Y-%m-%dT%H:%M:%SZ > "$CHECKPOINT_PROCESS"
    log_ok "Processed data: $WORKSPACE/processed_data.json"
}

# ---------------------------------------------------------------------------
# TOOL: render_report
# Pi pattern: BASH + WRITE tools
#
# Generates the output report from processed data.
# Input:  $WORKSPACE/processed_data.json
# Output: $REPORT_OUTPUT_FILE
#
# TODO: Implement this for your report format.
# ---------------------------------------------------------------------------
render_report() {
    log_step "Rendering ${OUTPUT_FORMAT} report"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Would render $OUTPUT_FORMAT report to: $REPORT_OUTPUT_FILE"
        return 0
    fi

    # -----------------------------------------------------------------------
    # TODO: Replace with your report renderer.
    #
    # OPTION A: Python script (recommended for HTML reports)
    #   python3 "$SCRIPT_DIR/../project3-report-generator/scripts/generate_report.py" \
    #       "$WORKSPACE/processed_data.json" \
    #       --output "$REPORT_OUTPUT_FILE" \
    #       --template "$TEMPLATE_DIR/report_template.html" \
    #       --title "${REPORT_TYPE^} Report: $DATE_FROM to $DATE_TO"
    #
    # OPTION B: render_report.py from project2
    #   python3 "$SCRIPT_DIR/../project2-data-pipeline/scripts/render_report.py" \
    #       "$WORKSPACE/processed_data.json" \
    #       --output "$REPORT_OUTPUT_FILE" \
    #       --format "$OUTPUT_FORMAT"
    #
    # OPTION C: Simple bash heredoc for markdown
    #   {
    #       echo "# $REPORT_TYPE Report"
    #       echo "Generated: $(date)"
    #       echo ""
    #       cat "$WORKSPACE/processed_data.json" | python3 -m json.tool
    #   } > "$REPORT_OUTPUT_FILE"
    # -----------------------------------------------------------------------

    # Placeholder: create a minimal report
    {
        echo "# ${REPORT_TYPE^} Report"
        echo "Generated: $(date)"
        echo "Date range: ${DATE_FROM:-N/A} to ${DATE_TO:-N/A}"
        echo ""
        echo "TODO: Implement render_report()"
    } > "$REPORT_OUTPUT_FILE"
    log_warn "render_report is using placeholder content — implement me!"

    log_ok "Report: $REPORT_OUTPUT_FILE"
}

# ---------------------------------------------------------------------------
# TOOL: distribute_report
# Pi pattern: BASH tool (sending/copying the output)
#
# Delivers the report to its destination.
# Input:  $REPORT_OUTPUT_FILE
# Output: (side effects: email, file copy, etc.)
#
# TODO: Implement this for your distribution channel.
# ---------------------------------------------------------------------------
distribute_report() {
    log_step "Distributing report"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Would distribute: $REPORT_OUTPUT_FILE"
        [[ -n "$NOTIFY_EMAIL" ]] && log_dry_run "  Email to: $NOTIFY_EMAIL"
        return 0
    fi

    # -----------------------------------------------------------------------
    # TODO: Replace with your distribution mechanism.
    #
    # OPTION A: Send email (requires mail or mailx)
    #   if [[ -n "$NOTIFY_EMAIL" ]]; then
    #       mail -s "${REPORT_TYPE^} Report: $DATE_FROM to $DATE_TO" \
    #           "$NOTIFY_EMAIL" < "$REPORT_OUTPUT_FILE"
    #       log_ok "Email sent to $NOTIFY_EMAIL"
    #   fi
    #
    # OPTION B: Copy to a shared drive / network path
    #   SHARE_PATH="/mnt/reports/${REPORT_TYPE}/"
    #   cp "$REPORT_OUTPUT_FILE" "$SHARE_PATH"
    #   log_ok "Copied to $SHARE_PATH"
    #
    # OPTION C: POST to a webhook (Slack, Teams, etc.)
    #   curl -s -X POST "$SLACK_WEBHOOK_URL" \
    #       -H 'Content-type: application/json' \
    #       --data "{\"text\": \"${REPORT_TYPE^} report ready: $REPORT_OUTPUT_FILE\"}"
    #   log_ok "Slack notification sent"
    #
    # OPTION D: Archive with date stamp
    #   ARCHIVE_DIR="$OUTPUT_DIR/archive"
    #   mkdir -p "$ARCHIVE_DIR"
    #   cp "$REPORT_OUTPUT_FILE" "$ARCHIVE_DIR/"
    #   log_ok "Archived to $ARCHIVE_DIR"
    # -----------------------------------------------------------------------

    log_info "distribute_report: no distribution configured — implement me if needed"
}

# ===========================================================================
# MAIN EXECUTION
# ===========================================================================
main() {
    # Stage 1: READ — fetch raw data
    query_data

    # Stage 2: BASH (Python) — process and enrich
    process_data

    # Stage 3: BASH + WRITE — generate the report
    render_report

    # Stage 4: BASH — distribute/deliver
    distribute_report

    # Open in browser if requested
    if [[ "$OPEN_AFTER" == "true" && "$DRY_RUN" == "false" && -f "$REPORT_OUTPUT_FILE" ]]; then
        if command -v open &>/dev/null; then
            open "$REPORT_OUTPUT_FILE"
        elif command -v xdg-open &>/dev/null; then
            xdg-open "$REPORT_OUTPUT_FILE"
        fi
    fi

    # Final summary
    echo ""
    echo "────────────────────────────────────────────"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}Dry run complete.${NC} No files were modified."
    else
        echo -e "  ${GREEN}Done!${NC}"
        [[ -f "$REPORT_OUTPUT_FILE" ]] && echo "  Report: $REPORT_OUTPUT_FILE"
    fi
    echo "  Log:    $LOG_FILE"
    echo ""

    _log "INFO" "Agent completed successfully"
}

# Run main
main
