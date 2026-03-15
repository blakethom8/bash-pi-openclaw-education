#!/bin/bash
# agent.sh - File Organizer Agent
#
# Organizes files in a directory by moving them into category subdirectories.
# Follows the Pi pattern: read (list) → decide (classify) → bash (move) → write (log)
#
# Usage:
#   ./agent.sh [--dry-run] [directory]
#
# Examples:
#   ./agent.sh                     # organize current directory
#   ./agent.sh /tmp/downloads      # organize a specific directory
#   ./agent.sh --dry-run ~/Desktop # preview what would happen

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------

# Category definitions: maps category name to a pattern used in classify_file
# You can extend these lists to add more extensions.
DOCS_EXTENSIONS="pdf doc docx txt md rtf odt pages"
IMAGE_EXTENSIONS="jpg jpeg png gif svg webp bmp tiff ico"
SCRIPT_EXTENSIONS="sh py js ts rb go rs pl php bash zsh"
DATA_EXTENSIONS="csv json xml xlsx xls sql parquet yaml yml toml"

# Name of the log file (written inside the target directory)
LOG_FILENAME="organizer.log"

# Name for files that don't match any known category
MISC_CATEGORY="misc"

# ---------------------------------------------------------------------------
# COLORS (optional, degrades gracefully if terminal doesn't support them)
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
# HELPER: log_action
# Appends a timestamped message to the log file.
# This is the WRITE tool in the Pi pattern.
# ---------------------------------------------------------------------------
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# HELPER: classify_file
# Given a filename, outputs the category name (docs/images/scripts/data/misc).
# This is the DECIDE step — pure logic, no side effects.
#
# Usage: category=$(classify_file "report.pdf")
# ---------------------------------------------------------------------------
classify_file() {
    local filename="$1"
    # Extract extension and normalize to lowercase
    local extension="${filename##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # If file has no extension (no dot found, or dot is first char), it's misc
    if [[ "$filename" == "$extension" ]] || [[ "$filename" == ".$extension" ]]; then
        echo "$MISC_CATEGORY"
        return
    fi

    # EXERCISE: Implement this section.
    # Check the extension against each category list and echo the category name.
    #
    # Hint: use a for loop over the extension list and check with [[ "$ext" == "$extension" ]]
    #
    # Example structure:
    #   for ext in $DOCS_EXTENSIONS; do
    #       if [[ "$ext" == "$extension" ]]; then
    #           echo "docs"
    #           return
    #       fi
    #   done

    for ext in $DOCS_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then
            echo "docs"
            return
        fi
    done

    for ext in $IMAGE_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then
            echo "images"
            return
        fi
    done

    for ext in $SCRIPT_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then
            echo "scripts"
            return
        fi
    done

    for ext in $DATA_EXTENSIONS; do
        if [[ "$ext" == "$extension" ]]; then
            echo "data"
            return
        fi
    done

    echo "$MISC_CATEGORY"
}

# ---------------------------------------------------------------------------
# HELPER: print_usage
# ---------------------------------------------------------------------------
print_usage() {
    echo "Usage: $(basename "$0") [--dry-run] [directory]"
    echo ""
    echo "Organizes files in a directory by type."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would happen without moving any files"
    echo "  --help       Show this help message"
    echo ""
    echo "If no directory is provided, uses the current directory."
    echo ""
    echo "Categories:"
    echo "  docs/     - pdf, doc, docx, txt, md, ..."
    echo "  images/   - jpg, png, gif, svg, ..."
    echo "  scripts/  - sh, py, js, rb, go, ..."
    echo "  data/     - csv, json, xml, xlsx, ..."
    echo "  misc/     - everything else"
}

# ---------------------------------------------------------------------------
# ARGUMENT PARSING
# ---------------------------------------------------------------------------
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

# Resolve to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
LOG_FILE="$TARGET_DIR/$LOG_FILENAME"

# ---------------------------------------------------------------------------
# VALIDATE INPUT
# ---------------------------------------------------------------------------
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

# Start the log file (WRITE tool — initializing context)
if [[ "$DRY_RUN" == "false" ]]; then
    echo "# File Organizer Agent — $(date)" > "$LOG_FILE"
    echo "# Target: $TARGET_DIR" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

# ---------------------------------------------------------------------------
# COUNTERS (accumulated as the agent loops)
# Using individual variables for bash 3 compatibility (macOS default shell)
# ---------------------------------------------------------------------------
count_docs=0
count_images=0
count_scripts=0
count_data=0
count_misc=0
total_count=0
skipped_count=0

# ---------------------------------------------------------------------------
# MAIN AGENT LOOP
# Pi pattern: READ → DECIDE → BASH → WRITE, repeated for each file
# ---------------------------------------------------------------------------

# READ: list all files in the target directory (not subdirectories)
# We use find with -maxdepth 1 -type f so we don't descend into existing
# category subdirs and don't pick up directories as files.
while IFS= read -r filepath; do
    filename=$(basename "$filepath")

    # Skip the log file itself
    if [[ "$filename" == "$LOG_FILENAME" ]]; then
        continue
    fi

    # Skip hidden files (dotfiles)
    if [[ "$filename" == .* ]]; then
        skipped_count=$(( skipped_count + 1 ))
        continue
    fi

    # DECIDE: determine which category this file belongs to
    category=$(classify_file "$filename")

    # Build the destination path
    dest_dir="$TARGET_DIR/$category"
    dest_file="$dest_dir/$filename"

    # Handle filename collisions: if destination already exists, add a suffix
    if [[ -e "$dest_file" ]]; then
        base="${filename%.*}"
        ext="${filename##*.}"
        counter=2
        while [[ -e "$dest_dir/${base}_${counter}.${ext}" ]]; do
            ((counter++))
        done
        dest_file="$dest_dir/${base}_${counter}.${ext}"
        filename="${base}_${counter}.${ext}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        # Dry run: just print what would happen
        printf "  ${YELLOW}[WOULD MOVE]${NC} %-30s → %s/\n" "$filename" "$category"
    else
        # BASH tool: create the category directory if needed, then move the file
        mkdir -p "$dest_dir"
        mv "$filepath" "$dest_file"

        # WRITE tool: append the action to the log
        log_action "MOVED $filename → $category/"

        printf "  ${GREEN}[MOVED]${NC} %-30s → %s/\n" "$filename" "$category"
    fi

    # Accumulate counts (using individual vars for bash 3 compatibility)
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
# SUMMARY
# Pi pattern: WRITE — write the final summary to log and stdout
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
    # Write summary to log
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
