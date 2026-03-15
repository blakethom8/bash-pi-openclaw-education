#!/bin/bash
# solution/agent.sh - File Organizer Agent (Reference Solution)
#
# This is the complete, heavily-commented reference solution.
# Read this AFTER you've attempted to build agent.sh yourself.
#
# Pi Pattern demonstrated:
#   READ  → find + list files
#   DECIDE → classify_file function (pure logic)
#   BASH  → mkdir + mv (side effects)
#   WRITE → log_action (audit trail)
#
# Usage:
#   ./solution/agent.sh [--dry-run] [directory]

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
# These are declared at the top so they're easy to change without hunting
# through the code. This is a good agent design practice.
DOCS_EXTENSIONS="pdf doc docx txt md rtf odt pages"
IMAGE_EXTENSIONS="jpg jpeg png gif svg webp bmp tiff ico"
SCRIPT_EXTENSIONS="sh py js ts rb go rs pl php bash zsh"
DATA_EXTENSIONS="csv json xml xlsx xls sql parquet yaml yml toml"
LOG_FILENAME="organizer.log"
MISC_CATEGORY="misc"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# WRITE TOOL IMPLEMENTATION
# ---------------------------------------------------------------------------
# In Pi, the write tool appends structured content to a file.
# Here we wrap it in a function that adds a timestamp automatically.
# Every agent that modifies the filesystem should have an equivalent.
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # >> is the key operator: APPEND, never overwrite
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# CLASSIFICATION LOGIC (the DECIDE step)
# ---------------------------------------------------------------------------
# This function is pure: given a filename, return a category.
# It has NO side effects — it doesn't move files, doesn't log anything.
# Separating the "what to do" from the "actually doing it" makes agents
# easier to test and to add dry-run support.
classify_file() {
    local filename="$1"

    # Extract and normalize extension
    local extension="${filename##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # Edge case: no extension at all (e.g. "Makefile", ".gitignore")
    if [[ "$filename" == "$extension" ]] || [[ "$filename" == ".$extension" ]]; then
        echo "$MISC_CATEGORY"
        return
    fi

    # Check each category list. The nested for-loop pattern is simple
    # and explicit — easy to understand and extend.
    for ext in $DOCS_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then echo "docs"; return; fi
    done

    for ext in $IMAGE_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then echo "images"; return; fi
    done

    for ext in $SCRIPT_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then echo "scripts"; return; fi
    done

    for ext in $DATA_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then echo "data"; return; fi
    done

    echo "$MISC_CATEGORY"
}

print_usage() {
    echo "Usage: $(basename "$0") [--dry-run] [directory]"
    echo ""
    echo "Organizes files in a directory by type."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would happen without moving any files"
    echo "  --help       Show this help message"
}

# ---------------------------------------------------------------------------
# ARGUMENT PARSING
# ---------------------------------------------------------------------------
# Always support --help and --dry-run. These two flags are standard for
# any agent that modifies state.
DRY_RUN=false
TARGET_DIR="."

