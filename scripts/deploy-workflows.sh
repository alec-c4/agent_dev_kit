#!/usr/bin/env bash
# deploy-workflows.sh — Deploy Antigravity workflow shortcuts
#
# Source: skills/{feature,fix,plan,review,ship}/SKILL.md
#
# Usage:
#   ./scripts/deploy-workflows.sh [--scope=global|project|both] [--dry-run]
#   ./scripts/kit deploy-workflows --scope=project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCOPE="project"
DRY_RUN=false

WORKFLOW_SKILLS=(feature fix plan review ship resolve-task)

for arg in "$@"; do
  case "$arg" in
    --scope=*) SCOPE="${arg#--scope=}" ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

case "$SCOPE" in
  global|project|both) ;;
  *) echo "ERROR: --scope must be global, project, or both" >&2; exit 1 ;;
esac

log() { echo "  $*"; }

copy_workflow() {
  local src="$1" dest="$2"
  if $DRY_RUN; then
    echo "  [dry] cp $src -> $dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

# Claude Code merged custom commands into skills: a directory at
# ~/.claude/skills/<name>/ already provides /<name>, and the skill wins when
# both exist. Copying SKILL.md into ~/.claude/commands/ therefore adds nothing
# and the copies go stale the moment the skill changes.
report_stale_claude_commands() {
  local base="$1"
  local found=()
  local name
  for name in "${WORKFLOW_SKILLS[@]}"; do
    [[ -f "$base/$name.md" ]] && found+=("$name.md")
  done
  log "Claude commands: skipped — ~/.claude/skills/<name>/ already provides /<name>"
  if ((${#found[@]})); then
    log "Stale copies from an older kit remain in $base: ${found[*]}"
    log "Remove them so the skill is the single source: rm $base/{$(IFS=,; echo "${found[*]%.md}")}.md"
  fi
}

deploy_antigravity_workflows() {
  local base="$1" label="$2"
  log "Antigravity workflows → $label ($base)"
  for name in "${WORKFLOW_SKILLS[@]}"; do
    copy_workflow "$KIT_DIR/skills/$name/SKILL.md" "$base/$name.md"
  done
}

echo "Agent Dev Kit deploy-workflows"
echo "  scope:   $SCOPE"
$DRY_RUN && echo "  dry-run: yes"
echo

if [[ "$SCOPE" == "global" || "$SCOPE" == "both" ]]; then
  report_stale_claude_commands "$HOME/.claude/commands"
fi

if [[ "$SCOPE" == "project" || "$SCOPE" == "both" ]]; then
  deploy_antigravity_workflows "$(pwd)/.agents/workflows" "project ./.agents/workflows"
fi

echo
log "Done. Restart Claude Code / Antigravity to refresh slash commands."
log "Codex/Cursor: workflow skills deploy via ./scripts/kit deploy-skills --pack=core"
