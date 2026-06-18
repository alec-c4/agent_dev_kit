#!/usr/bin/env bash
# deploy-skills.sh — Symlink pack skills into Agent Skills directories
#
# Usage:
#   ./scripts/deploy-skills.sh --pack=core [--scope=global|project|both] [--dry-run]
#   ./scripts/deploy-skills.sh --pack=core --scope=project --sync-antigravity-cli
#   ./scripts/kit deploy-skills --pack=core --scope=both
#
# Global:  ~/.agents/skills/<skill-path>/
# Project: ./.agents/skills/<skill-path>/
# Optional: ~/.gemini/antigravity-cli/skills/ (Antigravity CLI quirk)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACK=""
SCOPE="project"
DRY_RUN=false
MODE="symlink"
SYNC_AG_CLI=false
ALSO_CLAUDE=false

for arg in "$@"; do
  case "$arg" in
    --pack=*) PACK="${arg#--pack=}" ;;
    --scope=*) SCOPE="${arg#--scope=}" ;;
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=true ;;
    --sync-antigravity-cli) SYNC_AG_CLI=true ;;
    --also-claude) ALSO_CLAUDE=true ;;
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

[[ -n "$PACK" ]] || { echo "ERROR: --pack= required (e.g. core)" >&2; exit 1; }

case "$SCOPE" in
  global|project|both) ;;
  *) echo "ERROR: --scope must be global, project, or both" >&2; exit 1 ;;
esac

MANIFEST="$KIT_DIR/packs/$PACK/manifest.json"
[[ -f "$MANIFEST" ]] || { echo "ERROR: missing $MANIFEST — run: bash scripts/compile_registry.sh" >&2; exit 1; }

log() { echo "  $*"; }

link_or_copy() {
  local src="$1" dest="$2"
  if $DRY_RUN; then
    echo "  [dry] $MODE $src -> $dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi
  if [[ "$MODE" == "symlink" ]]; then
    ln -s "$src" "$dest"
  else
    cp -R "$src" "$dest"
  fi
}

deploy_skill_to() {
  local skill="$1" base="$2"
  local src="$KIT_DIR/skills/$skill"
  local dest="$base/$skill"
  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "ERROR: missing skills/$skill/SKILL.md" >&2
    exit 1
  fi
  link_or_copy "$src" "$dest"
}

deploy_pack_to() {
  local base="$1" label="$2"
  log "Deploy pack '$PACK' → $label ($base)"
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    deploy_skill_to "$skill" "$base"
  done < <(jq -r '.skills[]' "$MANIFEST")
}

echo "Agent Dev Kit deploy-skills"
echo "  pack:   $PACK"
echo "  scope:  $SCOPE"
echo "  mode:   $MODE"
$DRY_RUN && echo "  dry-run: yes"
echo

if [[ "$SCOPE" == "global" || "$SCOPE" == "both" ]]; then
  deploy_pack_to "$HOME/.agents/skills" "global ~/.agents/skills"
  if $SYNC_AG_CLI; then
    deploy_pack_to "$HOME/.gemini/antigravity-cli/skills" "Antigravity CLI"
  fi
  if $ALSO_CLAUDE; then
    deploy_pack_to "$HOME/.claude/skills" "Claude Code ~/.claude/skills"
  fi
fi

if [[ "$SCOPE" == "project" || "$SCOPE" == "both" ]]; then
  deploy_pack_to "$(pwd)/.agents/skills" "project ./.agents/skills"
fi

echo
log "Done. Restart Codex / Antigravity / Claude Code to refresh skill discovery."
log "Validate: ./scripts/kit validate-skills --pack=$PACK"
