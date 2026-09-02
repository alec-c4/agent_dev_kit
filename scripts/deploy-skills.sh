#!/usr/bin/env bash
# deploy-skills.sh — Symlink pack skills into Agent Skills directories
#
# Usage:
#   ./scripts/deploy-skills.sh --pack=core [--scope=global|project|both] [--dry-run] [--force]
#   ./scripts/deploy-skills.sh --pack=rails --scope=project
#   ./scripts/deploy-skills.sh --pack=core,rails --scope=both
#
# Resolves manifest depends_on (dependency packs deploy first).
# Global:  ~/.agents/skills/<skill-path>/
# Project: ./.agents/skills/<skill-path>/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACK=""
SCOPE="project"
DRY_RUN=false
FORCE=false
SKIPPED=0
MODE="symlink"
SYNC_AG_CLI=false
ALSO_CLAUDE=false
ORDERED_PACKS=()

for arg in "$@"; do
  case "$arg" in
    --pack=*) PACK="${arg#--pack=}" ;;
    --scope=*) SCOPE="${arg#--scope=}" ;;
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --sync-antigravity-cli) SYNC_AG_CLI=true ;;
    --also-claude) ALSO_CLAUDE=true ;;
    --help|-h)
      sed -n '2,13p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

[[ -n "$PACK" ]] || { echo "ERROR: --pack= required (e.g. core or core,rails)" >&2; exit 1; }

case "$SCOPE" in
  global|project|both) ;;
  *) echo "ERROR: --scope must be global, project, or both" >&2; exit 1 ;;
esac

log() { echo "  $*"; }

find_manifest() {
  local pack="$1"
  if [[ -f "$KIT_DIR/packs/$pack/manifest.json" ]]; then
    printf '%s' "$KIT_DIR/packs/$pack/manifest.json"
  elif [[ -f "$KIT_DIR/packs/community/$pack/manifest.json" ]]; then
    printf '%s' "$KIT_DIR/packs/community/$pack/manifest.json"
  else
    echo "ERROR: missing manifest for pack '$pack' — run: bash scripts/compile_registry.sh" >&2
    return 1
  fi
}

pack_listed() {
  local pack="$1" p
  for p in ${ORDERED_PACKS[@]+"${ORDERED_PACKS[@]}"}; do
    [[ "$p" == "$pack" ]] && return 0
  done
  return 1
}

add_pack_order() {
  local pack="$1"
  pack_listed "$pack" && return 0
  local manifest
  manifest="$(find_manifest "$pack")" || exit 1
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    add_pack_order "$dep"
  done < <(jq -r '.depends_on[]? // empty' "$manifest")
  ORDERED_PACKS+=("$pack")
}

resolve_path() {
  (cd "$1" 2>/dev/null && pwd -P) || printf ''
}

claude_skills_same_as_kit() {
  local base="$HOME/.claude/skills"
  local resolved kit_resolved
  [[ -e "$base" ]] || return 1
  resolved="$(resolve_path "$base")"
  kit_resolved="$(resolve_path "$KIT_DIR/skills")"
  [[ -n "$resolved" && -n "$kit_resolved" && "$resolved" == "$kit_resolved" ]]
}

# A symlink at the destination is ours to repoint. A real directory is not:
# it may be a skill the developer wrote by hand, and replacing it would delete
# their work with no warning. Refuse those unless --force says otherwise.
kit_owns_dest() {
  local dest="$1"
  [[ -L "$dest" ]] && return 0          # any symlink: previous deploy
  [[ ! -e "$dest" ]] && return 0        # nothing there
  return 1
}

link_or_copy() {
  local src="$1" dest="$2"
  if $DRY_RUN; then
    if kit_owns_dest "$dest" || $FORCE; then
      echo "  [dry] $MODE $src -> $dest"
    else
      echo "  [dry] SKIP (not a kit symlink) $dest"
    fi
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if ! kit_owns_dest "$dest" && ! $FORCE; then
    echo "  skip: $dest exists and is not a kit symlink — pass --force to replace it" >&2
    SKIPPED=$((SKIPPED + 1))
    return
  fi
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
  [[ -f "$src/SKILL.md" ]] || { echo "ERROR: missing skills/$skill/SKILL.md" >&2; exit 1; }
  link_or_copy "$src" "$dest"
}

deploy_manifest_to() {
  local manifest="$1" base="$2" label="$3"
  local pack_id
  pack_id="$(jq -r '.id' "$manifest")"
  log "Pack '$pack_id' → $label"
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    deploy_skill_to "$skill" "$base"
  done < <(jq -r '.skills[]' "$manifest")
}

deploy_all_bases() {
  local manifest="$1"
  if [[ "$SCOPE" == "global" || "$SCOPE" == "both" ]]; then
    deploy_manifest_to "$manifest" "$HOME/.agents/skills" "global ~/.agents/skills"
    $SYNC_AG_CLI && deploy_manifest_to "$manifest" "$HOME/.gemini/antigravity-cli/skills" "Antigravity CLI"
    if $ALSO_CLAUDE; then
      if claude_skills_same_as_kit; then
        log "Claude Code skills already linked to kit tree (~/.claude/skills → skills/) — skip per-skill deploy"
      else
        deploy_manifest_to "$manifest" "$HOME/.claude/skills" "Claude Code"
      fi
    fi
  fi
  if [[ "$SCOPE" == "project" || "$SCOPE" == "both" ]]; then
    deploy_manifest_to "$manifest" "$(pwd)/.agents/skills" "project ./.agents/skills"
  fi
}

echo "Agent Dev Kit deploy-skills"
echo "  pack:   $PACK"
echo "  scope:  $SCOPE"
echo "  mode:   $MODE"
$DRY_RUN && echo "  dry-run: yes"
echo

IFS=',' read -ra REQUESTED <<< "$PACK"
for p in "${REQUESTED[@]}"; do
  p="${p// /}"
  [[ -n "$p" ]] && add_pack_order "$p"
done

for p in ${ORDERED_PACKS[@]+"${ORDERED_PACKS[@]}"}; do
  manifest="$(find_manifest "$p")"
  deploy_all_bases "$manifest"
done

echo
if ((SKIPPED > 0)); then
  log "Skipped $SKIPPED destination(s) that were not kit symlinks — rerun with --force to replace them"
fi
if ((${#ORDERED_PACKS[@]} > 0)); then
  log "Done (${#ORDERED_PACKS[@]} pack(s): ${ORDERED_PACKS[*]})"
else
  log "Done (no packs resolved)"
fi
log "Validate: ./scripts/kit validate-skills --pack=<id>"