while [[ $# -gt 0 ]]; do
    case "$1" in
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
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Resolve to absolute path so log messages are unambiguous
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
LOG_FILE="$TARGET_DIR/$LOG_FILENAME"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Error:${NC} Directory not found: $TARGET_DIR" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  File Organizer Agent${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Target directory: $TARGET_DIR"
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  Mode: ${YELLOW}DRY RUN${NC} (no files will be moved)"
else
    echo -e "  Mode: ${GREEN}LIVE${NC} (files will be moved)"
fi
echo "────────────────────────────────────────────"
echo ""

# Initialize the log (WRITE tool — first write to establish context)
if [[ "$DRY_RUN" == "false" ]]; then
    {
        echo "# File Organizer Agent"
        echo "# Started: $(date)"
        echo "# Target: $TARGET_DIR"
        echo ""
    } > "$LOG_FILE"
fi

# ---------------------------------------------------------------------------
# COUNTERS
# ---------------------------------------------------------------------------
# Individual integer variables for bash 3 compatibility (macOS default shell).
# An associative array (declare -A) would be cleaner but requires bash 4+.
# This is the "accumulated state" that the summary will use.
count_docs=0
count_images=0
count_scripts=0
count_data=0
count_misc=0
total_count=0
skipped_count=0

# ---------------------------------------------------------------------------
# MAIN AGENT LOOP — Pi pattern in action
#
# This while loop is the core of the agent. For each iteration:
#   1. READ:   we already have the file path from `find`
#   2. DECIDE: call classify_file to determine category
#   3. BASH:   mkdir + mv (only in live mode)
#   4. WRITE:  log_action to append to the log
# ---------------------------------------------------------------------------

# READ: Use `find` to enumerate files at depth 1.
# -maxdepth 1 prevents descending into already-organized subdirectories.
# -type f skips directories, symlinks, etc.
# `sort` gives us deterministic order (useful for testing).
while IFS= read -r filepath; do
    filename=$(basename "$filepath")

    # Skip the log file — we don't want to organize our own log
    if [[ "$filename" == "$LOG_FILENAME" ]]; then
        continue
    fi

    # Skip hidden files — dotfiles are typically config, not user content
    if [[ "$filename" == .* ]]; then
        skipped_count=$(( skipped_count + 1 ))
        continue
    fi

    # DECIDE: pure classification, no side effects
    category=$(classify_file "$filename")

    # Build destination path
    dest_dir="$TARGET_DIR/$category"
    dest_file="$dest_dir/$filename"

    # Handle filename collisions: if the destination already has a file with
    # the same name, add _2, _3, etc. rather than silently overwriting.
    if [[ -e "$dest_file" && "$DRY_RUN" == "false" ]]; then
        base="${filename%.*}"
        ext="${filename##*.}"
        # Edge case: files with no extension
        if [[ "$base" == "$filename" ]]; then
            ext=""
        fi
        counter=2
        if [[ -n "$ext" ]]; then
            while [[ -e "$dest_dir/${base}_${counter}.${ext}" ]]; do
                ((counter++))
            done
            dest_file="$dest_dir/${base}_${counter}.${ext}"
            filename="${base}_${counter}.${ext}"
        else
            while [[ -e "$dest_dir/${base}_${counter}" ]]; do
                ((counter++))
            done
            dest_file="$dest_dir/${base}_${counter}"
            filename="${base}_${counter}"
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        # Dry run: print intent only, no filesystem changes
        printf "  ${YELLOW}[WOULD MOVE]${NC} %-30s → %s/\n" "$(basename "$filepath")" "$category"
    else
        # BASH tool: create directory and move file
        # mkdir -p is idempotent — safe to call multiple times
        mkdir -p "$dest_dir"
        mv "$filepath" "$dest_file"

        # WRITE tool: record this action in the audit log
        log_action "MOVED $(basename "$filepath") → $category/"

        printf "  ${GREEN}[MOVED]${NC} %-30s → %s/\n" "$(basename "$filepath")" "$category"
    fi

    # Accumulate count for this category
    case "$category" in
        docs)    count_docs=$(( count_docs + 1 )) ;;
        images)  count_images=$(( count_images + 1 )) ;;
        scripts) count_scripts=$(( count_scripts + 1 )) ;;
        data)    count_data=$(( count_data + 1 )) ;;
        misc)    count_misc=$(( count_misc + 1 )) ;;
    esac
    total_count=$(( total_count + 1 ))

done < <(find "$TARGET_DIR" -maxdepth 1 -type f | sort)

# ---------------------------------------------------------------------------
# SUMMARY — WRITE tool (final output)
# ---------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────────────"
echo "  Summary"
echo "────────────────────────────────────────────"

[[ "$count_docs" -gt 0 ]]    && printf "  %-12s %d file(s)\n" "docs:"    "$count_docs"
[[ "$count_images" -gt 0 ]]  && printf "  %-12s %d file(s)\n" "images:"  "$count_images"
[[ "$count_scripts" -gt 0 ]] && printf "  %-12s %d file(s)\n" "scripts:" "$count_scripts"
[[ "$count_data" -gt 0 ]]    && printf "  %-12s %d file(s)\n" "data:"    "$count_data"
[[ "$count_misc" -gt 0 ]]    && printf "  %-12s %d file(s)\n" "misc:"    "$count_misc"

if [[ "$skipped_count" -gt 0 ]]; then
    printf "  %-12s %d file(s)\n" "skipped:" "$skipped_count"
fi

echo "────────────────────────────────────────────"
printf "  %-12s %d file(s)\n" "Total:" "$total_count"

if [[ "$DRY_RUN" == "false" ]]; then
    # Write the final summary to the log too (WRITE tool — completing the audit)
    log_action "SUMMARY: $total_count file(s) organized"
    [[ "$count_docs" -gt 0 ]]    && log_action "  docs: $count_docs"
    [[ "$count_images" -gt 0 ]]  && log_action "  images: $count_images"
    [[ "$count_scripts" -gt 0 ]] && log_action "  scripts: $count_scripts"
    [[ "$count_data" -gt 0 ]]    && log_action "  data: $count_data"
    [[ "$count_misc" -gt 0 ]]    && log_action "  misc: $count_misc"
    echo ""
    echo "  Log written to: $LOG_FILE"
fi

echo ""

# ---------------------------------------------------------------------------
# Key lessons from this agent:
#
# 1. classify_file is PURE (no side effects) — the DECIDE step stays clean
# 2. log_action wraps the WRITE tool — consistent format, timestamped
# 3. --dry-run separates DECIDE from BASH — same classification, no action
# 4. Collision handling prevents silent data loss
# 5. find -maxdepth 1 -type f is the READ tool — scoped, precise
# ---------------------------------------------------------------------------
