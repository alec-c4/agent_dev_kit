#!/usr/bin/env bash
# clear-review-flag.sh — Clear one-use review flags after successful git commit (fail-open).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0
echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+commit\b' || exit 0
kit_clear_review_flags
exit 0
