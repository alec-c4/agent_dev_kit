# shellcheck shell=bash
# Kit hook shared helpers — source from hook scripts only.
# shellcheck disable=SC2034  # KIT_HOOK_* are read by the sourcing hook scripts.
# Supports Claude Code (PreToolUse/PostToolUse) and Cursor (beforeShellExecution/…).

# Set by kit_read_input when neither jq nor python3 is available: the payload
# could not be parsed, so a deny hook must not silently allow the command.
KIT_HOOK_UNPARSED=0

kit_read_input() {
  KIT_HOOK_INPUT="$(cat)"
  KIT_HOOK_COMMAND=""
  KIT_HOOK_FILE=""
  KIT_HOOK_UNPARSED=0

  if command -v jq &>/dev/null; then
    KIT_HOOK_COMMAND="$(printf '%s' "$KIT_HOOK_INPUT" | jq -r '.command // .tool_input.command // empty' 2>/dev/null || true)"
    KIT_HOOK_FILE="$(printf '%s' "$KIT_HOOK_INPUT" | jq -r '.file_path // .tool_input.file_path // empty' 2>/dev/null || true)"
  elif command -v python3 &>/dev/null; then
    KIT_HOOK_COMMAND="$(printf '%s' "$KIT_HOOK_INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('command') or d.get('tool_input', {}).get('command') or '')
" 2>/dev/null || true)"
    KIT_HOOK_FILE="$(printf '%s' "$KIT_HOOK_INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('file_path') or d.get('tool_input', {}).get('file_path') or '')
" 2>/dev/null || true)"
  else
    KIT_HOOK_UNPARSED=1
  fi
}

# Deny hooks are advertised as fail-closed. Without a JSON parser they cannot
# read the command, so they must say so rather than return 0 and allow it.
kit_require_parser() {
  [[ "${KIT_HOOK_UNPARSED:-0}" == "1" ]] || return 0
  kit_block "shell command that the kit hook could not inspect" \
    "This hook needs jq or python3 to read the tool payload, and neither is on PATH." \
    "Install jq (brew install jq / apt-get install jq), or disable the kit hooks in your tool settings."
}

kit_block() {
  local what="$1"
  local why="${2:-This command is not allowed.}"
  local next="${3:-Use a safer command or confirm with the human.}"
  local msg
  msg="$(printf 'Blocked: %s\nWhy: %s\nNext: %s' "$what" "$why" "$next")"
  if [[ "${KIT_HOOK_TARGET:-}" == "cursor" ]]; then
    python3 - "$msg" <<'PY'
import json, sys
msg = sys.argv[1]
print(json.dumps({
    "permission": "deny",
    "user_message": msg,
    "agent_message": msg,
}))
PY
    exit 0
  fi
  echo "$msg" >&2
  exit 2
}

kit_review_gate_enabled() {
  [[ "${KIT_REVIEW_GATE:-}" == "1" ]] && return 0
  [[ -f ".kit-review-gate" ]] && return 0
  [[ -f ".ai/kit-review-gate" ]] && return 0
  [[ -f "${HOME}/.claude/kit-review-gate" ]] && return 0
  return 1
}

kit_review_flags() {
  # Per-tool one-use flags (project root)
  printf '%s\n' ".claude/review-passed" ".cursor/review-passed" ".agents/review-passed"
}

kit_any_review_flag() {
  local f
  while IFS= read -r f; do
    [[ -f "$f" ]] && return 0
  done < <(kit_review_flags)
  return 1
}

kit_clear_review_flags() {
  local f
  while IFS= read -r f; do
    [[ -f "$f" ]] && rm -f "$f"
  done < <(kit_review_flags)
}

kit_find_root() {
  if [[ -n "${KIT_DIR:-}" && -f "${KIT_DIR}/scripts/kit" ]]; then
    printf '%s' "$KIT_DIR"
    return 0
  fi
  local d
  for d in \
    "${HOME}/.cursor/agent_dev_kit" \
    "${HOME}/.claude" \
    "$(git rev-parse --show-toplevel 2>/dev/null)/agent_dev_kit" \
    "$(pwd)/agent_dev_kit"; do
    [[ -n "$d" && -f "$d/scripts/kit" ]] || continue
    printf '%s' "$d"
    return 0
  done
  return 1
}
