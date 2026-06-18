#!/usr/bin/env bash
# install.sh — Deploy Agent Dev Kit guidelines and tool adapters
#
# Usage:
#   ./scripts/install.sh --target=both              # Claude Code + Cursor (default)
#   ./scripts/install.sh --target=all               # claude + cursor + codex + antigravity
#   ./scripts/install.sh --target=claude            # Claude Code (~/.claude/)
#   ./scripts/install.sh --target=cursor            # Cursor (~/.cursor/agent_dev_kit + kit rules)
#   ./scripts/install.sh --target=codex             # OpenAI Codex (~/.codex/ or $CODEX_HOME)
#   ./scripts/install.sh --target=antigravity       # Google Antigravity (~/.gemini/)
#   ./scripts/install.sh --target=all --project     # current repo
#   ./scripts/install.sh --dry-run --target=codex
#   ./scripts/kit install --target=all              # same; works from fish/zsh/bash
#
# Canonical entry: AGENTS.md. CLAUDE.md and GEMINI.md are thin adapters only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT_LINK_NAME="agent_dev_kit"
TARGET="both"
SCOPE="global"
MODE="symlink"
DRY_RUN=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --target=*) TARGET="${arg#--target=}" ;;
    --project) SCOPE="project" ;;
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --help|-h)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

case "$TARGET" in
  claude|cursor|both|codex|antigravity|all) ;;
  *)
    echo "ERROR: --target must be claude, cursor, both, codex, antigravity, or all" >&2
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

deploy_file_to() {
  link_or_copy "$REPO_DIR/$1" "$2"
}

deploy_optional_file() {
  local src_name="$1" dest_path="$2"
  if [[ -e "$dest_path" && "$FORCE" != true ]]; then
    log "skip (exists): $dest_path — use --force to replace"
    return
  fi
  link_or_copy "$REPO_DIR/$src_name" "$dest_path"
}

deploy_kit_tree() {
  local base="$1"
  deploy_dir "docs" "$base"
  deploy_dir "registry" "$base"
  deploy_dir "scripts" "$base"
  deploy_dir "skills" "$base"
  deploy_dir ".ai" "$base"
}

install_project_agents_scaffold() {
  local base="$1"
  log "Project .agents/ scaffold → $base/.agents/"
  if $DRY_RUN; then
    echo "  [dry] mkdir $base/.agents/skills $base/.agents/workflows"
    echo "  [dry] write README stubs in .agents/skills and .agents/workflows"
    return
  fi
  maybe mkdir -p "$base/.agents/skills" "$base/.agents/workflows"
  if [[ ! -f "$base/.agents/skills/README.md" ]]; then
    cp "$REPO_DIR/templates/project-agents/skills-README.md" "$base/.agents/skills/README.md"
  fi
  if [[ ! -f "$base/.agents/workflows/README.md" ]]; then
    cp "$REPO_DIR/templates/project-agents/workflows-README.md" "$base/.agents/workflows/README.md"
  fi
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

install_codex() {
  local base="${CODEX_HOME:-$HOME/.codex}"
  log "Codex CLI → $base (AGENTS.md + kit tree; \$CODEX_HOME=${CODEX_HOME:-default})"
  deploy_optional_file "AGENTS.md" "$base/AGENTS.md"
  deploy_kit_tree "$base"
  log "Codex: debug merged instructions with: codex --print-instructions"
}

install_codex_project() {
  local base="$1"
  log "Codex project → $base"
  deploy_file "AGENTS.md" "$base"
  deploy_dir "docs" "$base"
  deploy_dir "registry" "$base"
  deploy_dir "scripts" "$base"
  deploy_dir "skills" "$base"
  deploy_dir ".ai" "$base"
  install_project_agents_scaffold "$base"
}

install_antigravity() {
  local base="$HOME/.gemini"
  log "Antigravity → $base (AGENTS.md + GEMINI.md + kit tree)"
  deploy_optional_file "AGENTS.md" "$base/AGENTS.md"
  deploy_optional_file "GEMINI.md" "$base/GEMINI.md"
  deploy_kit_tree "$base"
  log "Antigravity CLI skills path: $base/antigravity-cli/skills/ (copy from ~/.agents/skills if CLI misses skills)"
}

install_antigravity_project() {
  local base="$1"
  log "Antigravity project → $base"
  deploy_file "AGENTS.md" "$base"
  deploy_optional_file "GEMINI.md" "$base/GEMINI.md"
  deploy_dir "docs" "$base"
  deploy_dir "registry" "$base"
  deploy_dir "scripts" "$base"
  deploy_dir "skills" "$base"
  deploy_dir ".ai" "$base"
  install_project_agents_scaffold "$base"
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

want_claude() { [[ "$TARGET" == "claude" || "$TARGET" == "both" || "$TARGET" == "all" ]]; }
want_cursor() { [[ "$TARGET" == "cursor" || "$TARGET" == "both" || "$TARGET" == "all" ]]; }
want_codex() { [[ "$TARGET" == "codex" || "$TARGET" == "all" ]]; }
want_antigravity() { [[ "$TARGET" == "antigravity" || "$TARGET" == "all" ]]; }

if [[ "$SCOPE" == "project" ]]; then
  CLAUDE_BASE="$(pwd)"
  PROJECT_BASE="$(pwd)"
else
  CLAUDE_BASE="$HOME/.claude"
  PROJECT_BASE=""
fi

echo "Agent Dev Kit install"
echo "  repo:    $REPO_DIR"
echo "  target:  $TARGET"
echo "  scope:   $SCOPE"
echo "  mode:    $MODE"
echo "  entry:   AGENTS.md"
$DRY_RUN && echo "  dry-run: yes"
$FORCE && echo "  force:   yes"
echo

if want_claude; then
  install_claude "$CLAUDE_BASE"
fi

if want_cursor; then
  if [[ "$SCOPE" == "project" ]]; then
    install_cursor_project "$PROJECT_BASE"
  else
    install_cursor_global
  fi
fi

if want_codex; then
  if [[ "$SCOPE" == "project" ]]; then
    install_codex_project "$PROJECT_BASE"
  else
    install_codex
  fi
fi

if want_antigravity; then
  if [[ "$SCOPE" == "project" ]]; then
    install_antigravity_project "$PROJECT_BASE"
  else
    install_antigravity
  fi
fi

echo
log "Done. Restart your AI tool to pick up changes."
log "Canonical instructions: AGENTS.md → docs/guidelines/"
log "Tool matrix: docs/tool-adapters.md"
