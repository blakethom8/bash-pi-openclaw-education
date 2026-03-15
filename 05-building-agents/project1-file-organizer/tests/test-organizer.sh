#!/bin/bash
# test-organizer.sh - Tests for the file organizer agent
#
# Creates a temporary directory with known files, runs the agent,
# and verifies that files end up in the correct locations.
#
# Usage: ./tests/test-organizer.sh [--verbose]

set -euo pipefail

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT="$SCRIPT_DIR/../agent.sh"

VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$@"
    fi
}

pass() {
    local test_name="$1"
    echo -e "  ${GREEN}PASS${NC}  $test_name"
    ((TESTS_PASSED++)) || true
}

fail() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "  ${RED}FAIL${NC}  $test_name"
    if [[ -n "$reason" ]]; then
        echo "        $reason"
    fi
    ((TESTS_FAILED++)) || true
}

assert_file_exists() {
    local description="$1"
    local filepath="$2"
    if [[ -f "$filepath" ]]; then
        pass "$description"
    else
        fail "$description" "Expected file not found: $filepath"
    fi
}

assert_file_not_exists() {
    local description="$1"
    local filepath="$2"
    if [[ ! -f "$filepath" ]]; then
        pass "$description"
    else
        fail "$description" "File should not exist: $filepath"
    fi
}

# ---------------------------------------------------------------------------
# Create test workspace
# ---------------------------------------------------------------------------
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  File Organizer Agent — Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test directory: $TEST_DIR"
echo ""

# ---------------------------------------------------------------------------
# TEST 1: Basic file categorization
# ---------------------------------------------------------------------------
echo "Test 1: Basic file categorization"

# Create one file of each category
touch "$TEST_DIR/quarterly_report.pdf"
touch "$TEST_DIR/meeting_notes.txt"
touch "$TEST_DIR/profile_photo.jpg"
touch "$TEST_DIR/data_export.csv"
touch "$TEST_DIR/process_claims.sh"
touch "$TEST_DIR/provider_lookup.py"
touch "$TEST_DIR/config.json"
touch "$TEST_DIR/archive.zip"

log "  Created test files."
log "  Running agent..."

"$AGENT" "$TEST_DIR" > /dev/null

assert_file_exists "PDF goes to docs/" "$TEST_DIR/docs/quarterly_report.pdf"
assert_file_exists "TXT goes to docs/" "$TEST_DIR/docs/meeting_notes.txt"
assert_file_exists "JPG goes to images/" "$TEST_DIR/images/profile_photo.jpg"
assert_file_exists "CSV goes to data/" "$TEST_DIR/data/data_export.csv"
assert_file_exists "SH goes to scripts/" "$TEST_DIR/scripts/process_claims.sh"
assert_file_exists "PY goes to scripts/" "$TEST_DIR/scripts/provider_lookup.py"
assert_file_exists "JSON goes to data/" "$TEST_DIR/data/config.json"
assert_file_exists "ZIP goes to misc/" "$TEST_DIR/misc/archive.zip"

echo ""

# ---------------------------------------------------------------------------
# TEST 2: Log file is created
# ---------------------------------------------------------------------------
echo "Test 2: Log file creation"

assert_file_exists "organizer.log created" "$TEST_DIR/organizer.log"

if [[ -f "$TEST_DIR/organizer.log" ]]; then
    log_content=$(cat "$TEST_DIR/organizer.log")
    if echo "$log_content" | grep -q "MOVED"; then
        pass "Log contains MOVED entries"
    else
        fail "Log contains MOVED entries" "Log content: $log_content"
    fi

    if echo "$log_content" | grep -q "SUMMARY"; then
        pass "Log contains SUMMARY entry"
    else
        fail "Log contains SUMMARY entry"
    fi
fi

echo ""

# ---------------------------------------------------------------------------
# TEST 3: Dry run does not move files
# ---------------------------------------------------------------------------
echo "Test 3: Dry run mode"

DRY_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" "$DRY_DIR"' EXIT

touch "$DRY_DIR/report.pdf"
touch "$DRY_DIR/photo.png"
touch "$DRY_DIR/script.sh"

