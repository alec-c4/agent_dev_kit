#!/usr/bin/env bash
# validate-registry.sh — CI gate for registry, packs, skills, and topics
# Exit 0 = pass, 1 = failures found
#
# Usage:
#   bash scripts/validate-registry.sh           # full validation
#   bash scripts/validate-registry.sh --phase=1 # registry JSON only (Phase 1 kit)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ERRORS=0
WARNINGS=0
PHASE="full"

for arg in "$@"; do
  case "$arg" in
    --phase=1) PHASE="1" ;;
    --help|-h)
      echo "Usage: $0 [--phase=1]"
      exit 0
      ;;
  esac
done

err() { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $*" >&2; WARNINGS=$((WARNINGS + 1)); }
ok() { echo "  ok: $*"; }

echo "Validating Agent Dev Kit at $KIT_DIR"
echo ""

# ── jq required ───────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  err "jq is required"
  exit 1
fi

# ── Registry JSON present ─────────────────────────────────────────────────────
for name in stacks topics dod; do
  if [[ ! -f "$KIT_DIR/registry/${name}.json" ]]; then
    err "missing registry/${name}.json — run: bash scripts/compile_registry.sh"
  else
    ok "registry/${name}.json"
  fi
done

if [[ "$PHASE" == "1" ]]; then
  echo "Phase 1 mode — registry + stack skill profiles only"
  echo ""

  if [[ -f "$KIT_DIR/registry/stacks.json" ]]; then
    while IFS= read -r sid; do
      [[ -z "$sid" ]] && continue
      skill=$(jq -r ".stacks[\"$sid\"].stack_skill // empty" "$KIT_DIR/registry/stacks.json")
      if [[ -z "$skill" ]]; then
        err "stack $sid missing stack_skill in registry/stacks.yaml"
        continue
      fi
      if [[ ! -f "$KIT_DIR/skills/$skill/profile.yaml" ]]; then
        err "stack $sid → missing skills/$skill/profile.yaml"
      elif [[ ! -f "$KIT_DIR/skills/$skill/profile.json" ]]; then
        warn "skills/$skill/profile.json missing — run: bash scripts/compile_registry.sh"
      else
        ok "stack profile $skill"
      fi
      if [[ ! -f "$KIT_DIR/skills/$skill/SKILL.md" ]]; then
        err "stack $sid → missing skills/$skill/SKILL.md"
      fi
    done < <(jq -r '.stacks | keys[]' "$KIT_DIR/registry/stacks.json")
  fi

  for skill in stack-detection stack-loader testing-universal; do
    if [[ ! -f "$KIT_DIR/skills/$skill/SKILL.md" ]]; then
      err "missing core skill: skills/$skill/SKILL.md"
    else
      ok "core skill $skill"
    fi
  done

  if [[ ! -f "$KIT_DIR/registry/cursor-user-rules.json" ]]; then
    err "missing registry/cursor-user-rules.json — run: bash scripts/compile_registry.sh"
  else
    ok "registry/cursor-user-rules.json"
  fi

  if [[ ! -f "$KIT_DIR/scripts/sync-cursor-user-rules.sh" ]]; then
    err "missing scripts/sync-cursor-user-rules.sh"
  elif [[ ! -f "$KIT_DIR/templates/cursor/rules/kit-user-rules.mdc" ]]; then
    err "missing templates/cursor/rules/kit-user-rules.mdc"
  else
    ok "cursor user-rules dedup (sync script + kit-user-rules.mdc)"
  fi

  if [[ ! -f "$KIT_DIR/docs/guidelines/TRACKER.md" ]]; then
    err "missing docs/guidelines/TRACKER.md"
  else
    ok "docs/guidelines/TRACKER.md"
  fi

  if [[ ! -f "$KIT_DIR/scripts/kit" ]]; then
    err "missing scripts/kit CLI wrapper"
  elif [[ ! -f "$KIT_DIR/docs/shell-commands.md" ]]; then
    err "missing docs/shell-commands.md"
  else
    ok "shell-agnostic kit CLI (scripts/kit + docs/shell-commands.md)"
  fi

  for name in stacks topics dod cursor-user-rules; do
    yaml="$KIT_DIR/registry/${name}.yaml"
    json="$KIT_DIR/registry/${name}.json"
    [[ -f "$yaml" && -f "$json" ]] || continue
    if [[ "$yaml" -nt "$json" ]]; then
      warn "registry/${name}.yaml is newer than .json — run: bash scripts/compile_registry.sh"
    fi
  done
  echo ""
  if [[ $ERRORS -gt 0 ]]; then
    echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
  fi
  echo "PASSED phase 1 ($WARNINGS warning(s))"
  exit 0
fi

# ── stacks: detection_order ↔ stacks keys ─────────────────────────────────────
if [[ -f "$KIT_DIR/registry/stacks.json" ]]; then
  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    if ! jq -e ".stacks[\"$sid\"]" "$KIT_DIR/registry/stacks.json" >/dev/null; then
      err "detection_order references unknown stack: $sid"
    fi
  done < <(jq -r '.detection_order[]' "$KIT_DIR/registry/stacks.json")

  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ ! -d "$KIT_DIR/skills/$skill" ]]; then
        err "stack $sid references missing skill: skills/$skill"
      fi
    done < <(jq -r ".stacks[\"$sid\"].skills | (.required // []) + (.recommended // []) + (.if_spec_dir // []) + (.if_test_dir // []) | .[]" "$KIT_DIR/registry/stacks.json" 2>/dev/null)
    # if_gem skills
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ ! -d "$KIT_DIR/skills/$skill" ]]; then
        err "stack $sid if_gem references missing skill: skills/$skill"
      fi
    done < <(jq -r ".stacks[\"$sid\"].skills.if_gem // {} | .[] | .[]" "$KIT_DIR/registry/stacks.json" 2>/dev/null)
  done < <(jq -r '.stacks | keys[]' "$KIT_DIR/registry/stacks.json")
