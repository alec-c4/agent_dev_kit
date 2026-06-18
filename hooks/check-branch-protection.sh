#!/usr/bin/env bash
# check-branch-protection.sh — Block git commit/push on main, master, develop.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0
echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+(commit|push)\b' || exit 0

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[[ -z "$BRANCH" ]] && exit 0

case "$BRANCH" in
  main|master|develop)
    kit_block "BLOCKED: direct commit/push to '$BRANCH' is not allowed. Create a feature branch first (see docs/guidelines/GIT.md)."
    ;;
esac
exit 0
