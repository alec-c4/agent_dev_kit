# Kit hook shared helpers — source from hook scripts only.
# Supports Claude Code (PreToolUse/PostToolUse) and Cursor (beforeShellExecution/…).

kit_read_input() {
  KIT_HOOK_INPUT="$(cat)"
  KIT_HOOK_COMMAND=""
  KIT_HOOK_FILE=""

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
  fi
}

kit_block() {
  local msg="$1"
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