fi

# ── topics: stack files exist ─────────────────────────────────────────────────
if [[ -f "$KIT_DIR/registry/topics.json" ]]; then
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ ! -f "$KIT_DIR/skills/$path" ]]; then
      err "topics references missing file: skills/$path"
    fi
  done < <(jq -r '.topics[].stack_files | .[]' "$KIT_DIR/registry/topics.json")
fi

# ── packs: manifests and skills ─────────────────────────────────────────────────
for manifest in "$KIT_DIR"/packs/*/manifest.json "$KIT_DIR"/packs/community/*/manifest.json; do
  [[ -f "$manifest" ]] || continue
  [[ "$manifest" == *"/_template/"* ]] && continue
  pack=$(jq -r '.id' "$manifest")
  ok "pack $pack"

  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    if [[ ! -f "$KIT_DIR/packs/$dep/manifest.json" ]]; then
      err "pack $pack depends_on missing pack: $dep"
    fi
  done < <(jq -r '.depends_on[]? // empty' "$manifest")

  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    if [[ ! -d "$KIT_DIR/skills/$skill" ]]; then
      err "pack $pack references missing skill: skills/$skill"
    fi
    if [[ ! -f "$KIT_DIR/skills/$skill/SKILL.md" ]]; then
      err "pack $pack skill missing SKILL.md: skills/$skill"
    fi
  done < <(jq -r '.skills[]' "$manifest")
done

# ── Empty skill directories ───────────────────────────────────────────────────
for skill_dir in "$KIT_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name=$(basename "$skill_dir")
  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    err "empty skill directory (no SKILL.md): skills/$name"
  fi
done

