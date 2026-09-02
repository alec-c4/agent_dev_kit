#!/usr/bin/env bash
# check-commit-scope.sh — Guard against multi-feature commits (fail-closed).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
kit_require_parser
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0
echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+commit\b' || exit 0

STAGED_FILES="$(git diff --staged --name-only 2>/dev/null)"
[[ -z "$STAGED_FILES" ]] && exit 0

FILE_COUNT="$(echo "$STAGED_FILES" | wc -l | tr -d ' ')"
DIR_COUNT="$(echo "$STAGED_FILES" | awk -F/ 'NF>1{print $1} NF==1{print "."}' | sort -u | wc -l | tr -d ' ')"

MSG="$(printf '%s' "$KIT_HOOK_COMMAND" | sed -nE 's/.*-m[[:space:]]+"([^"]+)".*/\1/p' 2>/dev/null)"
[[ -z "$MSG" ]] && MSG="$(printf '%s' "$KIT_HOOK_COMMAND" | sed -nE "s/.*-m[[:space:]]+'([^']+)'.*/\1/p" 2>/dev/null)"
# Unquoted -m, -F file, and editor commits leave MSG empty — the size check
# below still applies, and it reads the staged tree rather than the command line.

# A bare "and" is ordinary English ("parse header and trailer"). Only flag a
# subject that joins two conventional-commit *types* — that is two changes.
if [[ -n "$MSG" ]] \
  && printf '%s' "$MSG" \
    | grep -qiE '^[[:space:]]*(feat|fix|refactor|chore|docs|test|perf|build|ci|style|revert)([(!][^:]*)?:.*\b(and|\+)\b.*\b(feat|fix|refactor|chore|docs|test|perf|build|ci|style|revert)\b'; then
  kit_block "commit message joining two change types" \
    "The subject names more than one kind of change, so the commit cannot be reviewed or reverted as one unit." \
    "Split it: stage and commit each change separately (see docs/guidelines/COMMITS.md)."
fi

if [[ "$FILE_COUNT" -gt 15 && "$DIR_COUNT" -gt 4 ]]; then
  kit_block "commit spanning $FILE_COUNT files across $DIR_COUNT directories" \
    "A commit this wide cannot be reviewed or reverted as one logical change." \
    "Stage one logical change with 'git add -p' or per path, and commit it on its own."
fi
exit 0
