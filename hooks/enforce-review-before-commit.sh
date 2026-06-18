#!/usr/bin/env bash
# enforce-review-before-commit.sh — Require review-passed flag when review gate enabled (opt-in).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0
echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+commit\b' || exit 0
[[ "$KIT_HOOK_COMMAND" == *"--no-edit"* ]] && exit 0

kit_review_gate_enabled || exit 0

if ! kit_any_review_flag; then
  kit_block "BLOCKED: review gate enabled but no review-passed flag. Run /review and approve, or: bash hooks/mark-review-passed.sh"
fi
exit 0
