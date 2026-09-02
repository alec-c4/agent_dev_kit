#!/usr/bin/env bash
# block-dangerous.sh — Block destructive shell commands (fail-closed).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0

if echo "$KIT_HOOK_COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|--force\s+)'; then
  kit_block "forced remove (rm -f / rm -rf)" \
    "Forced removal deletes files with no prompt and no undo." \
    "Move the target to /tmp or use trash, then ask the human if it must really be deleted."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/'; then
  kit_block "recursive rm on an absolute path" \
    "An absolute path can reach outside the project and delete unrelated files." \
    "Use a path relative to the project root, and confirm the target with the human first."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+push.*(--force|-f)(\s|$)'; then
  kit_block "git push --force" \
    "A plain force push overwrites remote commits that other people may already have." \
    "Use 'git push --force-with-lease' after the human confirms the rewrite."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  kit_block "git reset --hard" \
    "It discards uncommitted work in the tree with no way to recover it." \
    "Run 'git stash' to park the changes, or ask the human before discarding them."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  kit_block "destructive SQL (DROP / TRUNCATE)" \
    "Dropping or truncating removes data and schema that a migration cannot restore." \
    "Write a reversible migration, or ask the human to run this against the database themselves."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'kill\s+-9\s+-1|killall\s+-9'; then
  kit_block "kill of every process" \
    "It terminates the human's own editors, servers, and shells, not just this task." \
    "Target the specific PID or process name you need to stop."
fi
exit 0