# ── Orphan top-level skill dirs (not in any pack or registry) ─────────────────
PACKED_SKILLS=$(mktemp)
REGISTRY_SKILLS=$(mktemp)
trap 'rm -f "$PACKED_SKILLS" "$REGISTRY_SKILLS"' EXIT
for m in "$KIT_DIR"/packs/*/manifest.json "$KIT_DIR"/packs/community/*/manifest.json; do
  [[ -f "$m" ]] || continue
  [[ "$m" == *"/_template/"* ]] && continue
  jq -r '.skills[]' "$m" >> "$PACKED_SKILLS"
done
jq -r '
  .stacks[] | .skills |
  (.required // []) + (.recommended // []) + (.if_spec_dir // []) + (.if_test_dir // []) + [(.if_gem // {} | .[] | .[])]
  | .[]
' "$KIT_DIR/registry/stacks.json" >> "$REGISTRY_SKILLS" 2>/dev/null
jq -r '.topics[].skill' "$KIT_DIR/registry/topics.json" >> "$REGISTRY_SKILLS" 2>/dev/null
for skill_dir in "$KIT_DIR"/skills/*/; do
  name=$(basename "$skill_dir")
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  # inertia/* nested skills are loaded via parent inertia/SKILL.md
  if grep -qxF "$name" "$PACKED_SKILLS" 2>/dev/null || grep -qxF "$name" "$REGISTRY_SKILLS" 2>/dev/null; then
    continue
  fi
  if [[ "${VALIDATE_ORPHANS_STRICT:-}" == "1" ]]; then
    err "orphan skill directory (not in packs or registry): skills/$name"
  else
    warn "orphan skill directory (not in packs or registry): skills/$name — add to a pack or remove"
  fi
done

# ── agents: required frontmatter ──────────────────────────────────────────────
for agent in "$KIT_DIR"/agents/*.md; do
  [[ -f "$agent" ]] || continue
  if ! grep -q '^name:' "$agent"; then
    err "agent missing name: $(basename "$agent")"
  fi
  if ! grep -q '^description:' "$agent"; then
    err "agent missing description: $(basename "$agent")"
  fi
done
ok "agents frontmatter"

# ── hooks: exist and executable ───────────────────────────────────────────────
for hook in "$KIT_DIR"/hooks/*.sh; do
  [[ -f "$hook" ]] || continue
  if [[ ! -x "$hook" ]]; then
    warn "hook not executable: $(basename "$hook") — run chmod +x"
  fi
  if ! bash -n "$hook" 2>/dev/null; then
    err "hook syntax error: $(basename "$hook")"
  fi
done
ok "hooks"

# ── detect-stack dry run on fixtures ──────────────────────────────────────────
FIXTURE_RAILS="$KIT_DIR/scripts/fixtures/minimal-rails"
if [[ -d "$FIXTURE_RAILS" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_RAILS" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "rails"' >/dev/null; then
    ok "detect_stack fixture rails"
  else
    err "detect_stack fixture did not detect rails"
  fi
fi

FIXTURE_ELIXIR="$KIT_DIR/scripts/fixtures/minimal-elixir"
if [[ -d "$FIXTURE_ELIXIR" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_ELIXIR" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "elixir"' >/dev/null; then
    ok "detect_stack fixture elixir"
  else
    err "detect_stack fixture did not detect elixir"
  fi
fi

# ── YAML vs JSON staleness ────────────────────────────────────────────────────
for name in stacks topics dod; do
  yaml="$KIT_DIR/registry/${name}.yaml"
  json="$KIT_DIR/registry/${name}.json"
  [[ -f "$yaml" && -f "$json" ]] || continue
  if [[ "$yaml" -nt "$json" ]]; then
    if [[ "${VALIDATE_STRICT:-}" == "1" ]]; then
      err "registry/${name}.yaml is newer than .json — run: bash scripts/compile_registry.sh"
    else
      warn "registry/${name}.yaml is newer than .json — run: bash scripts/compile_registry.sh"
    fi
  fi
done

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi
echo "PASSED ($WARNINGS warning(s))"
exit 0