"$AGENT" --dry-run "$DRY_DIR" > /dev/null

assert_file_exists "Original PDF still in root (dry run)" "$DRY_DIR/report.pdf"
assert_file_exists "Original PNG still in root (dry run)" "$DRY_DIR/photo.png"
assert_file_exists "Original SH still in root (dry run)" "$DRY_DIR/script.sh"
assert_file_not_exists "No docs/ dir created (dry run)" "$DRY_DIR/docs/report.pdf"
assert_file_not_exists "No log created (dry run)" "$DRY_DIR/organizer.log"

echo ""

# ---------------------------------------------------------------------------
# TEST 4: Uppercase extensions are handled
# ---------------------------------------------------------------------------
echo "Test 4: Case-insensitive extension matching"

CASE_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" "$DRY_DIR" "$CASE_DIR"' EXIT

touch "$CASE_DIR/DOCUMENT.PDF"
touch "$CASE_DIR/IMAGE.JPG"
touch "$CASE_DIR/SPREADSHEET.CSV"

"$AGENT" "$CASE_DIR" > /dev/null

assert_file_exists "PDF (uppercase) goes to docs/" "$CASE_DIR/docs/DOCUMENT.PDF"
assert_file_exists "JPG (uppercase) goes to images/" "$CASE_DIR/images/IMAGE.JPG"
assert_file_exists "CSV (uppercase) goes to data/" "$CASE_DIR/data/SPREADSHEET.CSV"

echo ""

# ---------------------------------------------------------------------------
# TEST 5: Files already in category dirs are not double-moved
# ---------------------------------------------------------------------------
echo "Test 5: Existing files in subdirectories are not touched"

EXISTING_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" "$DRY_DIR" "$CASE_DIR" "$EXISTING_DIR"' EXIT

mkdir -p "$EXISTING_DIR/docs"
touch "$EXISTING_DIR/docs/already_organized.pdf"
touch "$EXISTING_DIR/new_file.pdf"

"$AGENT" "$EXISTING_DIR" > /dev/null

assert_file_exists "Pre-existing file in docs/ still there" "$EXISTING_DIR/docs/already_organized.pdf"
assert_file_exists "New file moved to docs/" "$EXISTING_DIR/docs/new_file.pdf"

echo ""

# ---------------------------------------------------------------------------
# TEST 6: Filename collision handling
# ---------------------------------------------------------------------------
echo "Test 6: Filename collision (duplicate filenames)"

COLLISION_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" "$DRY_DIR" "$CASE_DIR" "$EXISTING_DIR" "$COLLISION_DIR"' EXIT

mkdir -p "$COLLISION_DIR/docs"
# Pre-place a file in the destination
touch "$COLLISION_DIR/docs/report.pdf"
# Now also have one in the root
touch "$COLLISION_DIR/report.pdf"

"$AGENT" "$COLLISION_DIR" > /dev/null

assert_file_exists "Original docs/report.pdf preserved" "$COLLISION_DIR/docs/report.pdf"
assert_file_exists "Conflicting file renamed report_2.pdf" "$COLLISION_DIR/docs/report_2.pdf"

echo ""

# ---------------------------------------------------------------------------
# TEST 7: Empty directory runs without error
# ---------------------------------------------------------------------------
echo "Test 7: Empty directory"

EMPTY_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" "$DRY_DIR" "$CASE_DIR" "$EXISTING_DIR" "$COLLISION_DIR" "$EMPTY_DIR"' EXIT

output=$("$AGENT" "$EMPTY_DIR" 2>&1)
exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
    pass "Agent exits cleanly on empty directory"
else
    fail "Agent exits cleanly on empty directory" "Exit code: $exit_code"
fi

echo ""

# ---------------------------------------------------------------------------
# FINAL RESULTS
# ---------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
total=$((TESTS_PASSED + TESTS_FAILED))
echo "  Results: $TESTS_PASSED/$total tests passed"

if [[ "$TESTS_FAILED" -eq 0 ]]; then
    echo -e "  ${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "  ${RED}$TESTS_FAILED test(s) failed.${NC}"
    exit 1
fi
