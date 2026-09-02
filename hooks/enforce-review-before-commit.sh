#!/usr/bin/env bash
# enforce-review-before-commit.sh — Require review-passed flag when review gate enabled (opt-in).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
kit_require_parser
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0
echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+commit\b' || exit 0
[[ "$KIT_HOOK_COMMAND" == *"--no-edit"* ]] && exit 0

kit_review_gate_enabled || exit 0

if ! kit_any_review_flag; then
  kit_block "commit while the review gate is enabled" \
    "This project requires a passing review before each commit; no review-passed flag is set." \
    "Run /review and address the findings, then: bash hooks/mark-review-passed.sh"
fi
exit 0
