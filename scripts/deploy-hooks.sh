#!/usr/bin/env bash
# deploy-hooks.sh — Install kit shell hooks for Claude Code and Cursor
#
# Usage:
#   bash scripts/deploy-hooks.sh --scope=global|project [--target=claude|cursor|both] [--review-gate] [--merge-settings] [--dry-run]
#   ./scripts/kit deploy-hooks --scope=project --target=both --review-gate
#
# Review gate is opt-in: creates .ai/kit-review-gate in project (or ~/.claude/kit-review-gate global).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCOPE="global"
TARGET="both"
REVIEW_GATE=false
MERGE_SETTINGS=false
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --scope=*) SCOPE="${arg#--scope=}" ;;
    --target=*) TARGET="${arg#--target=}" ;;
    --review-gate) REVIEW_GATE=true ;;
    --merge-settings) MERGE_SETTINGS=true ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

case "$SCOPE" in global|project) ;; *)
  echo "ERROR: --scope must be global or project" >&2
  exit 1
  ;;
esac

case "$TARGET" in claude|cursor|both) ;; *)
  echo "ERROR: --target must be claude, cursor, or both" >&2
  exit 1
  ;;
esac

log() { echo "  $*"; }
run() { $DRY_RUN && echo "  [dry] $*" || eval "$@"; }

chmod_hooks() {
  if $DRY_RUN; then return; fi
  find "$REPO_DIR/hooks" -name '*.sh' -exec chmod +x {} +
}

deploy_claude_hooks() {
  local base="$1"
  log "Claude hooks → $base/hooks"
  run "mkdir -p '$(dirname "$base/hooks")'"
  if $DRY_RUN; then
    echo "  [dry] ln -s $REPO_DIR/hooks $base/hooks"
  else
    rm -rf "$base/hooks"
    ln -s "$REPO_DIR/hooks" "$base/hooks"
  fi

  local fragment="$base/settings.hooks.kit.json"
  sed "s|__CLAUDE_HOOKS__|$base/hooks|g" "$REPO_DIR/templates/claude/settings.hooks.json" > "${fragment}.tmp"
  if $DRY_RUN; then
    echo "  [dry] write $fragment"
    rm -f "${fragment}.tmp"
  else
    mv "${fragment}.tmp" "$fragment"
  fi

  if $MERGE_SETTINGS && [[ -f "$base/settings.json" ]] && command -v jq &>/dev/null; then
    log "Merge hooks into $base/settings.json"
    if $DRY_RUN; then
      echo "  [dry] jq merge settings.hooks.kit.json into settings.json"
    else
      jq -s '.[0] * {hooks: .[1].hooks}' "$base/settings.json" "$fragment" > "$base/settings.json.tmp"
      mv "$base/settings.json.tmp" "$base/settings.json"
    fi
  else
    log "Hook fragment: $fragment — merge into settings.json or use --merge-settings"
  fi

  if $REVIEW_GATE; then
    local gate="$base/kit-review-gate"
    log "Review gate marker → $gate"
    run "touch '$gate'"
    log "Export KIT_REVIEW_GATE=1 in shell profile, or rely on project .ai/kit-review-gate"
  fi
}

deploy_cursor_hooks() {
  local hooks_path="$1"
  local dest="$2"
  log "Cursor hooks.json → $dest"
  run "mkdir -p '$(dirname "$dest")'"
  if $DRY_RUN; then
    echo "  [dry] write $dest (hooks path: $hooks_path)"
  else
    sed "s|__KIT_HOOKS__|$hooks_path|g" "$REPO_DIR/templates/cursor/hooks.json" > "$dest"
  fi
}

chmod_hooks

if [[ "$SCOPE" == "global" ]]; then
  if [[ "$TARGET" == "claude" || "$TARGET" == "both" ]]; then
    deploy_claude_hooks "$HOME/.claude"
  fi
  if [[ "$TARGET" == "cursor" || "$TARGET" == "both" ]]; then
    if [[ -d "$HOME/.cursor/agent_dev_kit/hooks" ]]; then
      local_kit="$(cd "$HOME/.cursor/agent_dev_kit/hooks" && pwd)"
    else
      local_kit="$(cd "$REPO_DIR/hooks" && pwd)"
      log "WARN: ~/.cursor/agent_dev_kit missing — using kit repo hooks path"
    fi
    deploy_cursor_hooks "$local_kit" "$HOME/.cursor/hooks.json"
  fi
  if $REVIEW_GATE; then
    run "touch '$HOME/.claude/kit-review-gate'"
  fi
else
  PROJECT_DIR="$(pwd)"
  if [[ "$TARGET" == "claude" || "$TARGET" == "both" ]]; then
    deploy_claude_hooks "$PROJECT_DIR/.claude"
  fi
  if [[ "$TARGET" == "cursor" || "$TARGET" == "both" ]]; then
    if $DRY_RUN; then
      echo "  [dry] ln -s $REPO_DIR/hooks $PROJECT_DIR/hooks"
    elif [[ ! -e "$PROJECT_DIR/hooks" ]]; then
      ln -s "$REPO_DIR/hooks" "$PROJECT_DIR/hooks"
    fi
    hooks_abs="$(cd "$PROJECT_DIR" && cd hooks 2>/dev/null && pwd || echo "$REPO_DIR/hooks")"
    deploy_cursor_hooks "$hooks_abs" "$PROJECT_DIR/.cursor/hooks.json"
  fi
  if $REVIEW_GATE; then
    run "mkdir -p '$PROJECT_DIR/.ai'"
    run "touch '$PROJECT_DIR/.ai/kit-review-gate'"
  fi
fi

log "Done. Restart Claude Code / Cursor to load hooks."
