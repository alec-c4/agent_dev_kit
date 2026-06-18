#!/usr/bin/env bash
# check-commit-scope.sh — Guard against multi-feature commits (fail-closed).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0
echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+commit\b' || exit 0

STAGED_FILES="$(git diff --staged --name-only 2>/dev/null)"
[[ -z "$STAGED_FILES" ]] && exit 0

FILE_COUNT="$(echo "$STAGED_FILES" | wc -l | tr -d ' ')"
DIR_COUNT="$(echo "$STAGED_FILES" | awk -F/ 'NF>1{print $1} NF==1{print "."}' | sort -u | wc -l | tr -d ' ')"

MSG="$(printf '%s' "$KIT_HOOK_COMMAND" | sed -nE 's/.*-m[[:space:]]+"([^"]+)".*/\1/p' 2>/dev/null)"
[[ -z "$MSG" ]] && MSG="$(printf '%s' "$KIT_HOOK_COMMAND" | sed -nE "s/.*-m[[:space:]]+'([^']+)'.*/\1/p" 2>/dev/null)"

if printf '%s' "$MSG" | grep -qiE '\band\b'; then
  kit_block "BLOCKED: commit message contains 'and' — likely multiple changes. One commit = one logical change (see docs/guidelines/COMMITS.md)."
fi

if [[ "$FILE_COUNT" -gt 15 && "$DIR_COUNT" -gt 4 ]]; then
  kit_block "BLOCKED: staged area has $FILE_COUNT files across $DIR_COUNT directories — split into atomic commits."
fi
exit 0
