#!/usr/bin/env bash
# install.sh — Deploy Agent Dev Kit guidelines and tool adapters
#
# Usage:
#   ./scripts/install.sh --target=both              # Claude Code + Cursor (default)
#   ./scripts/install.sh --target=claude            # Claude Code (~/.claude/)
#   ./scripts/install.sh --target=cursor            # Cursor (~/.cursor/agent_dev_kit + kit rules)
#   ./scripts/install.sh --target=both --project    # current repo
#   ./scripts/install.sh --dry-run --target=both
#   ./scripts/kit install --target=both   # same; works from fish/zsh/bash
#
# Canonical entry: AGENTS.md. CLAUDE.md is a Claude Code adapter only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT_LINK_NAME="agent_dev_kit"
TARGET="both"
SCOPE="global"
MODE="symlink"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --target=*) TARGET="${arg#--target=}" ;;
    --project) SCOPE="project" ;;
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

case "$TARGET" in
  claude|cursor|both) ;;
  *)
    echo "ERROR: --target must be claude, cursor, or both" >&2
    exit 1
    ;;
esac

log() { echo "  $*"; }

maybe() {
  if $DRY_RUN; then
    echo "  [dry] $*"
  else
    "$@"
  fi
}

link_or_copy() {
  local src="$1" dest="$2"
  if [[ ! -e "$src" ]]; then
    echo "ERROR: missing source $src" >&2
    exit 1
  fi
  maybe mkdir -p "$(dirname "$dest")"
  if $DRY_RUN; then
    echo "  [dry] $MODE $src -> $dest"
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi
  if [[ "$MODE" == "symlink" ]]; then
    ln -s "$src" "$dest"
  else
    if [[ -d "$src" ]]; then
      cp -R "$src" "$dest"
    else
      cp "$src" "$dest"
    fi
  fi
}

deploy_file() {
  link_or_copy "$REPO_DIR/$1" "$2/$1"
}

deploy_dir() {
  link_or_copy "$REPO_DIR/$1" "$2/$1"
}

install_claude() {
  local base="$1"
  log "Claude Code adapter → $base"
  deploy_file "AGENTS.md" "$base"
  deploy_file "CLAUDE.md" "$base"
  deploy_dir "docs" "$base"
  deploy_dir "registry" "$base"
  deploy_dir "scripts" "$base"
  deploy_dir "skills" "$base"
  deploy_dir ".ai" "$base"
}

install_cursor_rules_global() {
  local rules_dir="$1"
  log "Cursor rules → $rules_dir"
  maybe mkdir -p "$rules_dir"
  for mdc in "$REPO_DIR"/templates/cursor/rules/*.mdc; do
    [[ -f "$mdc" ]] || continue
    link_or_copy "$mdc" "$rules_dir/$(basename "$mdc")"
  done
}

install_cursor_rules_project() {
  local rules_dir="$1"
  local tmp
  tmp="$(mktemp)"
  log "Cursor rules → $rules_dir (project paths)"
  maybe mkdir -p "$rules_dir"
  for mdc in "$REPO_DIR"/templates/cursor/rules/*.mdc; do
    [[ -f "$mdc" ]] || continue
    sed "s|../${KIT_LINK_NAME}/||g" "$mdc" > "$tmp"
    if $DRY_RUN; then
      echo "  [dry] write project rule $(basename "$mdc") -> $rules_dir/"
    else
      cp "$tmp" "$rules_dir/$(basename "$mdc")"
    fi
  done
  rm -f "$tmp"
}

install_cursor_global() {
  log "Cursor → ~/.cursor/${KIT_LINK_NAME} (kit link) + ~/.cursor/rules/kit-*.mdc"
  link_or_copy "$REPO_DIR" "$HOME/.cursor/${KIT_LINK_NAME}"
  install_cursor_rules_global "$HOME/.cursor/rules"
  sync_cursor_user_rules
}

sync_cursor_user_rules() {
  log "Cursor user-rules manifest → ~/.cursor/kit-user-rules.manifest.json"
  if $DRY_RUN; then
    echo "  [dry] ./scripts/kit sync-rules"
    return
  fi
  "$REPO_DIR/scripts/kit" sync-rules
}

install_cursor_project() {
  local base="$1"
  log "Cursor project → $base"
  deploy_file "AGENTS.md" "$base"
  deploy_dir "docs" "$base"
  deploy_dir "registry" "$base"
  deploy_dir "scripts" "$base"
  deploy_dir "skills" "$base"
  deploy_dir ".ai" "$base"
  maybe mkdir -p "$base/.cursor"
  install_cursor_rules_project "$base/.cursor/rules"
  sync_cursor_user_rules_project "$base"
}

sync_cursor_user_rules_project() {
  local base="$1"
  log "Cursor user-rules manifest (global + project rules)"
  if $DRY_RUN; then
    echo "  [dry] sync-cursor-user-rules.sh --rules-dir $HOME/.cursor/rules --rules-dir $base/.cursor/rules"
    return
  fi
  local args=(--rules-dir "$HOME/.cursor/rules")
  if [[ -d "$base/.cursor/rules" ]]; then
    args+=(--rules-dir "$base/.cursor/rules")
  fi
  bash "$REPO_DIR/scripts/kit" sync-rules "${args[@]}"
}

if [[ "$SCOPE" == "project" ]]; then
  CLAUDE_BASE="$(pwd)"
else
  CLAUDE_BASE="$HOME/.claude"
fi

echo "Agent Dev Kit install"
echo "  repo:    $REPO_DIR"
echo "  target:  $TARGET"
echo "  scope:   $SCOPE"
echo "  mode:    $MODE"
echo "  entry:   AGENTS.md"
$DRY_RUN && echo "  dry-run: yes"
echo

if [[ "$TARGET" == "claude" || "$TARGET" == "both" ]]; then
  install_claude "$CLAUDE_BASE"
fi

if [[ "$TARGET" == "cursor" || "$TARGET" == "both" ]]; then
  if [[ "$SCOPE" == "project" ]]; then
    install_cursor_project "$(pwd)"
  else
    install_cursor_global
  fi
fi

echo
log "Done. Restart your AI tool to pick up changes."
log "Canonical instructions: AGENTS.md → docs/guidelines/"
