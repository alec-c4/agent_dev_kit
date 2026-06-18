#!/usr/bin/env bash
# block-dangerous.sh — Block destructive shell commands (fail-closed).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0

if echo "$KIT_HOOK_COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|--force\s+)'; then
  kit_block "BLOCKED: 'rm -f / rm -rf' is not allowed. Use trash or move to /tmp instead."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/'; then
  kit_block "BLOCKED: recursive rm on an absolute path is not allowed."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+push.*(--force|-f)(\s|$)'; then
  kit_block "BLOCKED: 'git push --force' is not allowed. Use --force-with-lease after human confirm."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  kit_block "BLOCKED: 'git reset --hard' discards uncommitted work. Confirm with the human first."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  kit_block "BLOCKED: destructive SQL (DROP/TRUNCATE) detected. Confirm with the human first."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'kill\s+-9\s+-1|killall\s+-9'; then
  kit_block "BLOCKED: killing all processes is not allowed."
fi
exit 0
